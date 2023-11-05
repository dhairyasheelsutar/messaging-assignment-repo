from typing import Union
from fastapi import FastAPI

from db.session import engine
from db.base import Base
from api.v1.routers import messages, health, metric

Base.metadata.create_all(bind=engine)


app = FastAPI()

app.include_router(health.router)
app.include_router(metric.router, prefix="/metrics")
app.include_router(messages.router, prefix="/v1")
