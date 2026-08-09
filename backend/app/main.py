from fastapi import FastAPI, Depends, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError
import os
import logging

from app.database import engine, Base, get_db, SessionLocal
from app.routers import auth, devotees, bills, reports, staff, finance

logger = logging.getLogger("uvicorn.error")

Base.metadata.create_all(bind=engine)

def run_idempotent_migration():
    db = SessionLocal()
    try:
        from app.models.models import Bill, FinancialTransaction, TransactionType, TransactionStatus
        from app.utils.finance import generate_transaction_no
        
        bills = db.query(Bill).all()
        migrated_count = 0
        for bill in bills:
            existing = db.query(FinancialTransaction).filter(FinancialTransaction.bill_id == bill.bill_id).first()
            if not existing:
                status = TransactionStatus.active if (bill.status == "active" or (hasattr(bill.status, "value") and bill.status.value == "active")) else TransactionStatus.cancelled
                
                category = bill.category
                if not category:
                    category = "வரி" if (bill.bill_type == "வரி" or (hasattr(bill.bill_type, "value") and bill.bill_type.value == "வரி")) else "காணிக்கை"
                
                transaction = FinancialTransaction(
                    transaction_no=generate_transaction_no(db),
                    transaction_date=bill.bill_date,
                    transaction_type=TransactionType.income,
                    category=category,
                    description=f"Income from Bill {bill.receipt_no}",
                    amount=bill.amount,
                    payment_method=bill.payment_method.value if hasattr(bill.payment_method, "value") else bill.payment_method,
                    reference_number=bill.receipt_no,
                    bill_id=bill.bill_id,
                    status=status,
                    created_by=bill.staff_id,
                    remarks=bill.remarks
                )
                db.add(transaction)
                db.commit()
                migrated_count += 1
        if migrated_count > 0:
            logger.info(f"Successfully migrated {migrated_count} historical bills to financial transactions.")
    except Exception as e:
        logger.error(f"Migration of historical bills failed: {e}")
    finally:
        db.close()

run_idempotent_migration()

app = FastAPI(
    title="Temple Billing Management System",
    description="செம்புகுட்டி சாஸ்தா திருக்கோவில் - Billing System API",
    version="1.0.0"
)

# Secure CORS origins
cors_origins_raw = os.getenv("CORS_ORIGINS", "*")
if cors_origins_raw == "*":
    origins = ["*"]
    allow_credentials = False
else:
    origins = [o.strip() for o in cors_origins_raw.split(",") if o.strip()]
    allow_credentials = True

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=allow_credentials,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global database exception masking
@app.exception_handler(SQLAlchemyError)
def sqlalchemy_exception_handler(request: Request, exc: SQLAlchemyError):
    # Log a secure server-side error without credentials
    logger.error(f"Database error occurred: {type(exc).__name__}")
    return JSONResponse(
        status_code=500,
        content={"detail": "சேவையக தரவுத்தள பிழை (Internal database error occurred)"}
    )

app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(devotees.router, prefix="/api/devotees", tags=["Devotees"])
app.include_router(bills.router, prefix="/api/bills", tags=["Bills"])
app.include_router(reports.router, prefix="/api/reports", tags=["Reports"])
app.include_router(staff.router, prefix="/api/staff", tags=["Staff"])
app.include_router(finance.router, prefix="/api/finance", tags=["Finance"])

@app.get("/")
def root():
    return {"message": "செம்புகுட்டி சாஸ்தா திருக்கோவில் - Temple Billing System"}

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/health/db")
@app.get("/api/health")
def health_check(db: Session = Depends(get_db)):
    try:
        # Secure database health check query
        db.execute(text("SELECT 1"))
        return {"status": "ok"}
    except Exception as e:
        logger.error("Health check database query failed")
        return JSONResponse(
            status_code=500,
            content={"status": "error", "detail": "Database connection failed"}
        )