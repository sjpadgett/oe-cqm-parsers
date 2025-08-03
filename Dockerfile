# Use Ruby 3.3.8 as the base image
FROM ruby:3.3.8

# Set the working directory inside the container
WORKDIR /app

# Install system dependencies and update certificates
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libssl-dev \
    libreadline-dev \
    zlib1g-dev \
    ca-certificates \
    git \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy Gemfile and Gemfile.lock to leverage Docker cache
COPY Gemfile Gemfile.lock ./

# Configure bundle and git for installation
# Temporarily disable SSL verification for bundle install due to container environment
RUN bundle config set --global force_ruby_platform true \
    && git config --global http.sslverify false \
    && bundle config set --local disable_ssl_verify true \
    && BUNDLE_DISABLE_SSL_VERIFY=true bundle install \
    && git config --global --unset http.sslverify \
    && bundle config unset disable_ssl_verify

# Copy the rest of the application code
COPY . .

# Create directories that might be needed
RUN mkdir -p json_measures

# Expose port 3000 (for potential web interface or API)
EXPOSE 3000

# Default command - can be overridden in docker-compose or docker run
CMD ["bundle", "exec", "ruby", "script.rb"]