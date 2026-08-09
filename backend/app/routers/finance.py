from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, func
from datetime import datetime, time
from typing import List, Optional
import json

from app.database import get_db
from app.models.models import User, Expense, FinancialTransaction, AuditLog, TransactionType, TransactionStatus
from app.schemas.schemas import ExpenseCreate, ExpenseUpdate, ExpenseOut, FinancialTransactionOut, TransactionSummary
from app.utils.auth import get_current_user, require_admin
from app.utils.finance import generate_expense_no, generate_transaction_no

router = APIRouter()

@router.get("/transactions", response_model=List[FinancialTransactionOut])
def get_transactions(
    from_date: Optional[datetime] = Query(None),
    to_date: Optional[datetime] = Query(None),
    transaction_type: Optional[str] = Query(None),
    category: Optional[str] = Query(None),
    payment_method: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(FinancialTransaction)
    
    # Filter by date boundaries correctly (inclusive of entire days if only date is passed)
    if from_date:
        query = query.filter(FinancialTransaction.transaction_date >= from_date)
    if to_date:
        # If to_date is provided without time, make it end of that day (23:59:59.999)
        if to_date.hour == 0 and to_date.minute == 0 and to_date.second == 0:
            to_date_end = datetime.combine(to_date.date(), time(23, 59, 59, 999999))
            query = query.filter(FinancialTransaction.transaction_date <= to_date_end)
        else:
            query = query.filter(FinancialTransaction.transaction_date <= to_date)
            
    if transaction_type:
        query = query.filter(FinancialTransaction.transaction_type == transaction_type)
    if category:
        query = query.filter(FinancialTransaction.category == category)
    if payment_method:
        query = query.filter(FinancialTransaction.payment_method == payment_method)
    if status:
        query = query.filter(FinancialTransaction.status == status)
    else:
        # Default to showing all, or optionally filter active
        pass

    return query.order_by(FinancialTransaction.transaction_date.desc(), FinancialTransaction.id.desc()).offset(skip).limit(limit).all()

@router.get("/transactions/summary", response_model=TransactionSummary)
def get_transactions_summary(
    from_date: datetime = Query(...),
    to_date: datetime = Query(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Setup correct inclusive date boundaries
    if to_date.hour == 0 and to_date.minute == 0 and to_date.second == 0:
        to_date_end = datetime.combine(to_date.date(), time(23, 59, 59, 999999))
    else:
        to_date_end = to_date

    # Fetch active transactions within date range
    txns = db.query(FinancialTransaction).filter(
        FinancialTransaction.transaction_date >= from_date,
        FinancialTransaction.transaction_date <= to_date_end,
        FinancialTransaction.status == TransactionStatus.active
    ).all()

    total_income = sum(t.amount for t in txns if t.transaction_type == TransactionType.income)
    total_expense = sum(t.amount for t in txns if t.transaction_type == TransactionType.expense)
    net_balance = total_income - total_expense

    income_count = sum(1 for t in txns if t.transaction_type == TransactionType.income)
    expense_count = sum(1 for t in txns if t.transaction_type == TransactionType.expense)

    return TransactionSummary(
        from_date=from_date,
        to_date=to_date,
        total_income=total_income,
        total_expense=total_expense,
        net_balance=net_balance,
        income_count=income_count,
        expense_count=expense_count
    )

@router.post("/expenses", response_model=ExpenseOut)
def create_expense(
    expense_data: ExpenseCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    # Perform operations inside a safe database transaction block
    expense_no = generate_expense_no(db)
    
    expense = Expense(
        expense_no=expense_no,
        expense_date=expense_data.expense_date,
        category=expense_data.category,
        description=expense_data.description,
        amount=expense_data.amount,
        payment_method=expense_data.payment_method,
        reference_no=expense_data.reference_no,
        remarks=expense_data.remarks,
        created_by=current_user.user_id,
        status="active"
    )
    db.add(expense)
    db.commit()
    db.refresh(expense)
    
    # Automatically log as EXPENSE transaction
    transaction = FinancialTransaction(
        transaction_no=generate_transaction_no(db),
        transaction_date=expense.expense_date,
        transaction_type=TransactionType.expense,
        category=expense.category,
        description=expense.description,
        amount=expense.amount,
        payment_method=expense.payment_method,
        reference_number=expense.expense_no,
        expense_id=expense.expense_id,
        status=TransactionStatus.active,
        created_by=current_user.user_id,
        remarks=expense.remarks
    )
    db.add(transaction)
    db.commit()

    # Log audit entry
    audit = AuditLog(
        user_id=current_user.user_id,
        username=current_user.username,
        action="EXPENSE_CREATED",
        entity="expense",
        entity_id=expense.expense_id,
        details=f"Created expense: {expense.expense_no} under category: {expense.category} with amount: ₹{expense.amount}"
    )
    db.add(audit)
    db.commit()

    return expense

@router.patch("/expenses/{expense_id}", response_model=ExpenseOut)
def update_expense(
    expense_id: int,
    expense_data: ExpenseUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    expense = db.query(Expense).filter(Expense.expense_id == expense_id).first()
    if not expense:
        raise HTTPException(status_code=404, detail="செலவு பதிவு கண்டுபிடிக்கப்படவில்லை")
        
    changes = {}
    for key, value in expense_data.dict(exclude_unset=True).items():
        old_val = getattr(expense, key)
        if old_val == value:
            continue
        changes[key] = {
            "old": str(old_val) if old_val is not None else None,
            "new": str(value) if value is not None else None
        }
        setattr(expense, key, value)
        
    if changes:
        db.commit()
        db.refresh(expense)
        
        # Sync update with the linked transaction
        transaction = db.query(FinancialTransaction).filter(FinancialTransaction.expense_id == expense.expense_id).first()
        if transaction:
            transaction.transaction_date = expense.expense_date
            transaction.category = expense.category
            transaction.description = expense.description
            transaction.amount = expense.amount
            transaction.payment_method = expense.payment_method
            transaction.reference_number = expense.expense_no
            transaction.remarks = expense.remarks
            db.commit()

        # Audit modifications
        audit = AuditLog(
            user_id=current_user.user_id,
            username=current_user.username,
            action="EXPENSE_UPDATED",
            entity="expense",
            entity_id=expense.expense_id,
            details=json.dumps(changes)
        )
        db.add(audit)
        db.commit()
        
    return expense

@router.delete("/expenses/{expense_id}")
def cancel_expense(
    expense_id: int,
    reason: Optional[str] = "Cancelled by Administrator",
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    expense = db.query(Expense).filter(Expense.expense_id == expense_id).first()
    if not expense:
        raise HTTPException(status_code=404, detail="செலவு பதிவு கண்டுபிடிக்கப்படவில்லை")
        
    expense.status = "cancelled"
    expense.cancelled_at = datetime.now()
    expense.cancelled_by = current_user.user_id
    expense.cancellation_reason = reason
    db.commit()
    
    # Sync with transaction
    transaction = db.query(FinancialTransaction).filter(FinancialTransaction.expense_id == expense.expense_id).first()
    if transaction:
        transaction.status = TransactionStatus.cancelled
        db.commit()
        
    # Audit log
    audit = AuditLog(
        user_id=current_user.user_id,
        username=current_user.username,
        action="EXPENSE_CANCELLED",
        entity="expense",
        entity_id=expense.expense_id,
        details=f"Cancelled expense reference no: {expense.expense_no}. Reason: {reason}"
    )
    db.add(audit)
    db.commit()
    
    return {"message": "செலவு பதிவு வெற்றிகரமாக ரத்து செய்யப்பட்டது"}
