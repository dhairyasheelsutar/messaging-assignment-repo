# app/core/config.py

import os
from pydantic_settings import BaseSettings
from .logger import logger


class Settings(BaseSettings):
    DATABASE_URL: str


try:
    DB_PASSWORD = os.environ["DB_PASSWORD"]
    DB_HOST = os.environ["DB_HOST"]
    DB_USER = os.environ["DB_USER"]
    DB_NAME = os.environ["DB_NAME"]
    DB_PORT = os.environ["DB_PORT"]
    # Load database URL from environment variables
    DATABASE_URL = f"mysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    settings = Settings(DATABASE_URL=DATABASE_URL)
except Exception as e:
    logger.error("Error in getting database credentials")
    raise Exception(e)
