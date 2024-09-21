package main

import (
	"errors"

	"github.com/eckertalex/greenlight/internal/data"
)

type user struct {
	Name     string
	Email    string
	Password string
}

func (app *application) seedUsers() {
	users := []user{
		{
			Name:     "Admin",
			Email:    "admin@greenlight.go",
			Password: "admin123",
		},
		{
			Name:     "Alice",
			Email:    "alice@example.com",
			Password: "alice123",
		},
		{
			Name:     "Bob",
			Email:    "bob@example.com",
			Password: "bob123",
		},
		{
			Name:     "Charlie",
			Email:    "charlie@example.com",
			Password: "charlie123",
		},
	}

	for _, user := range users {
		app.seedUser(&user)
	}
}

func (app *application) seedUser(user *user) {
	domainUser := &data.User{
		Name:      user.Name,
		Email:     user.Email,
		Activated: true,
	}

	err := domainUser.Password.Set(user.Password)
	if err != nil {
		app.logger.Error(err.Error(), "failed to set password for user", domainUser.Email)
		return
	}

	err = app.models.Users.Insert(domainUser)
	if err != nil {
		switch {
		case errors.Is(err, data.ErrDuplicateEmail):
			app.logger.Error(err.Error(), "a user with this email address already exists", domainUser.Email)
		default:
			app.logger.Error(err.Error(), "unknown error when inserting user", domainUser.Email)
		}
		return
	}

	err = app.models.Permissions.AddForUser(domainUser.ID, "movies:read")
	if err != nil {
		app.logger.Error(err.Error(), "failed to add permissions for user", domainUser.Email)
		return
	}

	app.logger.Info("successfully seeded user", "email", domainUser.Email)
}
