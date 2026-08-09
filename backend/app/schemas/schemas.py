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
    
    # PDF storage & Cancellation details
    pdf_storage_key: Optional[str] = None
    cancelled_at: Optional[datetime] = None
    cancelled_by: Optional[int] = None
    cancellation_reason: Optional[str] = None

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

class BillUpdate(BaseModel):
    devotee_id: Optional[int] = None
    bill_type: Optional[BillType] = None
    category: Optional[str] = None
    amount: Optional[Decimal] = None
    payment_method: Optional[PaymentMethod] = None
    transaction_id: Optional[str] = None
    remarks: Optional[str] = None

class AuditLogOut(BaseModel):
    log_id: int
    user_id: Optional[int] = None
    username: Optional[str] = None
    action: str
    timestamp: datetime
    entity: Optional[str] = None
    entity_id: Optional[int] = None
    details: Optional[str] = None

    class Config:
        from_attributes = True

# Expense schemas
class ExpenseCreate(BaseModel):
    expense_date: datetime
    category: str
    description: str
    amount: Decimal
    payment_method: str
    reference_no: Optional[str] = None
    remarks: Optional[str] = None

class ExpenseUpdate(BaseModel):
    expense_date: Optional[datetime] = None
    category: Optional[str] = None
    description: Optional[str] = None
    amount: Optional[Decimal] = None
    payment_method: Optional[str] = None
    reference_no: Optional[str] = None
    remarks: Optional[str] = None
    status: Optional[str] = None

class ExpenseOut(BaseModel):
    expense_id: int
    expense_no: str
    expense_date: datetime
    category: str
    description: str
    amount: Decimal
    payment_method: str
    reference_no: Optional[str]
    remarks: Optional[str]
    status: str
    created_by: int
    created_at: datetime
    updated_at: Optional[datetime]

    class Config:
        from_attributes = True

# FinancialTransaction schemas
class FinancialTransactionOut(BaseModel):
    id: int
    transaction_no: str
    transaction_date: datetime
    transaction_type: str
    category: str
    description: Optional[str]
    amount: Decimal
    payment_method: str
    reference_number: Optional[str]
    bill_id: Optional[int]
    expense_id: Optional[int]
    status: str
    created_by: int
    created_at: datetime
    updated_at: Optional[datetime]
    remarks: Optional[str]

    class Config:
        from_attributes = True

class TransactionSummary(BaseModel):
    from_date: datetime
    to_date: datetime
    total_income: Decimal
    total_expense: Decimal
    net_balance: Decimal
    income_count: int
    expense_count: int