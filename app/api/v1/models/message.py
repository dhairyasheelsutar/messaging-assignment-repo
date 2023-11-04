# app/api/v1/models/message.py

from pydantic import BaseModel
from uuid import UUID


class MessageCreate(BaseModel):
    account_id: int
    sender_number: str
    receiver_number: str


class Message(MessageCreate):
    message_id: UUID
