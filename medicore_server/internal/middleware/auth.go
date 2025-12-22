package middleware

import (
	"context"
	"crypto/rand"
	"encoding/base64"
	"fmt"
	"net/http"
	"strings"
	"time"

	"database/sql"
)

// ContextKey is a custom type for context keys
type ContextKey string

const (
	// UserIDKey is the context key for user ID
	UserIDKey ContextKey = "user_id"
	// UserRoleKey is the context key for user role
	UserRoleKey ContextKey = "user_role"
)

// AuthMiddleware provides JWT-like authentication
type AuthMiddleware struct {
	db *sql.DB
}

// NewAuthMiddleware creates a new auth middleware
func NewAuthMiddleware(db *sql.DB) *AuthMiddleware {
	return &AuthMiddleware{db: db}
}

// GenerateToken generates a secure session token
func GenerateToken() (string, error) {
	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return base64.URLEncoding.EncodeToString(b), nil
}

// CreateSession creates a new session for a user
func (a *AuthMiddleware) CreateSession(userID, ipAddress, userAgent string) (string, error) {
	token, err := GenerateToken()
	if err != nil {
		return "", fmt.Errorf("failed to generate token: %w", err)
	}

	expiresAt := time.Now().Add(24 * time.Hour) // 24 hour session

	_, err = a.db.Exec(`
		INSERT INTO sessions (user_id, token, ip_address, user_agent, expires_at)
		VALUES ($1, $2, $3, $4, $5)
	`, userID, token, ipAddress, userAgent, expiresAt)

	if err != nil {
		return "", fmt.Errorf("failed to create session: %w", err)
	}

	return token, nil
}

// ValidateSession validates a session token
func (a *AuthMiddleware) ValidateSession(token string) (userID, userRole string, err error) {
	var expiresAt time.Time

	err = a.db.QueryRow(`
		SELECT s.user_id, u.role, s.expires_at
		FROM sessions s
		JOIN users u ON s.user_id = u.id
		WHERE s.token = $1 AND s.expires_at > NOW()
	`, token).Scan(&userID, &userRole, &expiresAt)

	if err != nil {
		if err == sql.ErrNoRows {
			return "", "", fmt.Errorf("invalid or expired session")
		}
		return "", "", fmt.Errorf("session validation failed: %w", err)
	}

	// Update last activity
	_, err = a.db.Exec(`
		UPDATE sessions 
		SET last_activity = NOW() 
		WHERE token = $1
	`, token)

	return userID, userRole, nil
}

// DeleteSession deletes a session (logout)
func (a *AuthMiddleware) DeleteSession(token string) error {
	_, err := a.db.Exec(`
		DELETE FROM sessions WHERE token = $1
	`, token)
	return err
}

// CleanupExpiredSessions removes expired sessions
func (a *AuthMiddleware) CleanupExpiredSessions() error {
	result, err := a.db.Exec(`
		DELETE FROM sessions WHERE expires_at < NOW()
	`)
	if err != nil {
		return err
	}

	rows, _ := result.RowsAffected()
	if rows > 0 {
		fmt.Printf("🧹 Cleaned up %d expired sessions\n", rows)
	}

	return nil
}

// Middleware is the HTTP middleware for authentication
func (a *AuthMiddleware) Middleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Skip auth for certain endpoints
		if a.shouldSkipAuth(r.URL.Path) {
			next.ServeHTTP(w, r)
			return
		}

		// Get token from Authorization header
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			http.Error(w, "Missing authorization header", http.StatusUnauthorized)
			return
		}

		// Extract token (format: "Bearer <token>")
		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			http.Error(w, "Invalid authorization header format", http.StatusUnauthorized)
			return
		}

		token := parts[1]

		// Validate token
		userID, userRole, err := a.ValidateSession(token)
		if err != nil {
			http.Error(w, "Invalid or expired token", http.StatusUnauthorized)
			return
		}

		// Add user info to context
		ctx := context.WithValue(r.Context(), UserIDKey, userID)
		ctx = context.WithValue(ctx, UserRoleKey, userRole)

		// Continue with authenticated request
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// shouldSkipAuth determines if a path should skip authentication
func (a *AuthMiddleware) shouldSkipAuth(path string) bool {
	skipPaths := []string{
		"/api/auth/login",
		"/api/health",
		"/api/events/status",
		"/api/ping",
	}

	for _, skipPath := range skipPaths {
		if strings.HasPrefix(path, skipPath) {
			return true
		}
	}

	return false
}

// GetUserID extracts user ID from request context
func GetUserID(r *http.Request) string {
	if userID, ok := r.Context().Value(UserIDKey).(string); ok {
		return userID
	}
	return ""
}

// GetUserRole extracts user role from request context
func GetUserRole(r *http.Request) string {
	if role, ok := r.Context().Value(UserRoleKey).(string); ok {
		return role
	}
	return ""
}

// RequireRole middleware to check user role
func RequireRole(allowedRoles ...string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			userRole := GetUserRole(r)

			allowed := false
			for _, role := range allowedRoles {
				if userRole == role {
					allowed = true
					break
				}
			}

			if !allowed {
				http.Error(w, "Forbidden: insufficient permissions", http.StatusForbidden)
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}
