FROM ruby:3.2-slim

WORKDIR /app

# Install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy Gemfile and gemspec
COPY Gemfile grimoire.gemspec ./

# Install gems
RUN bundle install

# Copy application code
COPY . .

# Set up notes directory
RUN mkdir -p /root/.grimoire/notes

# Make executable
RUN chmod +x bin/grimoire

# Set environment variable for notes directory
ENV GRIMOIRE_NOTES_DIR=/root/.grimoire/notes

# Default command
CMD ["ruby", "bin/grimoire"]
