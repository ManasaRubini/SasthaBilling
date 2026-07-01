from fastapi import APIRouter, Depends, Query, Response
from sqlalchemy.orm import Session
from sqlalchemy import func, cast, Date
from datetime import datetime, date, timedelta
from typing import List, Optional
from app.database import get_db
from app.models.models import User, Devotee, Bill
from app.utils.auth import get_current_user, require_admin
from app.utils.pdf_generator import generate_report_pdf

router = APIRouter()

@router.get("/daily")
def daily_report(
    report_date: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if report_date:
        target = datetime.strptime(report_date, "%Y-%m-%d")
    else:
        target = datetime.now()
    
    day_start = target.replace(hour=0, minute=0, second=0, microsecond=0)
    day_end = target.replace(hour=23, minute=59, second=59)
    
    bills = db.query(Bill).filter(
        Bill.bill_date >= day_start,
        Bill.bill_date <= day_end,
        Bill.status == "active"
    ).all()
    
    return {
        "date": target.strftime("%d-%m-%Y"),
        "total_amount": sum(float(b.amount) for b in bills),
        "vari_amount": sum(float(b.amount) for b in bills if b.bill_type == "வரி"),
        "kanikkai_amount": sum(float(b.amount) for b in bills if b.bill_type == "காணிக்கை"),
        "bill_count": len(bills),
        "cash_amount": sum(float(b.amount) for b in bills if b.payment_method == "பணம்"),
        "upi_amount": sum(float(b.amount) for b in bills if b.payment_method == "UPI"),
        "card_amount": sum(float(b.amount) for b in bills if b.payment_method == "கார்டு"),
        "bills": [
            {
                "receipt_no": b.receipt_no,
                "devotee_name": b.devotee.devotee_name,
                "bill_type": b.bill_type,
                "amount": float(b.amount),
                "payment_method": b.payment_method,
                "staff_name": b.staff.staff_name,
                "time": b.bill_date.strftime("%I:%M %p")
            } for b in bills
        ]
    }

@router.get("/monthly")
def monthly_report(
    year: int = Query(datetime.now().year),
    month: int = Query(datetime.now().month),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    from calendar import monthrange
    _, last_day = monthrange(year, month)
    month_start = datetime(year, month, 1)
    month_end = datetime(year, month, last_day, 23, 59, 59)
    
    bills = db.query(Bill).filter(
        Bill.bill_date >= month_start,
        Bill.bill_date <= month_end,
        Bill.status == "active"
    ).all()
    
    # Group by day
    daily = {}
    for b in bills:
        d = b.bill_date.strftime("%d-%m-%Y")
        if d not in daily:
            daily[d] = {"date": d, "count": 0, "total": 0, "vari": 0, "kanikkai": 0}
        daily[d]["count"] += 1
        daily[d]["total"] += float(b.amount)
        if b.bill_type == "வரி":
            daily[d]["vari"] += float(b.amount)
        else:
            daily[d]["kanikkai"] += float(b.amount)
    
    return {
        "year": year,
        "month": month,
        "total_collection": sum(float(b.amount) for b in bills),
        "vari_total": sum(float(b.amount) for b in bills if b.bill_type == "வரி"),
        "kanikkai_total": sum(float(b.amount) for b in bills if b.bill_type == "காணிக்கை"),
        "bill_count": len(bills),
        "daily_breakdown": list(daily.values())
    }

@router.get("/staff")
def staff_report(
    report_date: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    if report_date:
        target = datetime.strptime(report_date, "%Y-%m-%d")
    else:
        target = datetime.now()
    
    day_start = target.replace(hour=0, minute=0, second=0, microsecond=0)
    day_end = target.replace(hour=23, minute=59, second=59)
    
    staff_list = db.query(User).filter(User.is_active == True).all()
    result = []
    
    for staff in staff_list:
        bills = db.query(Bill).filter(
            Bill.staff_id == staff.user_id,
            Bill.bill_date >= day_start,
            Bill.bill_date <= day_end,
            Bill.status == "active"
        ).all()
        
        result.append({
            "staff_name": staff.staff_name,
            "username": staff.username,
            "bill_count": len(bills),
            "vari_amount": sum(float(b.amount) for b in bills if b.bill_type == "வரி"),
            "kanikkai_amount": sum(float(b.amount) for b in bills if b.bill_type == "காணிக்கை"),
            "total_amount": sum(float(b.amount) for b in bills)
        })
    
    return {"date": target.strftime("%d-%m-%Y"), "staff_reports": result}

@router.get("/export/daily")
def export_daily_pdf(
    report_date: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    data = daily_report(report_date, db, current_user)
    
    headers = ["ரசீது எண்", "பக்தர் பெயர்", "வகை", "தொகை", "பணம்", "பணியாளர்", "நேரம்"]
    rows = [[
        b["receipt_no"], b["devotee_name"], b["bill_type"],
        f"₹{b['amount']:,.2f}", b["payment_method"], b["staff_name"], b["time"]
    ] for b in data["bills"]]
    
    pdf = generate_report_pdf(
        {"headers": headers, "rows": rows},
        f"Daily Collection - {data['date']}"
    )
    
    return Response(content=pdf, media_type="application/pdf",
                   headers={"Content-Disposition": f"attachment; filename=daily_report_{data['date']}.pdf"})