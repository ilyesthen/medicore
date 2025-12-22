package database

import (
	"database/sql"
	"fmt"
	"log"
	"sort"
)

// Migration represents a database migration
type Migration struct {
	Version     int
	Description string
	Up          func(*sql.DB) error
	Down        func(*sql.DB) error
}

// MigrationManager handles database schema migrations
type MigrationManager struct {
	db         *sql.DB
	migrations []Migration
}

// NewMigrationManager creates a new migration manager
func NewMigrationManager(db *sql.DB) *MigrationManager {
	return &MigrationManager{
		db:         db,
		migrations: []Migration{},
	}
}

// RegisterMigration adds a migration to the manager
func (m *MigrationManager) RegisterMigration(migration Migration) {
	m.migrations = append(m.migrations, migration)
}

// getCurrentVersion gets the current schema version from the database
func (m *MigrationManager) getCurrentVersion() (int, error) {
	var version int
	err := m.db.QueryRow(`
		SELECT COALESCE(MAX(version), 0) 
		FROM schema_migrations
	`).Scan(&version)

	if err != nil {
		// Table doesn't exist, create it
		_, err = m.db.Exec(`
			CREATE TABLE IF NOT EXISTS schema_migrations (
				version INTEGER PRIMARY KEY,
				description TEXT NOT NULL,
				applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
			)
		`)
		if err != nil {
			return 0, fmt.Errorf("failed to create schema_migrations table: %w", err)
		}
		return 0, nil
	}

	return version, nil
}

// Up runs all pending migrations
func (m *MigrationManager) Up() error {
	currentVersion, err := m.getCurrentVersion()
	if err != nil {
		return fmt.Errorf("failed to get current version: %w", err)
	}

	// Sort migrations by version
	sort.Slice(m.migrations, func(i, j int) bool {
		return m.migrations[i].Version < m.migrations[j].Version
	})

	log.Printf("📋 Current schema version: %d", currentVersion)

	// Run pending migrations
	for _, migration := range m.migrations {
		if migration.Version <= currentVersion {
			continue
		}

		log.Printf("🔄 Running migration %d: %s", migration.Version, migration.Description)

		tx, err := m.db.Begin()
		if err != nil {
			return fmt.Errorf("failed to begin transaction: %w", err)
		}

		// Run the migration
		if err := migration.Up(m.db); err != nil {
			tx.Rollback()
			return fmt.Errorf("migration %d failed: %w", migration.Version, err)
		}

		// Record the migration
		_, err = tx.Exec(`
			INSERT INTO schema_migrations (version, description)
			VALUES ($1, $2)
		`, migration.Version, migration.Description)

		if err != nil {
			tx.Rollback()
			return fmt.Errorf("failed to record migration %d: %w", migration.Version, err)
		}

		if err := tx.Commit(); err != nil {
			return fmt.Errorf("failed to commit migration %d: %w", migration.Version, err)
		}

		log.Printf("✅ Migration %d completed", migration.Version)
	}

	log.Println("✅ All migrations completed")
	return nil
}

// Down rolls back the last migration
func (m *MigrationManager) Down() error {
	currentVersion, err := m.getCurrentVersion()
	if err != nil {
		return fmt.Errorf("failed to get current version: %w", err)
	}

	if currentVersion == 0 {
		log.Println("⚠️ No migrations to roll back")
		return nil
	}

	// Find the migration to roll back
	var targetMigration *Migration
	for i := range m.migrations {
		if m.migrations[i].Version == currentVersion {
			targetMigration = &m.migrations[i]
			break
		}
	}

	if targetMigration == nil {
		return fmt.Errorf("migration %d not found", currentVersion)
	}

	log.Printf("🔄 Rolling back migration %d: %s", targetMigration.Version, targetMigration.Description)

	tx, err := m.db.Begin()
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}

	// Run the down migration
	if err := targetMigration.Down(m.db); err != nil {
		tx.Rollback()
		return fmt.Errorf("rollback failed: %w", err)
	}

	// Remove the migration record
	_, err = tx.Exec(`
		DELETE FROM schema_migrations 
		WHERE version = $1
	`, targetMigration.Version)

	if err != nil {
		tx.Rollback()
		return fmt.Errorf("failed to remove migration record: %w", err)
	}

	if err := tx.Commit(); err != nil {
		return fmt.Errorf("failed to commit rollback: %w", err)
	}

	log.Printf("✅ Migration %d rolled back", targetMigration.Version)
	return nil
}

// Status shows the current migration status
func (m *MigrationManager) Status() error {
	currentVersion, err := m.getCurrentVersion()
	if err != nil {
		return fmt.Errorf("failed to get current version: %w", err)
	}

	log.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	log.Println("📋 Migration Status")
	log.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	log.Printf("Current version: %d", currentVersion)
	log.Printf("Available migrations: %d", len(m.migrations))

	// Sort migrations
	sort.Slice(m.migrations, func(i, j int) bool {
		return m.migrations[i].Version < m.migrations[j].Version
	})

	for _, migration := range m.migrations {
		status := "❌ Pending"
		if migration.Version <= currentVersion {
			status = "✅ Applied"
		}
		log.Printf("  %s v%d: %s", status, migration.Version, migration.Description)
	}

	log.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	return nil
}

// InitialSchema represents the initial database schema (version 1)
func InitialSchema() Migration {
	return Migration{
		Version:     1,
		Description: "Initial schema with all 18 tables",
		Up: func(db *sql.DB) error {
			// This is already applied via schema_postgresql.sql
			// This migration is for tracking purposes only
			return nil
		},
		Down: func(db *sql.DB) error {
			// Cannot roll back initial schema
			return fmt.Errorf("cannot roll back initial schema")
		},
	}
}
