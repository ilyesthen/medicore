package repository

import (
	"database/sql"
	"fmt"
	"time"

	"medicore-server/internal/models"
)

// TemplatesRepository handles database operations for templates
type TemplatesRepository struct {
	db *sql.DB
}

// NewTemplatesRepository creates a new templates repository
func NewTemplatesRepository(db *sql.DB) *TemplatesRepository {
	return &TemplatesRepository{db: db}
}

// GetAll retrieves all templates (excluding soft-deleted)
func (r *TemplatesRepository) GetAll() ([]*models.UserTemplate, error) {
	query := `
		SELECT id, role, password_hash, percentage, created_at, updated_at,
		       deleted_at, last_synced_at, sync_version, needs_sync
		FROM templates
		WHERE deleted_at IS NULL
		ORDER BY created_at DESC
	`

	rows, err := r.db.Query(query)
	if err != nil {
		return nil, fmt.Errorf("failed to query templates: %w", err)
	}
	defer rows.Close()

	var templates []*models.UserTemplate
	for rows.Next() {
		template := &models.UserTemplate{}
		err := rows.Scan(
			&template.ID, &template.Role, &template.PasswordHash,
			&template.Percentage, &template.CreatedAt, &template.UpdatedAt,
			&template.DeletedAt, &template.LastSyncedAt, &template.SyncVersion,
			&template.NeedsSync,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan template: %w", err)
		}
		templates = append(templates, template)
	}

	return templates, nil
}

// GetByID retrieves a template by ID
func (r *TemplatesRepository) GetByID(id string) (*models.UserTemplate, error) {
	query := `
		SELECT id, role, password_hash, percentage, created_at, updated_at,
		       deleted_at, last_synced_at, sync_version, needs_sync
		FROM templates
		WHERE id = $1 AND deleted_at IS NULL
	`

	template := &models.UserTemplate{}
	err := r.db.QueryRow(query, id).Scan(
		&template.ID, &template.Role, &template.PasswordHash,
		&template.Percentage, &template.CreatedAt, &template.UpdatedAt,
		&template.DeletedAt, &template.LastSyncedAt, &template.SyncVersion,
		&template.NeedsSync,
	)

	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("failed to get template: %w", err)
	}

	return template, nil
}

// Create creates a new template
func (r *TemplatesRepository) Create(template *models.UserTemplate) error {
	query := `
		INSERT INTO templates (
			id, role, password_hash, percentage,
			created_at, updated_at, sync_version, needs_sync
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING id, created_at, updated_at
	`

	err := r.db.QueryRow(
		query,
		template.ID, template.Role, template.PasswordHash,
		template.Percentage, template.CreatedAt, template.UpdatedAt,
		template.SyncVersion, template.NeedsSync,
	).Scan(&template.ID, &template.CreatedAt, &template.UpdatedAt)

	if err != nil {
		return fmt.Errorf("failed to create template: %w", err)
	}

	return nil
}

// Update updates an existing template
func (r *TemplatesRepository) Update(template *models.UserTemplate) error {
	query := `
		UPDATE templates SET
			role = $2,
			password_hash = $3,
			percentage = $4,
			sync_version = $5,
			needs_sync = $6
		WHERE id = $1 AND deleted_at IS NULL
		RETURNING updated_at
	`

	err := r.db.QueryRow(
		query,
		template.ID, template.Role, template.PasswordHash,
		template.Percentage, template.SyncVersion, template.NeedsSync,
	).Scan(&template.UpdatedAt)

	if err == sql.ErrNoRows {
		return fmt.Errorf("template not found")
	}
	if err != nil {
		return fmt.Errorf("failed to update template: %w", err)
	}

	return nil
}

// Delete soft deletes a template
func (r *TemplatesRepository) Delete(id string) error {
	query := `
		UPDATE templates SET
			deleted_at = $2,
			needs_sync = TRUE
		WHERE id = $1 AND deleted_at IS NULL
	`

	result, err := r.db.Exec(query, id, time.Now())
	if err != nil {
		return fmt.Errorf("failed to delete template: %w", err)
	}

	rows, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rows == 0 {
		return fmt.Errorf("template not found")
	}

	return nil
}

// GetUpdatedSince retrieves templates updated since a timestamp
func (r *TemplatesRepository) GetUpdatedSince(timestamp time.Time) ([]*models.UserTemplate, error) {
	query := `
		SELECT id, role, password_hash, percentage, created_at, updated_at,
		       deleted_at, last_synced_at, sync_version, needs_sync
		FROM templates
		WHERE updated_at > $1 OR needs_sync = TRUE
		ORDER BY updated_at DESC
	`

	rows, err := r.db.Query(query, timestamp)
	if err != nil {
		return nil, fmt.Errorf("failed to query updated templates: %w", err)
	}
	defer rows.Close()

	var templates []*models.UserTemplate
	for rows.Next() {
		template := &models.UserTemplate{}
		err := rows.Scan(
			&template.ID, &template.Role, &template.PasswordHash,
			&template.Percentage, &template.CreatedAt, &template.UpdatedAt,
			&template.DeletedAt, &template.LastSyncedAt, &template.SyncVersion,
			&template.NeedsSync,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan template: %w", err)
		}
		templates = append(templates, template)
	}

	return templates, nil
}

// MarkAsSynced marks a template as synced
func (r *TemplatesRepository) MarkAsSynced(id string, syncTime time.Time) error {
	query := `
		UPDATE templates SET
			last_synced_at = $2,
			needs_sync = FALSE
		WHERE id = $1
	`

	_, err := r.db.Exec(query, id, syncTime)
	if err != nil {
		return fmt.Errorf("failed to mark template as synced: %w", err)
	}

	return nil
}
