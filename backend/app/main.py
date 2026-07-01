from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database import engine, Base
from app.routers import auth, devotees, bills, reports, staff

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Temple Billing Management System",
    description="செம்புகுட்டி சாஸ்தா திருக்கோவில் - Billing System API",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(devotees.router, prefix="/api/devotees", tags=["Devotees"])
app.include_router(bills.router, prefix="/api/bills", tags=["Bills"])
app.include_router(reports.router, prefix="/api/reports", tags=["Reports"])
app.include_router(staff.router, prefix="/api/staff", tags=["Staff"])

@app.get("/")
def root():
    return {"message": "செம்புகுட்டி சாஸ்தா திருக்கோவில் - Temple Billing System"}