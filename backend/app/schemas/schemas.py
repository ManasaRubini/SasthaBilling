from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime
from decimal import Decimal
from enum import Enum

class UserRole(str, Enum):
    admin = "admin"
    staff = "staff"

class BillType(str, Enum):
    vari = "வரி"
    kanikkai = "காணிக்கை"

class PaymentMethod(str, Enum):
    cash = "பணம்"
    upi = "UPI"
    card = "கார்டு"
    cheque = "காசோலை"

# Auth schemas
class LoginRequest(BaseModel):
    username: str
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str
    user_id: int
    username: str
    staff_name: str
    role: str

# User schemas
class UserCreate(BaseModel):
    username: str
    password: str
    staff_name: str
    role: UserRole = UserRole.staff
    mobile: Optional[str] = None

class UserUpdate(BaseModel):
    staff_name: Optional[str] = None
    mobile: Optional[str] = None
    role: Optional[UserRole] = None
    is_active: Optional[bool] = None

class UserOut(BaseModel):
    user_id: int
    username: str
    staff_name: str
    role: str
    mobile: Optional[str]
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True

# Devotee schemas
class DevoteeCreate(BaseModel):
    devotee_name: str
    father_name: Optional[str] = None
    mobile: Optional[str] = None
    address: Optional[str] = None
    village: Optional[str] = None
    family_id: Optional[str] = None

class DevoteeUpdate(BaseModel):
    devotee_name: Optional[str] = None
    father_name: Optional[str] = None
    mobile: Optional[str] = None
    address: Optional[str] = None
    village: Optional[str] = None
    family_id: Optional[str] = None

class DevoteeOut(BaseModel):
    devotee_id: int
    devotee_name: str
    father_name: Optional[str]
    mobile: Optional[str]
    address: Optional[str]
    village: Optional[str]
    family_id: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True

# Bill schemas
class BillCreate(BaseModel):
    devotee_id: int
    bill_type: BillType
    category: Optional[str] = None
    amount: Decimal
    payment_method: PaymentMethod = PaymentMethod.cash
    transaction_id: Optional[str] = None
    remarks: Optional[str] = None

class BillOut(BaseModel):
    bill_id: int
    receipt_no: str
    devotee_id: int
    staff_id: int
    bill_type: str
    category: Optional[str]
    amount: Decimal
    payment_method: str
    transaction_id: Optional[str]
    remarks: Optional[str]
    status: str
    bill_date: datetime
    devotee: Optional[DevoteeOut]
    staff: Optional[UserOut]

    class Config:
        from_attributes = True

# Dashboard schema
class DashboardStats(BaseModel):
    today_collection: Decimal
    today_vari: Decimal
    today_kanikkai: Decimal
    today_bills_count: int
    total_devotees: int
    total_staff: int
    monthly_collection: Decimal

# Report schemas
class DailyReport(BaseModel):
    date: str
    total_amount: Decimal
    vari_amount: Decimal
    kanikkai_amount: Decimal
    bill_count: int
    cash_amount: Decimal
    upi_amount: Decimal
    card_amount: Decimal

class StaffReport(BaseModel):
    staff_name: str
    bill_count: int
    vari_amount: Decimal
    kanikkai_amount: Decimal
    total_amount: Decimal