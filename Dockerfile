FROM golang:1.23

WORKDIR /app

RUN go install github.com/air-verse/air@latest

# The application code will be mounted at runtime
# No need to copy files or build the application here
