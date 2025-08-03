git clone https://github.com/openemr/oe-cqm-parsers

cd oe-cqm-parsers

cp .env.sample .env

put your VSAC API key in .env like this:
`VSAC_API_KEY=Your UMLS API key`

## Local Development

bundle install

bundle exec ruby script.rb

## Docker Development

### Prerequisites
- Docker and Docker Compose installed
- VSAC API key (put in .env file)

### Quick Start with Docker

1. Copy the environment file:
```bash
cp .env.sample .env
```

2. Add your VSAC API key to .env:
```bash
VSAC_API_KEY=Your UMLS API key
```

3. Start the services:
```bash
docker compose up --build
```

This will:
- Build the Ruby 3.3.8 application container
- Start a MongoDB 7 database
- Set up networking between the services
- Mount the application code for development

### Docker Services

- **app**: Ruby 3.3.8 application running on port 3000
- **db**: MongoDB 7 database running on port 27017
- **mongodb_data**: Persistent volume for MongoDB data

### Environment Variables

- `MONGODB_URI`: Connection string for MongoDB (automatically set in Docker)
- `VSAC_API_KEY`: Your VSAC API key for measure processing

### Troubleshooting

If you encounter SSL certificate issues during Docker build, uncomment the SSL workaround lines in the Dockerfile as indicated in the comments.
