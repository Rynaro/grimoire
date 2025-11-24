FROM ruby:3.2-alpine

# Install dependencies
RUN apk add --no-cache \
    build-base \
    ncurses \
    ncurses-dev \
    ncurses-terminfo \
    git \
    less \
    bash

WORKDIR /app

# Copy Gemfile first for better caching
COPY Gemfile Gemfile.lock* ./

# Install gems
RUN bundle install --jobs 4 --retry 3

# Copy application code
COPY . .

# Create notes directory
RUN mkdir -p /root/grimoire_notes

# Set environment variables
ENV GRIMOIRE_NOTES_DIR=/root/grimoire_notes
ENV TERM=xterm-256color
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Make grimoire executable
RUN chmod +x grimoire.rb

# Default command
CMD ["ruby", "grimoire.rb"]
