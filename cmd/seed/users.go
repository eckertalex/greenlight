package main

import (
	"errors"

	"github.com/eckertalex/greenlight/internal/data"
)

type user struct {
	Name        string
	Email       string
	Password    string
	Activated   bool
	Permissions data.Permissions
}

func (app *application) seedUsers() {
	admin := user{
		Name:        "Admin User",
		Email:       "admin@greenlight.go",
		Password:    "admin123",
		Activated:   true,
		Permissions: data.Permissions{"movies:read", "movies:write"},
	}

	app.logger.Info("seeding admin user...")
	app.seedUser(&admin)
	app.logger.Info("done seeding admin user")

	activatedUser := user{
		Name:        "Activated User",
		Email:       "activated@greenlight.go",
		Password:    "activated123",
		Activated:   true,
		Permissions: data.Permissions{"movies:read"},
	}

	app.logger.Info("seeding activated user...")
	app.seedUser(&activatedUser)
	app.logger.Info("done seeding activated user")

	unactivatedUser := user{
		Name:        "Unactivated User",
		Email:       "unactivated@greenlight.go",
		Password:    "unactivated123",
		Activated:   false,
		Permissions: data.Permissions{"movies:read"},
	}

	app.logger.Info("seeding unactivated user...")
	app.seedUser(&unactivatedUser)
	app.logger.Info("done seeding unactivated user")
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
			app.logger.Error(err.Error(), "error inserting user", domainUser.Email)
		}
		return
	}

	err = app.models.Permissions.AddForUser(domainUser.ID, user.Permissions...)
	if err != nil {
		app.logger.Error(err.Error(), "failed to add permissions for user", domainUser.Email)
		return
	}

	app.logger.Info("successfully seeded user", "email", domainUser.Email)
}
