package database

import (
	"database/sql"
	"fmt"
	"log"
	"os"
	"time"

	_ "github.com/lib/pq"
)

// PostgreSQL connection configuration
type Config struct {
	Host            string
	Port            int
	User            string
	Password        string
	DBName          string
	SSLMode         string
	MaxOpenConns    int
	MaxIdleConns    int
	ConnMaxLifetime time.Duration
}

// Default configuration
func DefaultConfig() Config {
	return Config{
		Host:            getEnv("DB_HOST", "localhost"),
		Port:            5432,
		User:            getEnv("DB_USER", "medicore"),
		Password:        getEnv("DB_PASSWORD", "medicore"),
		DBName:          getEnv("DB_NAME", "medicore_db"),
		SSLMode:         getEnv("DB_SSLMODE", "disable"),
		MaxOpenConns:    50, // Connection pool: 50 connections
		MaxIdleConns:    10, // Keep 10 idle connections
		ConnMaxLifetime: time.Hour,
	}
}

// NewPostgresConnection creates a new PostgreSQL database connection with connection pooling
func NewPostgresConnection(cfg Config) (*sql.DB, error) {
	connStr := fmt.Sprintf(
		"host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
		cfg.Host, cfg.Port, cfg.User, cfg.Password, cfg.DBName, cfg.SSLMode,
	)

	log.Printf("📊 Connecting to PostgreSQL: %s@%s:%d/%s", cfg.User, cfg.Host, cfg.Port, cfg.DBName)

	db, err := sql.Open("postgres", connStr)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	// Configure connection pool
	db.SetMaxOpenConns(cfg.MaxOpenConns)
	db.SetMaxIdleConns(cfg.MaxIdleConns)
	db.SetConnMaxLifetime(cfg.ConnMaxLifetime)

	log.Printf("🔧 Connection pool configured: max_open=%d, max_idle=%d, max_lifetime=%s",
		cfg.MaxOpenConns, cfg.MaxIdleConns, cfg.ConnMaxLifetime)

	// Test connection
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	log.Println("✅ PostgreSQL connection established successfully")

	// Verify schema version
	if err := verifySchemaVersion(db); err != nil {
		log.Printf("⚠️ Schema version check: %v", err)
	}

	return db, nil
}

// verifySchemaVersion checks if the database schema is up to date
func verifySchemaVersion(db *sql.DB) error {
	var version string
	err := db.QueryRow("SELECT value_text FROM app_metadata WHERE key = 'schema_version'").Scan(&version)
	if err != nil {
		return fmt.Errorf("could not read schema version: %w", err)
	}
	log.Printf("📋 Database schema version: %s", version)
	return nil
}

// getEnv gets environment variable with fallback
func getEnv(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}

// HealthCheck verifies database connectivity
func HealthCheck(db *sql.DB) error {
	if err := db.Ping(); err != nil {
		return fmt.Errorf("database health check failed: %w", err)
	}
	return nil
}
