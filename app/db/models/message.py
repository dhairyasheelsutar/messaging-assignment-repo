# app/db/models/message.py

from sqlalchemy import Column, Integer, String
from db.base import Base


class MessageDB(Base):
    __tablename__ = "messages"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    message_id = Column(String(length=255), unique=True, index=True)
    account_id = Column(Integer, index=True)
    sender_number = Column(String(length=255), index=True)
    receiver_number = Column(String(length=255), index=True)
