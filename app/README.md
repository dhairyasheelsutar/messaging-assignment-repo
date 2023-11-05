# Messaging Service with FastAPI

This README provides an overview and explanation of a messaging service implemented using FastAPI. We will cover various aspects of the codebase, including its structure, Dockerization, logging, testing, API endpoints, and how to run the service. Let's start by examining the directory structure.

## 1. Directory Structure

The directory structure of the project is as follows:

- /app
  - requirements.txt
  - main.py
  - Dockerfile
  - .dockerignore
  - /db
    - base.py
    - session.py
    - /models
      - message.py
  - /api
    - /v1
      - /models
        - message.py
      - /routers
        - health.py
        - metric.py
        - messages.py
  - /core
    - config.py
    - logger.py
  - test_main.py

Now, let's dive into each aspect of the project.

## 2. Dockerfile and .dockerignore

### Dockerfile
The `Dockerfile` is used to create a Docker image for the FastAPI application. Here's a breakdown of its components:

- It starts with an official Python 3.9 image as the base image.
- It installs system-level dependencies using `apt-get` to ensure the application can work with MySQL.
- Environment variables for the application user and home directory are set.
- The non-root user `app` is created, and the working directory is set to `/app`.
- Python dependencies are installed from `requirements.txt`.
- The FastAPI application code is copied into the container.
- A log directory is created, and ownership is changed to the non-root user.
- Port 8080 is exposed, and the container runs the FastAPI application using `uvicorn`.

### .dockerignore
The `.dockerignore` file specifies files and directories that should be excluded when copying files into the Docker container. In this case, it excludes `venv/` and `__pycache__/` directories.

This setup helps optimize the Docker image for security and build caching. By excluding unnecessary files and directories, you reduce the attack surface and make the build process more efficient.

## 3. Logging / Error Handling

Logging is configured in the `core/logger.py` file. It sets up a logger with the following features:

- Logging to both console and a rotating log file (`app.log`).
- Log messages include a timestamp, logger name, log level, and message content.
- The log file has a maximum size of 2000 bytes, and up to 10 backup files are retained.

This logging setup helps in recording application activities and errors, making it easier to diagnose issues and monitor the service.

## 4. Test Cases

Test cases are defined in the `test_main.py` file using the `pytest` framework. The tests make HTTP requests to the FastAPI application and assert the expected behavior. Here are the key test cases:

- `test_create_message`: Sends a POST request to the `/v1/create` endpoint to create a message and verifies the response.
- `test_get_messages`: Sends a GET request to the `/v1/get/messages/{account_id}` endpoint to retrieve messages for a specific account.
- `test_search_messages`: Sends GET requests to the `/v1/search` endpoint with different query parameters to search for messages.

These tests help ensure that the messaging service functions as expected and provide a safety net for code changes.

## 5. API Endpoints

The FastAPI application defines several API endpoints in the `app/main.py` file, which are organized into routers. The key endpoints and their functionality are as follows:

- `/health`: This endpoint, defined in `api/v1/routers/health.py`, provides a basic health check and returns a JSON response indicating the service is running properly.
- `/metrics`: The `/metrics` endpoint, defined in `api/v1/routers/metric.py`, serves Prometheus metrics. It increments a counter for each incoming request.
- `/v1/create`: This POST endpoint, defined in `api/v1/routers/messages.py`, is used to create a message. It takes a JSON payload and returns the created message with a unique `message_id`.
- `/v1/get/messages/{account_id}`: This GET endpoint, also in `messages.py`, retrieves messages for a specific account based on the `account_id`.
- `/v1/search`: This GET endpoint in `messages.py` allows searching for messages using query parameters such as `message_id`, `sender_number`, and `receiver_number`.

These endpoints together provide the core functionality of the messaging service.

## 6. Testing and Execution

To test and execute the code, follow these steps:

1. Ensure you have Docker installed on your system.
2. Navigate to the project directory.
3. Build the Docker image using the provided `Dockerfile`:

```bash
docker build -t messaging-service .
```

4. Provide environmental variables `DB_USER`, `DB_PASSWORD`, `DB_NAME`, `DB_PORT` and `DB_PORT`. This configurations specify the MySQL database configuration. So make sure you have MySQL database running first.

```bash
docker run -d -p 8080:8080 messaging-service
```

The FastAPI application should now be running in the container. You can access the API at **http://localhost:8080**.

For testing, run the pytest tests from the project directory:

```bash
pytest 
```

7. Code Documentation

- `requirements.txt`: Lists Python package dependencies required for the project.
- `main.py`: The main FastAPI application file.
- `Dockerfile`: Specifies instructions for building a Docker image.
- `.dockerignore`: Excludes unnecessary files from the Docker image.
- `db/base.py`: Contains the base model for SQLAlchemy declarative classes.
- `db/session.py`: Sets up the database session and engine.
- `db/models/message.py`: Defines the SQLAlchemy model for messages.
- `api/v1/models/message.py`: Contains Pydantic models for messages.
- `api/v1/routers/metric.py`: Defines the /metrics endpoint and Prometheus metrics.
- `api/v1/routers/messages.py`: Contains the core messaging endpoints.
- `api/v1/routers/health.py`: Defines the /health endpoint for health checks.
- `core/config.py`: Manages environment variables and settings.
- `core/logger.py`: Sets up logging for the application.
- `test_main.py`: Contains test cases for the FastAPI application.
