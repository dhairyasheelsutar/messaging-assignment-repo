# app/api/v1/routers/messages.py

from uuid import uuid4
from fastapi import APIRouter, HTTPException
from api.v1.models.message import MessageCreate, Message
from db.session import db
from db.models.message import MessageDB
from core.logger import logger

router = APIRouter()


@router.post("/create", response_model=Message)
def create_message(message: MessageCreate):
    logger.info("Received the request for the Create Message")

    db_message = message.dict()
    db_message["message_id"] = uuid4()

    db_obj = MessageDB(**db_message)
    db.add(db_obj)
    db.commit()

    return Message(**db_message)


@router.get("/get/messages/{account_id}", response_model=list[Message])
def get_messages(account_id: int):
    # Implement getting messages for a given account_id
    logger.info("Received the request for the selecting messages by account ID")
    return db.query(MessageDB).filter(MessageDB.account_id == account_id).all()


@router.get("/search", response_model=list[Message])
def search_messages(message_id: str = None, sender_number: str = None, receiver_number: str = None):

    logger.info(
        "Received the request for the searching the messages by ID, Sender Number & Receiver Number")
    query = db.query(MessageDB)

    if message_id:
        logger.info("Receiving by message IDs")
        message_ids = message_id.split(",")
        logger.info(f"Message ID: {message_ids}")
        query = query.filter(MessageDB.message_id.in_(message_ids))

    if sender_number:
        logger.info("Receiving by message ID")
        sender_numbers = sender_number.split(",")
        logger.info(f"Sender: {sender_numbers}")
        query = query.filter(MessageDB.sender_number.in_(sender_numbers))

    if receiver_number:
        logger.info("Receiving by message ID")
        receiver_numbers = receiver_number.split(",")
        logger.info(f"Receiver: {receiver_numbers}")
        query = query.filter(MessageDB.receiver_number.in_(receiver_numbers))

    logger.info(query)
    results = query.all()
    logger.info(results)
    return results
