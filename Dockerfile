FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY grimoire.py .

# Create a volume for notes
VOLUME /notes

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV TERM=xterm-256color

# Create entrypoint script
RUN echo '#!/bin/bash\npython grimoire.py --notes-dir /notes "$@"' > /entrypoint.sh && \
    chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
