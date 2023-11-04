from fastapi import APIRouter, HTTPException
from core.logger import logger

router = APIRouter()


@router.get("/")
def service_health():
    logger.info("Received health check request")
    return {
        "message": "Service is running properly"
    }
