package storage

import (
	"database/sql"
	"fmt"
	"nexusvpn/core/config"

	_ "modernc.org/sqlite"
)

type Database struct {
	db *sql.DB
}

// Connect opens SQLite database and runs migrations
func Connect(path string) (*Database, error) {
	db, err := sql.Open("sqlite", path)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	// Test connection
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	// Run migrations
	if err := runMigrations(db); err != nil {
		return nil, fmt.Errorf("failed to run migrations: %w", err)
	}

	return &Database{db: db}, nil
}

func runMigrations(db *sql.DB) error {
	query := `
	CREATE TABLE IF NOT EXISTS profiles (
		id TEXT PRIMARY KEY,
		name TEXT NOT NULL,
		protocol TEXT NOT NULL,
		payload TEXT NOT NULL,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);`
	
	_, err := db.Exec(query)
	return err
}

// SaveProfile inserts or updates a profile
func (d *Database) SaveProfile(p config.Profile) error {
	query := `INSERT OR REPLACE INTO profiles (id, name, protocol, payload) VALUES (?, ?, ?, ?)`
	_, err := d.db.Exec(query, p.ID, p.Name, p.Endpoint.Protocol, p.Endpoint.Payload)
	return err
}

// GetProfile retrieves a profile by ID
func (d *Database) GetProfile(id string) (config.Profile, error) {
	query := `SELECT name, protocol, payload FROM profiles WHERE id = ?`
	row := d.db.QueryRow(query, id)

	var name, protocol, payload string
	err := row.Scan(&name, &protocol, &payload)
	if err == sql.ErrNoRows {
		return config.Profile{}, fmt.Errorf("profile not found: %s", id)
	}
	if err != nil {
		return config.Profile{}, err
	}

	return config.Profile{
		ID:   id,
		Name: name,
		Endpoint: config.Endpoint{
			Protocol: protocol,
			Payload:  payload,
		},
	}, nil
}

// ListProfiles returns all profiles
func (d *Database) ListProfiles() ([]config.Profile, error) {
	query := `SELECT id, name, protocol, payload FROM profiles ORDER BY created_at DESC`
	rows, err := d.db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var profiles []config.Profile
	for rows.Next() {
		var id, name, protocol, payload string
		if err := rows.Scan(&id, &name, &protocol, &payload); err != nil {
			return nil, err
		}
		profiles = append(profiles, config.Profile{
			ID:   id,
			Name: name,
			Endpoint: config.Endpoint{
				Protocol: protocol,
				Payload:  payload,
			},
		})
	}
	return profiles, rows.Err()
}

// DeleteProfile removes a profile by ID
func (d *Database) DeleteProfile(id string) error {
	query := `DELETE FROM profiles WHERE id = ?`
	_, err := d.db.Exec(query, id)
	return err
}

// Close closes the database connection
func (d *Database) Close() error {
	return d.db.Close()
}
