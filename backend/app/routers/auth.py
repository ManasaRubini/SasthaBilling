from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
import os

from app.database import get_db
from app.models.models import User, AuditLog
from app.schemas.schemas import (
    LoginRequest,
    TokenResponse,
    UserCreate,
    UserOut,
)

from app.utils.auth import (
    verify_password,
    get_password_hash,
    create_access_token,
    get_current_user,
    require_admin,
)

router = APIRouter()


def authenticate_user(
    db: Session,
    username: str,
    password: str,
):
    user = (
        db.query(User)
        .filter(User.username == username)
        .first()
    )

    if not user:
        return None

    if not verify_password(
        password,
        user.password_hash,
    ):
        return None

    if not user.is_active:
        raise HTTPException(
            status_code=403,
            detail="User is inactive",
        )

    return user


def build_token(user: User):
    token = create_access_token(
        {
            "sub": str(user.user_id),
            "role": user.role,
        }
    )

    return TokenResponse(
        access_token=token,
        token_type="bearer",
        user_id=user.user_id,
        username=user.username,
        staff_name=user.staff_name,
        role=user.role,
    )


@router.post(
    "/login",
    response_model=TokenResponse,
)
def login(
    request: LoginRequest,
    db: Session = Depends(get_db),
):
    user = authenticate_user(
        db,
        request.username,
        request.password,
    )

    if user is None:
        # Audit failed login
        audit = AuditLog(
            action="login_failed",
            username=request.username,
            details=f"Failed login attempt for username: {request.username}"
        )
        db.add(audit)
        db.commit()
        raise HTTPException(
            status_code=401,
            detail="Invalid username or password",
        )

    # Audit successful login
    audit = AuditLog(
        user_id=user.user_id,
        username=user.username,
        action="login_success",
        details=f"Successful login for user: {user.username}"
    )
    db.add(audit)
    db.commit()

    return build_token(user)


@router.post(
    "/token",
    response_model=TokenResponse,
)
def login_oauth2(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db),
):
    user = authenticate_user(
        db,
        form_data.username,
        form_data.password,
    )

    if user is None:
        # Audit failed login
        audit = AuditLog(
            action="login_failed",
            username=form_data.username,
            details=f"Failed OAuth2 login attempt for username: {form_data.username}"
        )
        db.add(audit)
        db.commit()
        raise HTTPException(
            status_code=401,
            detail="Invalid username or password",
        )

    # Audit successful login
    audit = AuditLog(
        user_id=user.user_id,
        username=user.username,
        action="login_success",
        details=f"Successful OAuth2 login for user: {user.username}"
    )
    db.add(audit)
    db.commit()

    return build_token(user)


@router.get(
    "/me",
    response_model=UserOut,
)
def get_me(
    current_user: User = Depends(get_current_user),
):
    return current_user


@router.post(
    "/create-user",
    response_model=UserOut,
)
def create_user(
    user_data: UserCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    existing = (
        db.query(User)
        .filter(User.username == user_data.username)
        .first()
    )

    if existing:
        raise HTTPException(
            status_code=400,
            detail="Username already exists",
        )

    user = User(
        username=user_data.username,
        password_hash=get_password_hash(user_data.password),
        staff_name=user_data.staff_name,
        role=user_data.role,
        mobile=user_data.mobile,
    )

    db.add(user)
    db.commit()
    db.refresh(user)

    # Audit staff creation
    audit = AuditLog(
        user_id=current_user.user_id,
        username=current_user.username,
        action="create_staff",
        entity="user",
        entity_id=user.user_id,
        details=f"Created staff user: {user.username} with role: {user.role}"
    )
    db.add(audit)
    db.commit()

    return user


@router.post("/setup-admin")
def setup_admin(
    db: Session = Depends(get_db),
):
    # Only allow setup if no admin user exists in the database
    admin_exists = db.query(User).filter(User.role == "admin").count() > 0
    if admin_exists:
        raise HTTPException(
            status_code=400,
            detail="நிர்வாகி கணக்கு ஏற்கனவே உருவாக்கப்பட்டுள்ளது (Admin account already exists)"
        )

    admin_username = os.getenv("ADMIN_USERNAME", "admin")
    admin_password = os.getenv("ADMIN_PASSWORD", "temple@2024")

    admin = User(
        username=admin_username,
        password_hash=get_password_hash(admin_password),
        staff_name="நிர்வாகி",
        role="admin",
        mobile="9999999999",
    )

    db.add(admin)
    db.commit()
    db.refresh(admin)

    # Audit setup admin action
    audit = AuditLog(
        action="setup_admin",
        username=admin_username,
        details="Initial administrator setup completed."
    )
    db.add(audit)
    db.commit()

    return {
        "message": "நிர்வாகி கணக்கு வெற்றிகரமாக உருவாக்கப்பட்டது (Admin setup completed)",
        "username": admin_username,
    }