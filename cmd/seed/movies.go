package main

import (
	"github.com/eckertalex/greenlight/internal/data"
)

type movie struct {
	Title   string
	Year    int32
	Runtime int32
	Genres  []string
}

func (app *application) seedMovies() {
	movies := []movie{
		{
			Title:   "The Lord of the Rings: The Fellowship of the Ring",
			Year:    2001,
			Runtime: 178,
			Genres:  []string{"Adventure", "Fantasy", "Action"},
		},
		{
			Title:   "The Lord of the Rings: The Two Towers",
			Year:    2002,
			Runtime: 179,
			Genres:  []string{"Adventure", "Fantasy", "Action"},
		},
		{
			Title:   "The Lord of the Rings: The Return of the King",
			Year:    2003,
			Runtime: 201,
			Genres:  []string{"Adventure", "Fantasy", "Action"},
		},
		{
			Title:   "Inception",
			Year:    2010,
			Runtime: 148,
			Genres:  []string{"Action", "Sci-Fi", "Thriller"},
		},
		{
			Title:   "The Shawshank Redemption",
			Year:    1994,
			Runtime: 142,
			Genres:  []string{"Drama"},
		},
		{
			Title:   "Pulp Fiction",
			Year:    1994,
			Runtime: 154,
			Genres:  []string{"Crime", "Drama"},
		},
		{
			Title:   "The Dark Knight",
			Year:    2008,
			Runtime: 152,
			Genres:  []string{"Action", "Crime", "Drama"},
		},
		{
			Title:   "Forrest Gump",
			Year:    1994,
			Runtime: 142,
			Genres:  []string{"Drama", "Romance"},
		},
		{
			Title:   "The Matrix",
			Year:    1999,
			Runtime: 136,
			Genres:  []string{"Action", "Sci-Fi"},
		},
		{
			Title:   "Goodfellas",
			Year:    1990,
			Runtime: 146,
			Genres:  []string{"Biography", "Crime", "Drama"},
		},
	}

	for _, movie := range movies {
		app.seedMovie(&movie)
	}
}

func (app *application) seedMovie(movie *movie) {
	domainMovie := &data.Movie{
		Title:   movie.Title,
		Year:    movie.Year,
		Runtime: data.Runtime(movie.Runtime),
		Genres:  movie.Genres,
	}

	err := app.models.Movies.Insert(domainMovie)
	if err != nil {
		app.logger.Error(err.Error(), "error inserting movie", domainMovie.Title)
		return
	}

	app.logger.Info("successfully seeded movie", "title", domainMovie.Title)
}
