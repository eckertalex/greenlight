set dotenv-load

default:
    @just --list

# ==================================================================================== #
# HELPERS
# ==================================================================================== #

# Reusable confirmation recipe
[private]
confirm message:
    #!/usr/bin/env sh
    read -p "{{ message }} (y/n) " answer
    if [ "$answer" != "y" ]; then
        exit 1
    fi

# ==================================================================================== #
# DEVELOPMENT
# ==================================================================================== #

# Run the cmd/api application
run-api:
    go run ./cmd/api -db-dsn="{{env_var('GREENLIGHT_DB_DSN')}}" -smtp-host="{{env_var('GREENLIGHT_SMTP_HOST')}}" -smtp-username="{{env_var('GREENLIGHT_SMTP_USERNAME')}}" -smtp-password="{{env_var('GREENLIGHT_SMTP_PASSWORD')}}" -smtp-sender="{{env_var('GREENLIGHT_SMTP_SENDER')}}"

# Run the application with reloading on file changes
watch-api:
    #!/usr/bin/env sh
    if command -v air > /dev/null; then
        air --build.bin "./bin/api -db-dsn=\"{{env_var('GREENLIGHT_DB_DSN')}}\" -smtp-host=\"{{env_var('GREENLIGHT_SMTP_HOST')}}\" -smtp-username=\"{{env_var('GREENLIGHT_SMTP_USERNAME')}}\" -smtp-password=\"{{env_var('GREENLIGHT_SMTP_PASSWORD')}}\" -smtp-sender=\"{{env_var('GREENLIGHT_SMTP_SENDER')}}\""
        echo "Watching..."
    else
        echo "Go's 'air' is not installed. Please run 'go install github.com/air-verse/air@latest'"
    fi

# Connect to the database using psql
db-psql:
    psql "{{env_var('GREENLIGHT_DB_DSN')}}"

# Create a new database migration
db-migrations-new name:
    @echo "Creating migration files for {{name}}"
    migrate create -seq -ext=.sql -dir=./migrations "{{name}}"

# Apply all up database migrations
db-migrations-up: (confirm "Are you sure you want to apply all up database migrations? This action may modify your database schema.")
    @echo "Running up migrations..."
    migrate -path ./migrations -database "{{env_var('GREENLIGHT_DB_DSN')}}" up

# ==================================================================================== #
# QUALITY CONTROL
# ==================================================================================== #

# Format all .go files, and tidy and vendor module dependencies
tidy:
    @echo "Formatting .go files..."
    go fmt ./...
    @echo "Tidying module dependencies..."
    go mod tidy
    @echo "Verifying and vendoring module dependencies..."
    go mod verify
    go mod vendor

# Run quality control checks
audit:
    @echo "Checking module dependencies"
    go mod tidy -diff
    go mod verify
    @echo "Vetting code..."
    go vet ./...
    staticcheck ./...
    @echo "Running tests..."
    go test -race -vet=off ./...

# ==================================================================================== #
# BUILD
# ==================================================================================== #

# Build the cmd/api application
build-api:
    @echo "Building cmd/api..."
    go build -ldflags="-s -w" -o=./bin/api ./cmd/api
    GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o=./bin/linux_amd64/api ./cmd/api

# Clean build artifacts
clean: (confirm "Are you sure you want to clean build artifacts?")
    rm -rf bin
    @echo "Clean complete."
