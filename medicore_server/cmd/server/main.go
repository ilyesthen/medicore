package main

import (
	"database/sql"
	"log"
	"net"
	"os"
	"path/filepath"
	"runtime"

	_ "github.com/mattn/go-sqlite3"
	"google.golang.org/grpc"

	"medicore/internal/service"
	pb "medicore/proto"
)

const (
	port = ":50051"
)

func main() {
	log.Println("🚀 MediCore gRPC Server Starting...")

	// Find the SQLite database
	dbPath := findDatabase()
	if dbPath == "" {
		log.Fatal("❌ Could not find medicore.db. Make sure the admin has imported a database.")
	}

	log.Printf("📊 Connecting to SQLite database: %s", dbPath)

	// Connect to SQLite
	db, err := sql.Open("sqlite3", dbPath+"?cache=shared&mode=ro")
	if err != nil {
		log.Fatalf("❌ Failed to open database: %v", err)
	}
	defer db.Close()

	// Test connection
	if err := db.Ping(); err != nil {
		log.Fatalf("❌ Database ping failed: %v", err)
	}

	log.Println("✅ Database connected successfully")

	// Create gRPC server
	grpcServer := grpc.NewServer()

	// Register the unified MediCore service
	mediCoreService := service.NewMediCoreService(db)
	pb.RegisterMediCoreServiceServer(grpcServer, mediCoreService)

	log.Println("✅ MediCoreService registered")

	// Start listening
	lis, err := net.Listen("tcp", port)
	if err != nil {
		log.Fatalf("❌ Failed to listen on %s: %v", port, err)
	}

	log.Printf("🎯 gRPC Server listening on %s", port)
	log.Println("📡 Ready to accept client connections from LAN")
	log.Println("")

	if err := grpcServer.Serve(lis); err != nil {
		log.Fatalf("❌ Failed to serve: %v", err)
	}
}

// findDatabase locates the medicore.db file
// It checks common locations where the Flutter app stores the database
func findDatabase() string {
	// Try environment variable first
	if dbPath := os.Getenv("MEDICORE_DB_PATH"); dbPath != "" {
		if _, err := os.Stat(dbPath); err == nil {
			return dbPath
		}
	}

	var searchPaths []string

	if runtime.GOOS == "windows" {
		// Windows: Check AppData\Roaming\medicore_app
		appData := os.Getenv("APPDATA")
		if appData != "" {
			searchPaths = append(searchPaths, filepath.Join(appData, "medicore_app", "medicore.db"))
		}
		// Also check Local AppData
		localAppData := os.Getenv("LOCALAPPDATA")
		if localAppData != "" {
			searchPaths = append(searchPaths, filepath.Join(localAppData, "medicore_app", "medicore.db"))
		}
	} else if runtime.GOOS == "darwin" {
		// macOS: Check ~/Library/Application Support/medicore_app
		home := os.Getenv("HOME")
		if home != "" {
			searchPaths = append(searchPaths, filepath.Join(home, "Library", "Application Support", "medicore_app", "medicore.db"))
		}
	} else {
		// Linux: Check ~/.local/share/medicore_app
		home := os.Getenv("HOME")
		if home != "" {
			searchPaths = append(searchPaths, filepath.Join(home, ".local", "share", "medicore_app", "medicore.db"))
		}
	}

	// Search all paths
	for _, path := range searchPaths {
		if _, err := os.Stat(path); err == nil {
			return path
		}
	}

	return ""
}
