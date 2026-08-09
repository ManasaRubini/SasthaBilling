from datetime import datetime
from sqlalchemy.orm import Session
from app.models.models import Expense, FinancialTransaction

def generate_expense_no(db: Session) -> str:
    """Generate expense number: EXP-YYYYMMDD-XXXX"""
    today = datetime.now()
    date_str = today.strftime("%Y%m%d")
    prefix = f"EXP-{date_str}-"
    
    # Count today's expenses
    today_start = today.replace(hour=0, minute=0, second=0, microsecond=0)
    count = db.query(Expense).filter(Expense.expense_date >= today_start).count()
    serial = str(count + 1).zfill(4)
    
    return f"{prefix}{serial}"

def generate_transaction_no(db: Session) -> str:
    """Generate transaction number: TXN-YYYYMMDD-XXXX"""
    today = datetime.now()
    date_str = today.strftime("%Y%m%d")
    prefix = f"TXN-{date_str}-"
    
    # Count today's transactions using created_at
    today_start = today.replace(hour=0, minute=0, second=0, microsecond=0)
    count = db.query(FinancialTransaction).filter(FinancialTransaction.created_at >= today_start).count()
    serial = str(count + 1).zfill(4)
    
    return f"{prefix}{serial}"
