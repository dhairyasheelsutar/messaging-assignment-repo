# logger.py

import logging
from logging.handlers import RotatingFileHandler
import sys

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

# Create a console handler
ch = logging.StreamHandler(sys.stdout)
ch.setLevel(logging.DEBUG)

# Create a file logger
file = RotatingFileHandler(
    "/var/log/webservice/app.log",
    mode="a",
    maxBytes=2000,
    backupCount=10
)
file.setLevel(logging.DEBUG)

# Create a formatter and set it for the handler
formatter = logging.Formatter(
    "%(asctime)s - %(name)s - %(levelname)s - %(message)s")
ch.setFormatter(formatter)

# Add the handler to the logger
logger.addHandler(ch)
logger.addHandler(file)
