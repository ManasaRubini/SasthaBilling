from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import or_
from typing import List, Optional
from app.database import get_db
from app.models.models import User, Devotee, Bill
from app.schemas.schemas import DevoteeCreate, DevoteeUpdate, DevoteeOut, BillOut
from app.utils.auth import get_current_user

router = APIRouter()

@router.get("/", response_model=List[DevoteeOut])
def list_devotees(
    search: Optional[str] = Query(None),
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(Devotee)
    if search:
        query = query.filter(
            or_(
                Devotee.devotee_name.ilike(f"%{search}%"),
                Devotee.mobile.ilike(f"%{search}%"),
                Devotee.village.ilike(f"%{search}%"),
                Devotee.family_id.ilike(f"%{search}%"),
            )
        )
    return query.order_by(Devotee.devotee_name).offset(skip).limit(limit).all()

@router.get("/{devotee_id}", response_model=DevoteeOut)
def get_devotee(devotee_id: int, db: Session = Depends(get_db),
                current_user: User = Depends(get_current_user)):
    devotee = db.query(Devotee).filter(Devotee.devotee_id == devotee_id).first()
    if not devotee:
        raise HTTPException(status_code=404, detail="பக்தர் கண்டுபிடிக்கப்படவில்லை")
    return devotee

@router.post("/", response_model=DevoteeOut)
def create_devotee(devotee_data: DevoteeCreate, db: Session = Depends(get_db),
                   current_user: User = Depends(get_current_user)):
    devotee = Devotee(**devotee_data.dict())
    db.add(devotee)
    db.commit()
    db.refresh(devotee)
    return devotee

@router.put("/{devotee_id}", response_model=DevoteeOut)
def update_devotee(devotee_id: int, devotee_data: DevoteeUpdate,
                   db: Session = Depends(get_db),
                   current_user: User = Depends(get_current_user)):
    devotee = db.query(Devotee).filter(Devotee.devotee_id == devotee_id).first()
    if not devotee:
        raise HTTPException(status_code=404, detail="பக்தர் கண்டுபிடிக்கப்படவில்லை")
    
    for key, value in devotee_data.dict(exclude_unset=True).items():
        setattr(devotee, key, value)
    
    db.commit()
    db.refresh(devotee)
    return devotee

@router.delete("/{devotee_id}")
def delete_devotee(devotee_id: int, db: Session = Depends(get_db),
                   current_user: User = Depends(get_current_user)):
    devotee = db.query(Devotee).filter(Devotee.devotee_id == devotee_id).first()
    if not devotee:
        raise HTTPException(status_code=404, detail="பக்தர் கண்டுபிடிக்கப்படவில்லை")

    bill_count = db.query(Bill).filter(Bill.devotee_id == devotee_id).count()
    if bill_count > 0:
        raise HTTPException(
            status_code=409,
            detail=f"இந்த பக்தருக்கு {bill_count} பில்லிங் பதிவுகள் உள்ளன, நீக்க முடியாது "
                   f"(This devotee has {bill_count} billing record(s) and cannot be deleted)"
        )

    db.delete(devotee)
    db.commit()
    return {"message": "பக்தர் நீக்கப்பட்டார்"}

@router.get("/{devotee_id}/history", response_model=List[BillOut])
def get_devotee_history(devotee_id: int, db: Session = Depends(get_db),
                        current_user: User = Depends(get_current_user)):
    bills = db.query(Bill).filter(
        Bill.devotee_id == devotee_id,
        Bill.status == "active"
    ).order_by(Bill.bill_date.desc()).all()
    return bills