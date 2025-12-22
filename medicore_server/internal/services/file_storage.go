package services

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
	"time"
)

// FileStorage handles file storage for PDFs and documents
type FileStorage struct {
	basePath string
}

// NewFileStorage creates a new file storage service
func NewFileStorage(basePath string) (*FileStorage, error) {
	// Create base directory if it doesn't exist
	if err := os.MkdirAll(basePath, 0755); err != nil {
		return nil, fmt.Errorf("failed to create storage directory: %w", err)
	}

	return &FileStorage{
		basePath: basePath,
	}, nil
}

// SaveFile saves a file to storage
func (fs *FileStorage) SaveFile(filename string, data io.Reader) (string, error) {
	// Create date-based subdirectory (YYYY/MM/DD)
	now := time.Now()
	subDir := filepath.Join(
		fmt.Sprintf("%04d", now.Year()),
		fmt.Sprintf("%02d", now.Month()),
		fmt.Sprintf("%02d", now.Day()),
	)

	fullDir := filepath.Join(fs.basePath, subDir)
	if err := os.MkdirAll(fullDir, 0755); err != nil {
		return "", fmt.Errorf("failed to create directory: %w", err)
	}

	// Create unique filename with timestamp
	timestamp := now.Format("150405") // HHMMSS
	uniqueFilename := fmt.Sprintf("%s_%s", timestamp, filename)
	fullPath := filepath.Join(fullDir, uniqueFilename)

	// Create file
	file, err := os.Create(fullPath)
	if err != nil {
		return "", fmt.Errorf("failed to create file: %w", err)
	}
	defer file.Close()

	// Copy data to file
	if _, err := io.Copy(file, data); err != nil {
		return "", fmt.Errorf("failed to write file: %w", err)
	}

	// Return relative path
	relativePath := filepath.Join(subDir, uniqueFilename)
	return relativePath, nil
}

// GetFile retrieves a file from storage
func (fs *FileStorage) GetFile(relativePath string) (io.ReadCloser, error) {
	fullPath := filepath.Join(fs.basePath, relativePath)

	// Check if file exists
	if _, err := os.Stat(fullPath); os.IsNotExist(err) {
		return nil, fmt.Errorf("file not found: %s", relativePath)
	}

	// Open file
	file, err := os.Open(fullPath)
	if err != nil {
		return nil, fmt.Errorf("failed to open file: %w", err)
	}

	return file, nil
}

// DeleteFile deletes a file from storage
func (fs *FileStorage) DeleteFile(relativePath string) error {
	fullPath := filepath.Join(fs.basePath, relativePath)

	if err := os.Remove(fullPath); err != nil {
		return fmt.Errorf("failed to delete file: %w", err)
	}

	return nil
}

// ListFiles lists all files in a directory
func (fs *FileStorage) ListFiles(relativePath string) ([]string, error) {
	fullPath := filepath.Join(fs.basePath, relativePath)

	entries, err := os.ReadDir(fullPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read directory: %w", err)
	}

	var files []string
	for _, entry := range entries {
		if !entry.IsDir() {
			files = append(files, entry.Name())
		}
	}

	return files, nil
}

// GetFileSize returns the size of a file in bytes
func (fs *FileStorage) GetFileSize(relativePath string) (int64, error) {
	fullPath := filepath.Join(fs.basePath, relativePath)

	info, err := os.Stat(fullPath)
	if err != nil {
		return 0, fmt.Errorf("failed to get file info: %w", err)
	}

	return info.Size(), nil
}

// CleanupOldFiles deletes files older than the specified duration
func (fs *FileStorage) CleanupOldFiles(maxAge time.Duration) error {
	cutoff := time.Now().Add(-maxAge)

	err := filepath.Walk(fs.basePath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if !info.IsDir() && info.ModTime().Before(cutoff) {
			if err := os.Remove(path); err != nil {
				return fmt.Errorf("failed to delete old file %s: %w", path, err)
			}
		}

		return nil
	})

	return err
}
