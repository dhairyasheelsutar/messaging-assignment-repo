import pytest
from fastapi.testclient import TestClient
from .main import app

load_balancer_hostname = "http://k8s-messagin-messagin-f0423e3afa-406709038.us-east-1.elb.amazonaws.com/"

# Create a TestClient to make requests to the FastAPI app
client = TestClient(app, base_url=load_balancer_hostname)

# Define some sample data for testing
sample_message = {
    "account_id": 12313,
    "sender_number": "1234567890",
    "receiver_number": "9876543210",
    "message_text": "Hello, World!"
}

# Test cases for the /create endpoint
def test_create_message():
    response = client.post("/api/v1/create", json=sample_message)
    assert response.status_code == 200
    data = response.json()
    assert "message_id" in data
    assert data["account_id"] == sample_message["account_id"]
    assert data["sender_number"] == sample_message["sender_number"]
    assert data["receiver_number"] == sample_message["receiver_number"]
    assert data["message_text"] == sample_message["message_text"]

# Test cases for the /get/messages/{account_id} endpoint
def test_get_messages():
    account_id = sample_message["account_id"]
    response = client.get(f"/api/v1/get/messages/{account_id}")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)

# Test cases for the /search endpoint
def test_search_messages():
    # Add some messages to the database for testing
    sample_messages = [sample_message.copy() for _ in range(3)]
    for msg in sample_messages:
        client.post("/api/v1/create", json=msg)

    # Search by message_id
    message_ids = ",".join([msg["message_id"] for msg in sample_messages])
    response = client.get(f"/api/v1/search?message_id={message_ids}")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) == len(sample_messages)

    # Search by sender_number
    sender_numbers = ",".join([msg["sender_number"] for msg in sample_messages])
    response = client.get(f"/api/v1/search?sender_number={sender_numbers}")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) == len(sample_messages)

    # Search by receiver_number
    receiver_numbers = ",".join([msg["receiver_number"] for msg in sample_messages])
    response = client.get(f"/api/v1/search?receiver_number={receiver_numbers}")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) == len(sample_messages)
