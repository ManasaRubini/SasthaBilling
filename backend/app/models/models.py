from sqlalchemy import Column, Integer, String, DateTime, Numeric, Enum, ForeignKey, Text, Boolean
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
import enum

class UserRole(str, enum.Enum):
    admin = "admin"
    staff = "staff"

class BillType(str, enum.Enum):
    vari = "வரி"
    kanikkai = "காணிக்கை"

class PaymentMethod(str, enum.Enum):
    cash = "பணம்"
    upi = "UPI"
    card = "கார்டு"
    cheque = "காசோலை"

class BillStatus(str, enum.Enum):
    active = "active"
    cancelled = "cancelled"

class User(Base):
    __tablename__ = "users"

    user_id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    staff_name = Column(String(100), nullable=False)
    role = Column(Enum(UserRole), default=UserRole.staff)
    mobile = Column(String(15))
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    bills = relationship("Bill", back_populates="staff", foreign_keys="[Bill.staff_id]")

class Devotee(Base):
    __tablename__ = "devotees"

    devotee_id = Column(Integer, primary_key=True, index=True)
    devotee_name = Column(String(100), nullable=False, index=True)
    father_name = Column(String(100))
    mobile = Column(String(15), index=True)
    address = Column(Text)
    village = Column(String(100))
    family_id = Column(String(50))
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    bills = relationship("Bill", back_populates="devotee")

class Bill(Base):
    __tablename__ = "bills"

    bill_id = Column(Integer, primary_key=True, index=True)
    receipt_no = Column(String(20), unique=True, nullable=False, index=True)
    devotee_id = Column(Integer, ForeignKey("devotees.devotee_id"), nullable=False, index=True)
    staff_id = Column(Integer, ForeignKey("users.user_id"), nullable=False, index=True)
    bill_type = Column(Enum(BillType), nullable=False)
    category = Column(String(100))
    amount = Column(Numeric(10, 2), nullable=False)
    payment_method = Column(Enum(PaymentMethod), default=PaymentMethod.cash)
    transaction_id = Column(String(100), index=True)
    remarks = Column(Text)
    status = Column(Enum(BillStatus), default=BillStatus.active, index=True)
    bill_date = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)

    # PDF storage & Cancellation details
    pdf_storage_key = Column(String(255), nullable=True)
    cancelled_at = Column(DateTime(timezone=True), nullable=True)
    cancelled_by = Column(Integer, ForeignKey("users.user_id"), nullable=True)
    cancellation_reason = Column(String(255), nullable=True)

    devotee = relationship("Devotee", back_populates="bills")
    staff = relationship("User", back_populates="bills", foreign_keys=[staff_id])
    cancelled_by_user = relationship("User", foreign_keys=[cancelled_by])
    
    financial_transaction = relationship("FinancialTransaction", back_populates="bill", uselist=False)

class AuditLog(Base):
    __tablename__ = "audit_logs"

    log_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=True)
    username = Column(String(100), nullable=True)
    action = Column(String(100), nullable=False)
    timestamp = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    entity = Column(String(50), nullable=True)
    entity_id = Column(Integer, nullable=True)
    details = Column(Text, nullable=True)

    user = relationship("User")

class TransactionType(str, enum.Enum):
    income = "INCOME"
    expense = "EXPENSE"

class TransactionStatus(str, enum.Enum):
    active = "active"
    cancelled = "cancelled"

class Expense(Base):
    __tablename__ = "expenses"

    expense_id = Column(Integer, primary_key=True, index=True)
    expense_no = Column(String(50), unique=True, nullable=False, index=True)
    expense_date = Column(DateTime(timezone=True), nullable=False, index=True)
    category = Column(String(100), nullable=False, index=True)
    description = Column(String(255), nullable=False)
    amount = Column(Numeric(10, 2), nullable=False)
    payment_method = Column(String(50), nullable=False, index=True)
    reference_no = Column(String(100))
    remarks = Column(Text)
    status = Column(String(50), default="active", index=True)
    
    created_by = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    cancelled_at = Column(DateTime(timezone=True), nullable=True)
    cancelled_by = Column(Integer, ForeignKey("users.user_id"), nullable=True)
    cancellation_reason = Column(String(255), nullable=True)

    creator = relationship("User", foreign_keys=[created_by])
    canceller = relationship("User", foreign_keys=[cancelled_by])
    financial_transaction = relationship("FinancialTransaction", back_populates="expense", uselist=False)

class FinancialTransaction(Base):
    __tablename__ = "financial_transactions"

    id = Column(Integer, primary_key=True, index=True)
    transaction_no = Column(String(50), unique=True, nullable=False, index=True)
    transaction_date = Column(DateTime(timezone=True), nullable=False, index=True)
    transaction_type = Column(Enum(TransactionType), nullable=False, index=True)
    category = Column(String(100), nullable=False, index=True)
    description = Column(String(255))
    amount = Column(Numeric(10, 2), nullable=False)
    payment_method = Column(String(50), nullable=False, index=True)
    reference_number = Column(String(100), index=True)
    
    bill_id = Column(Integer, ForeignKey("bills.bill_id"), nullable=True, index=True)
    expense_id = Column(Integer, ForeignKey("expenses.expense_id"), nullable=True, index=True)
    status = Column(Enum(TransactionStatus), default=TransactionStatus.active, index=True)
    
    created_by = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    remarks = Column(Text)

    bill = relationship("Bill", back_populates="financial_transaction")
    expense = relationship("Expense", back_populates="financial_transaction")
    creator = relationship("User", foreign_keys=[created_by])