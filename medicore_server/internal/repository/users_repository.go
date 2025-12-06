package repository

import (
	"database/sql"
	"fmt"
	"time"

	"medicore/internal/models"
)

// UsersRepository handles database operations for users
type UsersRepository struct {
	db *sql.DB
}

// NewUsersRepository creates a new users repository
func NewUsersRepository(db *sql.DB) *UsersRepository {
	return &UsersRepository{db: db}
}

// GetAll retrieves all users (excluding soft-deleted)
func (r *UsersRepository) GetAll() ([]*models.User, error) {
	query := `
		SELECT id, name, role, password_hash, percentage, is_template_user,
		       created_at, updated_at, deleted_at, last_synced_at, sync_version, needs_sync
		FROM users
		WHERE deleted_at IS NULL
		ORDER BY created_at DESC
	`

	rows, err := r.db.Query(query)
	if err != nil {
		return nil, fmt.Errorf("failed to query users: %w", err)
	}
	defer rows.Close()

	var users []*models.User
	for rows.Next() {
		user := &models.User{}
		err := rows.Scan(
			&user.ID, &user.Name, &user.Role, &user.PasswordHash,
			&user.Percentage, &user.IsTemplateUser, &user.CreatedAt,
			&user.UpdatedAt, &user.DeletedAt, &user.LastSyncedAt,
			&user.SyncVersion, &user.NeedsSync,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan user: %w", err)
		}
		users = append(users, user)
	}

	return users, nil
}

// GetByID retrieves a user by ID
func (r *UsersRepository) GetByID(id string) (*models.User, error) {
	query := `
		SELECT id, name, role, password_hash, percentage, is_template_user,
		       created_at, updated_at, deleted_at, last_synced_at, sync_version, needs_sync
		FROM users
		WHERE id = $1 AND deleted_at IS NULL
	`

	user := &models.User{}
	err := r.db.QueryRow(query, id).Scan(
		&user.ID, &user.Name, &user.Role, &user.PasswordHash,
		&user.Percentage, &user.IsTemplateUser, &user.CreatedAt,
		&user.UpdatedAt, &user.DeletedAt, &user.LastSyncedAt,
		&user.SyncVersion, &user.NeedsSync,
	)

	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	return user, nil
}

// Create creates a new user
func (r *UsersRepository) Create(user *models.User) error {
	query := `
		INSERT INTO users (
			id, name, role, password_hash, percentage, is_template_user,
			created_at, updated_at, sync_version, needs_sync
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
		RETURNING id, created_at, updated_at
	`

	err := r.db.QueryRow(
		query,
		user.ID, user.Name, user.Role, user.PasswordHash,
		user.Percentage, user.IsTemplateUser, user.CreatedAt,
		user.UpdatedAt, user.SyncVersion, user.NeedsSync,
	).Scan(&user.ID, &user.CreatedAt, &user.UpdatedAt)

	if err != nil {
		return fmt.Errorf("failed to create user: %w", err)
	}

	return nil
}

// Update updates an existing user
func (r *UsersRepository) Update(user *models.User) error {
	query := `
		UPDATE users SET
			name = $2,
			role = $3,
			password_hash = $4,
			percentage = $5,
			is_template_user = $6,
			sync_version = $7,
			needs_sync = $8
		WHERE id = $1 AND deleted_at IS NULL
		RETURNING updated_at
	`

	err := r.db.QueryRow(
		query,
		user.ID, user.Name, user.Role, user.PasswordHash,
		user.Percentage, user.IsTemplateUser, user.SyncVersion,
		user.NeedsSync,
	).Scan(&user.UpdatedAt)

	if err == sql.ErrNoRows {
		return fmt.Errorf("user not found")
	}
	if err != nil {
		return fmt.Errorf("failed to update user: %w", err)
	}

	return nil
}

// Delete soft deletes a user
func (r *UsersRepository) Delete(id string) error {
	query := `
		UPDATE users SET
			deleted_at = $2,
			needs_sync = TRUE
		WHERE id = $1 AND deleted_at IS NULL
	`

	result, err := r.db.Exec(query, id, time.Now())
	if err != nil {
		return fmt.Errorf("failed to delete user: %w", err)
	}

	rows, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rows == 0 {
		return fmt.Errorf("user not found")
	}

	return nil
}

// GetUpdatedSince retrieves users updated since a timestamp
func (r *UsersRepository) GetUpdatedSince(timestamp time.Time) ([]*models.User, error) {
	query := `
		SELECT id, name, role, password_hash, percentage, is_template_user,
		       created_at, updated_at, deleted_at, last_synced_at, sync_version, needs_sync
		FROM users
		WHERE updated_at > $1 OR needs_sync = TRUE
		ORDER BY updated_at DESC
	`

	rows, err := r.db.Query(query, timestamp)
	if err != nil {
		return nil, fmt.Errorf("failed to query updated users: %w", err)
	}
	defer rows.Close()

	var users []*models.User
	for rows.Next() {
		user := &models.User{}
		err := rows.Scan(
			&user.ID, &user.Name, &user.Role, &user.PasswordHash,
			&user.Percentage, &user.IsTemplateUser, &user.CreatedAt,
			&user.UpdatedAt, &user.DeletedAt, &user.LastSyncedAt,
			&user.SyncVersion, &user.NeedsSync,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan user: %w", err)
		}
		users = append(users, user)
	}

	return users, nil
}

// MarkAsSynced marks a user as synced
func (r *UsersRepository) MarkAsSynced(id string, syncTime time.Time) error {
	query := `
		UPDATE users SET
			last_synced_at = $2,
			needs_sync = FALSE
		WHERE id = $1
	`

	_, err := r.db.Exec(query, id, syncTime)
	if err != nil {
		return fmt.Errorf("failed to mark user as synced: %w", err)
	}

	return nil
}
