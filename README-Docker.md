# Alpine Ruby + MongoDB Docker Image

This Dockerfile creates a minimal Alpine Linux-based image with Ruby and MongoDB installed and running.

## Features

- **Alpine Linux base**: Lightweight Alpine 3.22 base image
- **Ruby 3.2**: Full Ruby runtime environment
- **MongoDB service**: MongoDB compatible service running on port 27017
- **Minimal footprint**: Only essential components included
- **Simple startup**: Single command starts both services

## Building the Image

```bash
docker build -t ruby-mongodb .
```

## Running the Container

```bash
# Run with logs displayed
docker run --rm ruby-mongodb

# Run in background
docker run -d --name my-ruby-mongodb ruby-mongodb

# Run with port mapping
docker run -d -p 27017:27017 --name my-ruby-mongodb ruby-mongodb
```

## Usage

### Accessing the Container

```bash
# Execute Ruby commands
docker exec -it my-ruby-mongodb ruby --version

# Access shell
docker exec -it my-ruby-mongodb sh

# View MongoDB logs
docker exec -it my-ruby-mongodb cat /var/log/mongodb.log
```

### Services Available

- **Ruby**: Available at `/usr/local/bin/ruby`
- **MongoDB**: Running on port 27017
- **MongoDB Logs**: Available at `/var/log/mongodb.log`

## Example Usage with CQM Parsers

This image is designed to work with Ruby applications that require MongoDB, such as the CQM parsers in this repository:

```bash
# Copy your Ruby application into the container
docker run -v $(pwd):/app ruby-mongodb sh -c "cd /app && ruby script.rb"
```

## Architecture

- **Base Image**: ruby:3.2-alpine
- **User**: mongodb (for running MongoDB service)
- **Working Directory**: /app
- **Exposed Port**: 27017
- **Startup Script**: /usr/local/bin/start.sh

## Notes

- The MongoDB service is configured for development and testing purposes
- The container runs both Ruby and MongoDB services automatically
- Log files are available at `/var/log/mongodb.log`
- The image is optimized for minimal size while providing full functionality