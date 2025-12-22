package services

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"time"
)

// BackupService handles automated PostgreSQL backups
type BackupService struct {
	backupDir  string
	dbHost     string
	dbPort     int
	dbUser     string
	dbName     string
	dbPassword string
	retention  int // Number of days to keep backups
}

// NewBackupService creates a new backup service
func NewBackupService(backupDir, dbHost string, dbPort int, dbUser, dbPassword, dbName string, retention int) (*BackupService, error) {
	// Create backup directory if it doesn't exist
	if err := os.MkdirAll(backupDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create backup directory: %w", err)
	}

	return &BackupService{
		backupDir:  backupDir,
		dbHost:     dbHost,
		dbPort:     dbPort,
		dbUser:     dbUser,
		dbName:     dbName,
		dbPassword: dbPassword,
		retention:  retention,
	}, nil
}

// CreateBackup creates a PostgreSQL backup
func (bs *BackupService) CreateBackup() (string, error) {
	timestamp := time.Now().Format("20060102_150405")
	filename := fmt.Sprintf("medicore_backup_%s.sql.gz", timestamp)
	backupPath := filepath.Join(bs.backupDir, filename)

	log.Printf("📦 Creating backup: %s", filename)

	// Set PGPASSWORD environment variable
	env := os.Environ()
	env = append(env, fmt.Sprintf("PGPASSWORD=%s", bs.dbPassword))

	// Create pg_dump command
	cmd := exec.Command(
		"pg_dump",
		"-h", bs.dbHost,
		"-p", fmt.Sprintf("%d", bs.dbPort),
		"-U", bs.dbUser,
		"-d", bs.dbName,
		"-F", "p", // Plain text format
		"--no-owner",
		"--no-acl",
	)

	cmd.Env = env

	// Create gzip command
	gzipCmd := exec.Command("gzip")

	// Create output file
	outFile, err := os.Create(backupPath)
	if err != nil {
		return "", fmt.Errorf("failed to create backup file: %w", err)
	}
	defer outFile.Close()

	// Pipe pg_dump output to gzip, then to file
	pipe, err := cmd.StdoutPipe()
	if err != nil {
		return "", fmt.Errorf("failed to create pipe: %w", err)
	}

	gzipCmd.Stdin = pipe
	gzipCmd.Stdout = outFile

	// Start both commands
	if err := cmd.Start(); err != nil {
		return "", fmt.Errorf("failed to start pg_dump: %w", err)
	}

	if err := gzipCmd.Start(); err != nil {
		return "", fmt.Errorf("failed to start gzip: %w", err)
	}

	// Wait for commands to finish
	if err := cmd.Wait(); err != nil {
		return "", fmt.Errorf("pg_dump failed: %w", err)
	}

	if err := gzipCmd.Wait(); err != nil {
		return "", fmt.Errorf("gzip failed: %w", err)
	}

	// Get file size
	info, err := os.Stat(backupPath)
	if err != nil {
		return "", fmt.Errorf("failed to get backup file info: %w", err)
	}

	log.Printf("✅ Backup created: %s (%.2f MB)", filename, float64(info.Size())/1024/1024)

	return backupPath, nil
}

// CleanupOldBackups removes backups older than retention period
func (bs *BackupService) CleanupOldBackups() error {
	cutoff := time.Now().AddDate(0, 0, -bs.retention)

	entries, err := os.ReadDir(bs.backupDir)
	if err != nil {
		return fmt.Errorf("failed to read backup directory: %w", err)
	}

	deletedCount := 0
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}

		info, err := entry.Info()
		if err != nil {
			continue
		}

		if info.ModTime().Before(cutoff) {
			path := filepath.Join(bs.backupDir, entry.Name())
			if err := os.Remove(path); err != nil {
				log.Printf("⚠️ Failed to delete old backup %s: %v", entry.Name(), err)
			} else {
				deletedCount++
			}
		}
	}

	if deletedCount > 0 {
		log.Printf("🧹 Cleaned up %d old backup(s)", deletedCount)
	}

	return nil
}

// ListBackups returns a list of available backups
func (bs *BackupService) ListBackups() ([]string, error) {
	entries, err := os.ReadDir(bs.backupDir)
	if err != nil {
		return nil, fmt.Errorf("failed to read backup directory: %w", err)
	}

	var backups []string
	for _, entry := range entries {
		if !entry.IsDir() && filepath.Ext(entry.Name()) == ".gz" {
			backups = append(backups, entry.Name())
		}
	}

	return backups, nil
}

// RestoreBackup restores from a backup file
func (bs *BackupService) RestoreBackup(backupFilename string) error {
	backupPath := filepath.Join(bs.backupDir, backupFilename)

	// Check if backup exists
	if _, err := os.Stat(backupPath); os.IsNotExist(err) {
		return fmt.Errorf("backup file not found: %s", backupFilename)
	}

	log.Printf("🔄 Restoring from backup: %s", backupFilename)

	// Set PGPASSWORD environment variable
	env := os.Environ()
	env = append(env, fmt.Sprintf("PGPASSWORD=%s", bs.dbPassword))

	// Create gunzip command
	gunzipCmd := exec.Command("gunzip", "-c", backupPath)

	// Create psql command
	psqlCmd := exec.Command(
		"psql",
		"-h", bs.dbHost,
		"-p", fmt.Sprintf("%d", bs.dbPort),
		"-U", bs.dbUser,
		"-d", bs.dbName,
	)

	psqlCmd.Env = env

	// Pipe gunzip output to psql
	pipe, err := gunzipCmd.StdoutPipe()
	if err != nil {
		return fmt.Errorf("failed to create pipe: %w", err)
	}

	psqlCmd.Stdin = pipe

	// Start both commands
	if err := gunzipCmd.Start(); err != nil {
		return fmt.Errorf("failed to start gunzip: %w", err)
	}

	if err := psqlCmd.Start(); err != nil {
		return fmt.Errorf("failed to start psql: %w", err)
	}

	// Wait for commands to finish
	if err := gunzipCmd.Wait(); err != nil {
		return fmt.Errorf("gunzip failed: %w", err)
	}

	if err := psqlCmd.Wait(); err != nil {
		return fmt.Errorf("psql failed: %w", err)
	}

	log.Printf("✅ Backup restored successfully")

	return nil
}

// ScheduleBackup creates a backup on a schedule
func (bs *BackupService) ScheduleBackup(interval time.Duration) {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()

	log.Printf("⏰ Backup scheduler started (interval: %v)", interval)

	for range ticker.C {
		if _, err := bs.CreateBackup(); err != nil {
			log.Printf("❌ Scheduled backup failed: %v", err)
		}

		if err := bs.CleanupOldBackups(); err != nil {
			log.Printf("⚠️ Backup cleanup failed: %v", err)
		}
	}
}
