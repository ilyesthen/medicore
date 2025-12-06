package models

import "time"

// User represents a user account in the system
type User struct {
	ID             string     `json:"id"`
	Name           string     `json:"name"`
	Role           string     `json:"role"`
	PasswordHash   string     `json:"password_hash"`
	Percentage     *float64   `json:"percentage,omitempty"`
	IsTemplateUser bool       `json:"is_template_user"`
	CreatedAt      time.Time  `json:"created_at"`
	UpdatedAt      time.Time  `json:"updated_at"`
	DeletedAt      *time.Time `json:"deleted_at,omitempty"`
	LastSyncedAt   *time.Time `json:"last_synced_at,omitempty"`
	SyncVersion    int32      `json:"sync_version"`
	NeedsSync      bool       `json:"needs_sync"`
}

// UserTemplate represents a user template for quick registration
type UserTemplate struct {
	ID           string     `json:"id"`
	Role         string     `json:"role"`
	PasswordHash string     `json:"password_hash"`
	Percentage   float64    `json:"percentage"`
	CreatedAt    time.Time  `json:"created_at"`
	UpdatedAt    time.Time  `json:"updated_at"`
	DeletedAt    *time.Time `json:"deleted_at,omitempty"`
	LastSyncedAt *time.Time `json:"last_synced_at,omitempty"`
	SyncVersion  int32      `json:"sync_version"`
	NeedsSync    bool       `json:"needs_sync"`
}
