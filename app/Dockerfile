# Use an official Python runtime as a parent image
FROM python:3.9

RUN apt-get update && apt-get install -y default-libmysqlclient-dev pkg-config

# Set environment variables
ENV APP_USER=app
ENV APP_HOME=/app

# Create a non-root user and set working directory
RUN useradd -m $APP_USER
WORKDIR $APP_HOME

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the FastAPI application code into the container
COPY . .

# Setup log directory
RUN mkdir -p /var/log/webservice
RUN chown -R $APP_USER:$APP_USER /var/log/webservice

# Change ownership of the application code to the non-root user
RUN chown -R $APP_USER:$APP_USER $APP_HOME

# Expose the port your FastAPI application will run on
EXPOSE 8080

# Switch to the non-root user
USER $APP_USER

# Run the FastAPI application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
