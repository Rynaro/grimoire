FROM ruby:3.2

RUN apt-get update \
  && apt-get install -y --no-install-recommends build-essential git less ncurses-dev \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile .
RUN bundle install

COPY . .

ENV GRIMOIRE_NOTES_ROOT=/data/grimoire
VOLUME ["/data"]

CMD ["bin/grimoire", "--root", "/data/grimoire"]
