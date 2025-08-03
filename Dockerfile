# Use Ruby 3.3.8 as the base image
FROM ruby:3.3.8

# Set the working directory inside the container
WORKDIR /app

# Install system dependencies
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libssl-dev \
    libreadline-dev \
    zlib1g-dev \
    ca-certificates \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy Gemfile and Gemfile.lock to leverage Docker cache
COPY Gemfile Gemfile.lock ./

# Install Ruby dependencies
# Note: If SSL certificate issues occur in your environment, temporarily uncomment the following lines:
# RUN git config --global http.sslverify false
# ENV BUNDLE_DISABLE_SSL_VERIFY=true
RUN bundle config set --global force_ruby_platform true && \
    bundle install
# If you uncommented the SSL workarounds above, uncomment these lines too:
# RUN git config --global --unset http.sslverify
# ENV BUNDLE_DISABLE_SSL_VERIFY=false

# Copy the rest of the application code
COPY . .

# Create directories that might be needed
RUN mkdir -p json_measures

# Expose port 3000 (for potential web interface or API)
EXPOSE 3000

# Default command
CMD ["bundle", "exec", "ruby", "script.rb"]