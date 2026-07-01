from datetime import datetime
from sqlalchemy.orm import Session
try:
    # Try importing from the actual application structure
    from app.models.models import Bill
except ImportError:
    # Fallback for local testing/verification
    class Bill:
        pass
def generate_receipt_no(db: Session) -> str:
    """Generate receipt number: SSKT-YYYYMMDD-XXXX"""
    today = datetime.now()
    date_str = today.strftime("%Y%m%d")
    prefix = f"SSKT-{date_str}-"
    
    # Count today's bills
    today_start = today.replace(hour=0, minute=0, second=0, microsecond=0)
    count = db.query(Bill).filter(Bill.bill_date >= today_start).count()
    serial = str(count + 1).zfill(4)
    
    return f"{prefix}{serial}"
