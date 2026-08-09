from fastapi import APIRouter, Depends, HTTPException, Response
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import datetime
from decimal import Decimal
from typing import List, Optional
import json

from app.database import get_db
from app.models.models import User, Devotee, Bill, AuditLog, FinancialTransaction, TransactionType, TransactionStatus
from app.schemas.schemas import BillCreate, BillOut, DashboardStats, BillUpdate
from app.utils.auth import get_current_user, require_admin
from app.utils.receipt import generate_receipt_no
from app.utils.pdf_generator import generate_receipt_pdf
from app.utils.storage import upload_pdf_to_storage, download_pdf_from_storage
from app.utils.finance import generate_transaction_no

router = APIRouter()

@router.get("/dashboard", response_model=DashboardStats)
def get_dashboard(db: Session = Depends(get_db),
                  current_user: User = Depends(get_current_user)):
    from decimal import Decimal
    today = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
    month_start = today.replace(day=1)
    
    today_bills = db.query(Bill).filter(Bill.bill_date >= today, Bill.status == "active").all()
    
    today_collection = sum(float(b.amount) for b in today_bills)
    today_vari = sum(float(b.amount) for b in today_bills if b.bill_type == "வரி")
    today_kanikkai = sum(float(b.amount) for b in today_bills if b.bill_type == "காணிக்கை")
    
    monthly_bills = db.query(Bill).filter(Bill.bill_date >= month_start, Bill.status == "active").all()
    monthly_collection = sum(float(b.amount) for b in monthly_bills)
    
    total_devotees = db.query(Devotee).count()
    total_staff = db.query(User).filter(User.is_active == True).count()
    
    return DashboardStats(
        today_collection=Decimal(str(today_collection)),
        today_vari=Decimal(str(today_vari)),
        today_kanikkai=Decimal(str(today_kanikkai)),
        today_bills_count=len(today_bills),
        total_devotees=total_devotees,
        total_staff=total_staff,
        monthly_collection=Decimal(str(monthly_collection))
    )

@router.get("/", response_model=List[BillOut])
def list_bills(skip: int = 0, limit: int = 50, db: Session = Depends(get_db),
               current_user: User = Depends(get_current_user)):
    return db.query(Bill).order_by(Bill.bill_date.desc()).offset(skip).limit(limit).all()

@router.post("/", response_model=BillOut)
def create_bill(bill_data: BillCreate, db: Session = Depends(get_db),
                current_user: User = Depends(get_current_user)):
    devotee = db.query(Devotee).filter(Devotee.devotee_id == bill_data.devotee_id).first()
    if not devotee:
        raise HTTPException(status_code=404, detail="பக்தர் கண்டுபிடிக்கப்படவில்லை")
    
    receipt_no = generate_receipt_no(db)
    
    bill = Bill(
        receipt_no=receipt_no,
        devotee_id=bill_data.devotee_id,
        staff_id=current_user.user_id,
        bill_type=bill_data.bill_type,
        category=bill_data.category,
        amount=bill_data.amount,
        payment_method=bill_data.payment_method,
        transaction_id=bill_data.transaction_id,
        remarks=bill_data.remarks
    )
    db.add(bill)
    db.commit()
    db.refresh(bill)
    
    # Automatically log as INCOME transaction in database-level atomic flow
    transaction = FinancialTransaction(
        transaction_no=generate_transaction_no(db),
        transaction_date=bill.bill_date,
        transaction_type=TransactionType.income,
        category=bill.category or ("வரி" if bill.bill_type.value == "வரி" or bill.bill_type == "வரி" else "காணிக்கை"),
        description=f"Income from Bill {bill.receipt_no}",
        amount=bill.amount,
        payment_method=bill.payment_method.value if hasattr(bill.payment_method, 'value') else bill.payment_method,
        reference_number=bill.receipt_no,
        bill_id=bill.bill_id,
        status=TransactionStatus.active,
        created_by=current_user.user_id,
        remarks=bill.remarks
    )
    db.add(transaction)
    db.commit()
    
    # Audit bill creation
    audit = AuditLog(
        user_id=current_user.user_id,
        username=current_user.username,
        action="create_bill",
        entity="bill",
        entity_id=bill.bill_id,
        details=f"Created bill: {bill.receipt_no} for devotee: {devotee.devotee_name} with amount: ₹{bill.amount}"
    )
    db.add(audit)
    db.commit()
    
    # Generate and upload PDF to Object Storage
    try:
        bill_dict = {
            "receipt_no": bill.receipt_no,
            "bill_date": bill.bill_date,
            "bill_type": bill.bill_type.value if hasattr(bill.bill_type, 'value') else bill.bill_type,
            "category": bill.category or "-",
            "amount": float(bill.amount),
            "payment_method": bill.payment_method.value if hasattr(bill.payment_method, 'value') else bill.payment_method,
            "transaction_id": bill.transaction_id,
            "remarks": bill.remarks,
            "devotee_name": devotee.devotee_name,
            "father_name": devotee.father_name or "-",
            "mobile": devotee.mobile or "-",
            "village": devotee.village or "-",
            "staff_name": current_user.staff_name,
        }
        pdf_bytes = generate_receipt_pdf(bill_dict)
        storage_key = upload_pdf_to_storage(pdf_bytes, f"receipt_{bill.receipt_no}.pdf")
        if storage_key:
            bill.pdf_storage_key = storage_key
            db.commit()
    except Exception as e:
        import logging
        logger = logging.getLogger("uvicorn.error")
        logger.error(f"Failed to upload PDF bill to storage: {e}")
    
    # Reload with relationships
    bill = db.query(Bill).filter(Bill.bill_id == bill.bill_id).first()
    return bill

