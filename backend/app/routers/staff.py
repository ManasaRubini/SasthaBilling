from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app.models.models import User, Bill
from app.schemas.schemas import UserOut, UserUpdate
from app.utils.auth import get_current_user, require_admin, get_password_hash

router = APIRouter()

@router.get("/", response_model=List[UserOut])
def list_staff(db: Session = Depends(get_db),
               current_user: User = Depends(require_admin)):
    return db.query(User).order_by(User.staff_name).all()

@router.get("/{user_id}", response_model=UserOut)
def get_staff(user_id: int, db: Session = Depends(get_db),
              current_user: User = Depends(require_admin)):
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="பணியாளர் கண்டுபிடிக்கப்படவில்லை")
    return user

@router.put("/{user_id}", response_model=UserOut)
def update_staff(user_id: int, user_data: UserUpdate, db: Session = Depends(get_db),
                 current_user: User = Depends(require_admin)):
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="பணியாளர் கண்டுபிடிக்கப்படவில்லை")

    for key, value in user_data.dict(exclude_unset=True).items():
        setattr(user, key, value)

    db.commit()
    db.refresh(user)
    return user

@router.put("/{user_id}/reset-password")
def reset_password(user_id: int, new_password: str, db: Session = Depends(get_db),
                   current_user: User = Depends(require_admin)):
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="பணியாளர் கண்டுபிடிக்கப்படவில்லை")

    user.password_hash = get_password_hash(new_password)
    db.commit()
    return {"message": "கடவுச்சொல் மீட்டமைக்கப்பட்டது"}

@router.delete("/{user_id}")
def deactivate_staff(user_id: int, db: Session = Depends(get_db),
                     current_user: User = Depends(require_admin)):
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="பணியாளர் கண்டுபிடிக்கப்படவில்லை")

    user.is_active = False
    db.commit()
    return {"message": "பணியாளர் செயலிழக்கப்பட்டார்"}

@router.get("/{user_id}/history")
def get_staff_history(user_id: int, db: Session = Depends(get_db),
                      current_user: User = Depends(get_current_user)):
    bills = db.query(Bill).filter(
        Bill.staff_id == user_id,
        Bill.status == "active"
    ).order_by(Bill.bill_date.desc()).limit(100).all()

    return [{
        "bill_id": b.bill_id,
        "receipt_no": b.receipt_no,
        "devotee_name": b.devotee.devotee_name,
        "bill_type": b.bill_type,
        "amount": float(b.amount),
        "bill_date": b.bill_date.isoformat()
    } for b in bills]