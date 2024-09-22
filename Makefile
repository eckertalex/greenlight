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
	@go run ./cmd/api \
		-db-database=${GREENLIGHT_DB_DATABASE} \
		-db-password=${GREENLIGHT_DB_PASSWORD} \
		-db-username=${GREENLIGHT_DB_USERNAME} \
		-db-port=${GREENLIGHT_DB_PORT} \
		-db-host=${GREENLIGHT_DB_HOST} \
		-db-schema=${GREENLIGHT_DB_SCHEMA} \
		-smtp-host=${GREENLIGHT_SMTP_HOST} \
		-smtp-username=${GREENLIGHT_SMTP_USERNAME} \
		-smtp-password=${GREENLIGHT_SMTP_PASSWORD} \
		-smtp-sender=${GREENLIGHT_SMTP_SENDER}

## watch: run the application with reloading on file changes
.PHONY: watch/api
watch/api:
	@air --build.cmd "go build -o=./tmp/api ./cmd/api" \
		--build.bin "./tmp/api \
			-db-database=${GREENLIGHT_DB_DATABASE} \
			-db-password=${GREENLIGHT_DB_PASSWORD} \
			-db-username=${GREENLIGHT_DB_USERNAME} \
			-db-port=${GREENLIGHT_DB_PORT} \
			-db-host=${GREENLIGHT_DB_HOST} \
			-db-schema=${GREENLIGHT_DB_SCHEMA} \
			-smtp-host=${GREENLIGHT_SMTP_HOST} \
			-smtp-username=${GREENLIGHT_SMTP_USERNAME} \
			-smtp-password=${GREENLIGHT_SMTP_PASSWORD} \
			-smtp-sender=${GREENLIGHT_SMTP_SENDER}"

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
	go build -ldflags="-s -w" -o=./tmp/api ./cmd/api
	
## build/seed: build the cmd/seed application
.PHONY: build/seed
build/seed:
	@echo "Building cmd/seed..."
	go build -ldflags="-s -w" -o=./tmp/seed ./cmd/seed
	
## clean: Clean build artifacts
.PHONY: clean
clean: message := Are you sure you want to clean build artifacts?
clean: confirm
	rm -rf tmp
	
# ==================================================================================== #
# DOCKER
# ==================================================================================== #

## docker/up: Create and run the docker cluster
.PHONY: docker/up
docker/up:
	docker compose up --detach

## docker/logs: Follow docker logs
.PHONY: docker/logs
docker/logs:
	docker compose logs --follow

## docker/down: Shutdown the docker cluster
.PHONY: docker/down
docker/down:
	docker compose down

## docker/destroy: Destroy docker cluster
.PHONY: docker/destroy
docker/destroy: message := Are you sure you want to destroy the docker cluster? This action is not reversible.
docker/destroy: confirm
	docker compose down --remove-orphans --rmi all --volumes

# ==================================================================================== #
# DB
# ==================================================================================== #

## db/psql: connect to the database using psql
.PHONY: db/psql
db/psql:
	@docker compose exec db psql -U ${GREENLIGHT_DB_USERNAME} -d ${GREENLIGHT_DB_DATABASE}

## db/seed: seed database
.PHONY: db/seed
db/seed: message := Are you sure you want to seed the database? This action may modify your database data.
db/seed: confirm
	@docker build -t greenlight-seed -f Dockerfile.seed .
	@docker run --rm --network greenlight_default greenlight-seed -database "postgres://${GREENLIGHT_DB_USERNAME}:${GREENLIGHT_DB_PASSWORD}@${GREENLIGHT_DB_HOST}:${GREENLIGHT_DB_PORT}/${GREENLIGHT_DB_DATABASE}?sslmode=disable&search_path=${GREENLIGHT_DB_SCHEMA}"

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
	@docker run --rm -v ./migrations:/migrations --network greenlight_default migrate/migrate -path=/migrations/ -database "postgres://${GREENLIGHT_DB_USERNAME}:${GREENLIGHT_DB_PASSWORD}@${GREENLIGHT_DB_HOST}:${GREENLIGHT_DB_PORT}/${GREENLIGHT_DB_DATABASE}?sslmode=disable&search_path=${GREENLIGHT_DB_SCHEMA}" up

## db/migrations/down: apply all up database migrations
.PHONY: db/migrations/down
db/migrations/down: message := Are you sure you want to apply all up database migrations? This action may modify your database schema.
db/migrations/down: confirm
	@echo "Running down migrations..."
	@docker run --rm -v ./migrations:/migrations --network greenlight_default migrate/migrate -path=/migrations/ -database "postgres://${GREENLIGHT_DB_USERNAME}:${GREENLIGHT_DB_PASSWORD}@${GREENLIGHT_DB_HOST}:${GREENLIGHT_DB_PORT}/${GREENLIGHT_DB_DATABASE}?sslmode=disable&search_path=${GREENLIGHT_DB_SCHEMA}" down

## db/migrations/goto version=$1: migrate to  specific version number
.PHONY: db/migrations/goto
db/migrations/goto: message := Are you sure you want to apply this database migration? This action may modify your database schema.
db/migrations/goto: confirm
	@docker run --rm -v ./migrations:/migrations --network greenlight_default migrate/migrate -path=/migrations/ -database "postgres://${GREENLIGHT_DB_USERNAME}:${GREENLIGHT_DB_PASSWORD}@${GREENLIGHT_DB_HOST}:${GREENLIGHT_DB_PORT}/${GREENLIGHT_DB_DATABASE}?sslmode=disable&search_path=${GREENLIGHT_DB_SCHEMA}" goto ${version}

## db/migrations/force version=$1: force database migration
.PHONY: db/migrations/force
db/migrations/force: message := Are you sure you want to apply this database migration? This action may modify your database schema.
db/migrations/force: confirm
	@docker run --rm -v ./migrations:/migrations --network greenlight_default migrate/migrate -path=/migrations/ -database "postgres://${GREENLIGHT_DB_USERNAME}:${GREENLIGHT_DB_PASSWORD}@${GREENLIGHT_DB_HOST}:${GREENLIGHT_DB_PORT}/${GREENLIGHT_DB_DATABASE}?sslmode=disable&search_path=${GREENLIGHT_DB_SCHEMA}" force ${version}

## db/migrations/version: print the current in-use migration version
.PHONY: db/migrations/version
db/migrations/version:
	@docker run --rm -v ./migrations:/migrations --network greenlight_default migrate/migrate -path=/migrations/ -database "postgres://${GREENLIGHT_DB_USERNAME}:${GREENLIGHT_DB_PASSWORD}@${GREENLIGHT_DB_HOST}:${GREENLIGHT_DB_PORT}/${GREENLIGHT_DB_DATABASE}?sslmode=disable&search_path=${GREENLIGHT_DB_SCHEMA}" version

# vim: set tabstop=4 shiftwidth=4 noexpandtab
