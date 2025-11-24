FROM ruby:3.2-alpine

# Install dependencies
RUN apk add --no-cache \
    build-base \
    ncurses \
    ncurses-dev \
    git \
    less

WORKDIR /app

# Copy Gemfile
COPY Gemfile* ./

# Install gems
RUN bundle install

# Copy application
COPY . .

# Create notes directory
RUN mkdir -p /root/grimoire_notes

# Set environment
ENV GRIMOIRE_NOTES_DIR=/root/grimoire_notes
ENV TERM=xterm-256color

CMD ["ruby", "grimoire.rb"]