@router.get("/{bill_id}", response_model=BillOut)
def get_bill(bill_id: int, db: Session = Depends(get_db),
             current_user: User = Depends(get_current_user)):
    bill = db.query(Bill).filter(Bill.bill_id == bill_id).first()
    if not bill:
        raise HTTPException(status_code=404, detail="பில் கண்டுபிடிக்கப்படவில்லை")
    return bill

@router.patch("/{bill_id}", response_model=BillOut)
def update_bill(
    bill_id: int,
    bill_data: BillUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    bill = db.query(Bill).filter(Bill.bill_id == bill_id).first()
    if not bill:
        raise HTTPException(status_code=404, detail="பில் கண்டுபிடிக்கப்படவில்லை")
        
    changes = {}
    for key, value in bill_data.dict(exclude_unset=True).items():
        old_val = getattr(bill, key)
        if isinstance(old_val, (float, int, Decimal)) and value is not None:
            if float(old_val) == float(value):
                continue
        elif old_val == value:
            continue
            
        changes[key] = {
            "old": str(old_val) if old_val is not None else None,
            "new": str(value) if value is not None else None
        }
        setattr(bill, key, value)
        
    if changes:
        db.commit()
        db.refresh(bill)
        
        # Sync with transaction
        transaction = db.query(FinancialTransaction).filter(FinancialTransaction.bill_id == bill.bill_id).first()
        if transaction:
            transaction.amount = bill.amount
            transaction.category = bill.category or ("வரி" if bill.bill_type.value == "வரி" or bill.bill_type == "வரி" else "காணிக்கை")
            transaction.payment_method = bill.payment_method.value if hasattr(bill.payment_method, 'value') else bill.payment_method
            transaction.remarks = bill.remarks
            db.commit()
        
        audit = AuditLog(
            user_id=current_user.user_id,
            username=current_user.username,
            action="BILL_UPDATED",
            entity="bill",
            entity_id=bill.bill_id,
            details=json.dumps(changes)
        )
        db.add(audit)
        db.commit()
        
    # Reload with relationships
    bill = db.query(Bill).filter(Bill.bill_id == bill_id).first()
    return bill

@router.get("/{bill_id}/receipt")
def download_receipt(bill_id: int, db: Session = Depends(get_db),
                     current_user: User = Depends(get_current_user)):
    bill = db.query(Bill).filter(Bill.bill_id == bill_id).first()
    if not bill:
        raise HTTPException(status_code=404, detail="பில் கண்டுபிடிக்கப்படவில்லை")
    
    # Try fetching from object storage
    if bill.pdf_storage_key:
        pdf_bytes = download_pdf_from_storage(bill.pdf_storage_key)
        if pdf_bytes:
            return Response(
                content=pdf_bytes,
                media_type="application/pdf",
                headers={"Content-Disposition": f"attachment; filename=receipt_{bill.receipt_no}.pdf"}
            )
            
    # Fallback: generate on the fly
    bill_data = {
        "receipt_no": bill.receipt_no,
        "bill_date": bill.bill_date,
        "bill_type": bill.bill_type.value if hasattr(bill.bill_type, 'value') else bill.bill_type,
        "category": bill.category or "-",
        "amount": float(bill.amount),
        "payment_method": bill.payment_method.value if hasattr(bill.payment_method, 'value') else bill.payment_method,
        "transaction_id": bill.transaction_id,
        "remarks": bill.remarks,
        "devotee_name": bill.devotee.devotee_name,
        "father_name": bill.devotee.father_name or "-",
        "mobile": bill.devotee.mobile or "-",
        "village": bill.devotee.village or "-",
        "staff_name": bill.staff.staff_name,
    }
    
    pdf_bytes = generate_receipt_pdf(bill_data)
    
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f"attachment; filename=receipt_{bill.receipt_no}.pdf"}
    )

@router.delete("/{bill_id}/cancel")
def cancel_bill(bill_id: int, reason: Optional[str] = "Cancelled by Administrator", db: Session = Depends(get_db),
                 current_user: User = Depends(require_admin)):
    bill = db.query(Bill).filter(Bill.bill_id == bill_id).first()
    if not bill:
        raise HTTPException(status_code=404, detail="பில் கண்டுபிடிக்கப்படவில்லை")
    
    bill.status = "cancelled"
    bill.cancelled_at = datetime.now()
    bill.cancelled_by = current_user.user_id
    bill.cancellation_reason = reason
    db.commit()
    
    # Sync with transaction
    transaction = db.query(FinancialTransaction).filter(FinancialTransaction.bill_id == bill.bill_id).first()
    if transaction:
        transaction.status = TransactionStatus.cancelled
        db.commit()
    
    # Audit bill cancellation
    audit = AuditLog(
        user_id=current_user.user_id,
        username=current_user.username,
        action="BILL_CANCELLED",
        entity="bill",
        entity_id=bill.bill_id,
        details=f"Cancelled bill receipt no: {bill.receipt_no}. Reason: {reason}"
    )
    db.add(audit)
    db.commit()
    
    return {"message": "பில் ரத்து செய்யப்பட்டது"}