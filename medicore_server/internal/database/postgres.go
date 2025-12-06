package database

import (
	"database/sql"
	"fmt"

	_ "github.com/lib/pq"
)

// PostgreSQL connection configuration
type Config struct {
	Host     string
	Port     int
	User     string
	Password string
	DBName   string
	SSLMode  string
}

// Default configuration
func DefaultConfig() Config {
	return Config{
		Host:     "localhost",
		Port:     5432,
		User:     "medicore",
		Password: "medicore",
		DBName:   "medicore_db",
		SSLMode:  "disable",
	}
}

// NewPostgresConnection creates a new PostgreSQL database connection
func NewPostgresConnection(cfg Config) (*sql.DB, error) {
	connStr := fmt.Sprintf(
		"host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
		cfg.Host, cfg.Port, cfg.User, cfg.Password, cfg.DBName, cfg.SSLMode,
	)

	db, err := sql.Open("postgres", connStr)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	// Test connection
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	return db, nil
}
