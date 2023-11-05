import requests
import string
import random
import pytest


load_balancer_hostname = "http://k8s-messagin-messagin-f0423e3afa-406709038.us-east-1.elb.amazonaws.com"

# Create a TestClient to make requests to the FastAPI app
# client = TestClient(app, base_url=load_balancer_hostname)


def generate_random_10_digit_string():
    digits = string.digits  # '0123456789'
    random_string = ''.join(random.choice(digits) for _ in range(10))
    return random_string


# Define some sample data for testing
sample_message = {
    "account_id": random.randint(1000, 99999),
    "sender_number": generate_random_10_digit_string(),
    "receiver_number": generate_random_10_digit_string(),
}

# Test cases for the /create endpoint


def test_create_message():
    response = requests.post(
        f"{load_balancer_hostname}/v1/create",
        json=sample_message
    )
    assert response.status_code == 200
    data = response.json()
    assert "message_id" in data
    sample_message["message_id"] = data["message_id"]
    assert data["account_id"] == sample_message["account_id"]
    assert data["sender_number"] == sample_message["sender_number"]
    assert data["receiver_number"] == sample_message["receiver_number"]

# Test cases for the /get/messages/{account_id} endpoint


def test_get_messages():
    account_id = sample_message["account_id"]
    response = requests.get(
        f"{load_balancer_hostname}/v1/get/messages/{account_id}")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)

# Test cases for the /search endpoint


@pytest.mark.run(after="test_create_message")
def test_search_messages():
    message_ids = ",".join([sample_message["message_id"]])

    # Search by message_id
    response = requests.get(
        f"{load_balancer_hostname}/v1/search?message_id={message_ids}")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) == len(message_ids.split(","))

    # Search by sender_number
    sender_numbers = ",".join([sample_message["sender_number"]])
    response = requests.get(
        f"{load_balancer_hostname}/v1/search?sender_number={sender_numbers}")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) == len(sender_numbers.split(","))

    # Search by receiver_number
    receiver_numbers = ",".join([sample_message["receiver_number"]])
    response = requests.get(
        f"{load_balancer_hostname}/v1/search?receiver_number={receiver_numbers}")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) == len(receiver_numbers.split(","))
