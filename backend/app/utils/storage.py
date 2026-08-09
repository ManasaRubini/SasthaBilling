import os
import logging
from typing import Optional
import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger("uvicorn.error")

STORAGE_ACCESS_KEY = os.getenv("STORAGE_ACCESS_KEY")
STORAGE_SECRET_KEY = os.getenv("STORAGE_SECRET_KEY")
STORAGE_BUCKET = os.getenv("STORAGE_BUCKET")
STORAGE_ENDPOINT = os.getenv("STORAGE_ENDPOINT")

def get_s3_client():
    if not (STORAGE_ACCESS_KEY and STORAGE_SECRET_KEY and STORAGE_BUCKET):
        return None
        
    s3_config = {}
    if STORAGE_ENDPOINT:
        s3_config["endpoint_url"] = STORAGE_ENDPOINT
        
    return boto3.client(
        "s3",
        aws_access_key_id=STORAGE_ACCESS_KEY,
        aws_secret_access_key=STORAGE_SECRET_KEY,
        **s3_config
    )

def upload_pdf_to_storage(pdf_bytes: bytes, filename: str) -> Optional[str]:
    """Upload PDF bytes to R2/S3. Returns the storage key (path) if successful."""
    client = get_s3_client()
    if not client:
        logger.warning("Object storage credentials not configured. Skipping upload.")
        return None
        
    # Standard prefix format: bills/YYYY/MM/filename
    from datetime import datetime
    now = datetime.now()
    key = f"bills/{now.year}/{now.month:02d}/{filename}"
    
    try:
        client.put_object(
            Bucket=STORAGE_BUCKET,
            Key=key,
            Body=pdf_bytes,
            ContentType="application/pdf"
        )
        logger.info(f"Successfully uploaded PDF to storage: {key}")
        return key
    except ClientError as e:
        logger.error(f"Failed to upload PDF to storage: {e}")
        return None

def download_pdf_from_storage(key: str) -> Optional[bytes]:
    """Download PDF bytes from R2/S3."""
    client = get_s3_client()
    if not client:
        return None
    try:
        response = client.get_object(Bucket=STORAGE_BUCKET, Key=key)
        return response["Body"].read()
    except ClientError as e:
        logger.error(f"Failed to download PDF from storage: {e}")
        return None
