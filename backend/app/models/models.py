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

    bills = relationship("Bill", back_populates="staff")

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
    devotee_id = Column(Integer, ForeignKey("devotees.devotee_id"), nullable=False)
    staff_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    bill_type = Column(Enum(BillType), nullable=False)
    category = Column(String(100))
    amount = Column(Numeric(10, 2), nullable=False)
    payment_method = Column(Enum(PaymentMethod), default=PaymentMethod.cash)
    transaction_id = Column(String(100))
    remarks = Column(Text)
    status = Column(Enum(BillStatus), default=BillStatus.active)
    bill_date = Column(DateTime(timezone=True), server_default=func.now())
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    devotee = relationship("Devotee", back_populates="bills")
    staff = relationship("User", back_populates="bills")