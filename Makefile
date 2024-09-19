include .env

# ==================================================================================== #
# HELPERS
# ==================================================================================== #

## help: print this help message
.PHONY: help
help:
	@echo "Usage:"
	@sed -n "s/^##//p" ${MAKEFILE_LIST} | column -t -s ":" |  sed -e "s/^/ /"

.PHONY: confirm
confirm:
	@echo "$(message) (y/n) \c"
	@read answer; \
	if [ "$$answer" != "y" ]; then \
		echo "Aborting."; \
		exit 1; \
	fi

# ==================================================================================== #
# DEVELOPMENT
# ==================================================================================== #

## run/api: run the cmd/api application
.PHONY: run/api
run/api:
	go run ./cmd/api -db-dsn=${GREENLIGHT_DB_DSN} \
		-smtp-host=${GREENLIGHT_SMTP_HOST} \
		-smtp-username=${GREENLIGHT_SMTP_USERNAME} \
		-smtp-password=${GREENLIGHT_SMTP_PASSWORD} \
		-smtp-sender=${GREENLIGHT_SMTP_SENDER}

## watch: run the application with reloading on file changes
.PHONY: watch/api
watch/api:
	@if command -v air > /dev/null; then \
		air \
			--build.cmd "go build -o=./bin/api ./cmd/api" \
			--build.bin "./bin/api -db-dsn=${GREENLIGHT_DB_DSN} \
				-smtp-host=${GREENLIGHT_SMTP_HOST} \
				-smtp-username=${GREENLIGHT_SMTP_USERNAME} \
				-smtp-password=${GREENLIGHT_SMTP_PASSWORD} \
				-smtp-sender=${GREENLIGHT_SMTP_SENDER}"; \
		echo "Watching..."; \
	else \
		echo "Go's 'air' is not installed. Please run 'go install github.com/air-verse/air@latest'";\
	fi

## db/psql: connect to the database using psql
.PHONY: db/psql
db/psql:
	psql ${GREENLIGHT_DB_DSN}

## db/migrations/new name=$1: create a new database migration
.PHONY: db/migrations/new
db/migrations/new:
	@echo "Creating migration files for ${name}"
	migrate create -seq -ext=.sql -dir=./migrations ${name}

## db/migrations/up: apply all up database migrations
.PHONY: db/migrations/up
db/migrations/up: message := Are you sure you want to apply all up database migrations? This action may modify your database schema.
db/migrations/up: confirm
	@echo "Running up migrations..."
	migrate -path ./migrations -database ${GREENLIGHT_DB_DSN} up

# ==================================================================================== #
# QUALITY CONTROL
# ==================================================================================== #

## tidy: format all .go files, and tidy and vendor module dependencies
.PHONY: tidy
tidy:
	@echo "Formatting .go files..."
	go fmt ./...
	@echo "Tidying module dependencies..."
	go mod tidy
	@echo "Verifying and vendoring module dependencies..."
	go mod verify
	go mod vendor

## audit: run quality control checks
.PHONY: audit
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

## build/api: build the cmd/api application
.PHONY: build/api
build/api:
	@echo "Building cmd/api..."
	go build -ldflags="-s -w" -o=./bin/api ./cmd/api
	GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o=./bin/linux_amd64/api ./cmd/api
	
## clean: Clean build artifacts
.PHONY: clean
clean: message := Are you sure you want to clean build artifacts?
clean: confirm
	rm -rf bin
