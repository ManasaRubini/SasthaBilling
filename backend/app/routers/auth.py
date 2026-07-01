from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.models import User
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
        raise HTTPException(
            status_code=401,
            detail="Invalid username or password",
        )

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
        raise HTTPException(
            status_code=401,
            detail="Invalid username or password",
        )

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

    return user


@router.post("/setup-admin")
def setup_admin(
    db: Session = Depends(get_db),
):

    existing = (
        db.query(User)
        .filter(User.username == "admin")
        .first()
    )

    if existing:
        return {"message": "Admin already exists"}

    admin = User(
        username="admin",
        password_hash=get_password_hash("temple@2024"),
        staff_name="நிர்வாகி",
        role="admin",
        mobile="9999999999",
    )

    db.add(admin)
    db.commit()

    return {
        "message": "Admin created",
        "username": "admin",
        "password": "temple@2024",
    }