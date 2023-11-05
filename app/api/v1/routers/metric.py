from fastapi import APIRouter, HTTPException
from core.logger import logger
from fastapi.responses import Response
from prometheus_client import generate_latest, CollectorRegistry, Counter, Gauge

router = APIRouter()


# Create Prometheus metrics
requests_total = Counter(
    "http_requests_total",
    "Total HTTP Requests",
    ["method", "endpoint", "status"]
)


@router.get("/")
def metrics():
    logger.info("Received metrics scraping request")
    registry = CollectorRegistry()
    requests_total.labels(method="GET", endpoint="/", status="200").inc(1)
    prometheus_metrics = generate_latest(registry)
    return Response(content=prometheus_metrics, media_type="text/plain")
