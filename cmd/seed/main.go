package main

import (
	"context"
	"database/sql"
	"flag"
	"log/slog"
	"os"
	"time"

	"github.com/eckertalex/greenlight/internal/data"
	_ "github.com/lib/pq"
)

type config struct {
	dsn string
}

type application struct {
	config config
	logger *slog.Logger
	models data.Models
}

func main() {
	var cfg config

	flag.StringVar(&cfg.dsn, "database", "", "PostgreSQL DSN")

	flag.Parse()

	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))

	if cfg.dsn == "" {
		logger.Error("Usage: ./seed -database=<connection_string>")
		os.Exit(1)
	}

	db, err := openDB(cfg)
	if err != nil {
		logger.Error(err.Error())
		os.Exit(1)
	}
	defer db.Close()
	logger.Info("database connection pool established")

	app := &application{
		config: cfg,
		logger: logger,
		models: data.NewModels(db),
	}

	logger.Info("seeding users...")
	app.seedUsers()
	logger.Info("done seeding users")

	logger.Info("seeding movies...")
	app.seedMovies()
	logger.Info("done seeding movies")

	logger.Info("database seeded successfully")
}

func openDB(cfg config) (*sql.DB, error) {
	db, err := sql.Open("postgres", cfg.dsn)
	if err != nil {
		return nil, err
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	err = db.PingContext(ctx)
	if err != nil {
		db.Close()
		return nil, err
	}

	return db, nil
}
