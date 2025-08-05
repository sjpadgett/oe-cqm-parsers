FROM ruby:3.3

# Install required dependencies
RUN apt-get update -qq && \
    apt-get install -y build-essential git libpq-dev nodejs

# Create app directory
WORKDIR /app

# Install bundler and dependencies
COPY Gemfile Gemfile.lock ./
RUN gem install bundler && bundle install

# Copy app code
COPY . .

# Default command (can override with docker exec or -it)
CMD ["irb"]
