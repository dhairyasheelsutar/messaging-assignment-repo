# app/db/session.py

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from core.config import settings
print("hERE")
print(settings.DATABASE_URL)
DATABASE_URL = settings.DATABASE_URL

engine = create_engine(DATABASE_URL)
Session = sessionmaker(autocommit=False, autoflush=False, bind=engine)
db = Session()
