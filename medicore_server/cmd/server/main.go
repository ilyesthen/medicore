package main

import (
	"database/sql"
	"log"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"runtime"

	_ "github.com/mattn/go-sqlite3"

	"medicore/internal/api"
)

const (
	// Listen on all interfaces (0.0.0.0) so LAN clients can connect
	restAddr = "0.0.0.0:50052"
	restPort = 50052
	// Keep a TCP listener on 50051 for connection testing
	testAddr = "0.0.0.0:50051"
	testPort = 50051
)

func main() {
	log.Println("")
	log.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	log.Println("🚀 MediCore REST API Server Starting...")
	log.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

	// Find the SQLite database
	dbPath := findDatabase()
	if dbPath == "" {
		log.Fatal("❌ Could not find medicore.db. Make sure the admin has imported a database.")
	}

	log.Printf("📊 Database: %s", dbPath)

	// Connect to SQLite with read-write mode for proper functionality
	db, err := sql.Open("sqlite3", dbPath+"?cache=shared&_journal_mode=WAL")
	if err != nil {
		log.Fatalf("❌ Failed to open database: %v", err)
	}
	defer db.Close()

	// Configure connection pool for LAN access
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(5)

	// Test connection
	if err := db.Ping(); err != nil {
		log.Fatalf("❌ Database ping failed: %v", err)
	}

	log.Println("✅ Database connected successfully")

	// Get local IP for display
	localIP := getLocalIP()

	// Start a simple TCP listener on 50051 for connection testing
	// (Flutter setup wizard tests this port to verify server is reachable)
	go func() {
		lis, err := net.Listen("tcp", testAddr)
		if err != nil {
			log.Printf("⚠️ Could not start test listener on %s: %v", testAddr, err)
			return
		}
		log.Printf("🔌 Test listener on port %d (for client discovery)", testPort)
		for {
			conn, err := lis.Accept()
			if err != nil {
				continue
			}
			conn.Close() // Just accept and close - only for testing connectivity
		}
	}()

	// Setup REST API server
	restHandler := api.NewRESTHandler(db)
	mux := http.NewServeMux()
	restHandler.SetupRoutes(mux)
	restHandler.SetupSSERoutes(mux) // Real-time events via Server-Sent Events

	log.Println("")
	log.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	log.Println("✅ MEDICORE SERVER READY FOR LAN CONNECTIONS")
	log.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	log.Printf("🌐 REST API:    http://%s:%d", localIP, restPort)
	log.Printf("📡 SSE Events:  http://%s:%d/api/events", localIP, restPort)
	log.Printf("🔌 Test Port:   %s:%d", localIP, testPort)
	log.Printf("💻 Computer:    %s", getHostname())
	log.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	log.Println("📡 Real-time sync enabled via Server-Sent Events")
	log.Println("")

	if err := http.ListenAndServe(restAddr, mux); err != nil {
		log.Fatalf("❌ Failed to start REST server: %v", err)
	}
}

// getLocalIP returns the local IP address for LAN
func getLocalIP() string {
	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return "127.0.0.1"
	}

	for _, addr := range addrs {
		if ipnet, ok := addr.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
			if ipnet.IP.To4() != nil {
				ip := ipnet.IP.String()
				// Prefer LAN addresses
				if len(ip) > 3 && (ip[:3] == "192" || ip[:3] == "10." || ip[:4] == "172.") {
					return ip
				}
			}
		}
	}

	// Fallback: return first non-loopback IPv4
	for _, addr := range addrs {
		if ipnet, ok := addr.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
			if ipnet.IP.To4() != nil {
				return ipnet.IP.String()
			}
		}
	}

	return "127.0.0.1"
}

// getHostname returns the computer hostname
func getHostname() string {
	hostname, err := os.Hostname()
	if err != nil {
		return "Unknown"
	}
	return hostname
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
		// Windows: Check AppData\Roaming\com.example\medicore_app (Flutter's path)
		appData := os.Getenv("APPDATA")
		if appData != "" {
			// Primary: Flutter uses com.example\medicore_app
			searchPaths = append(searchPaths, filepath.Join(appData, "com.example", "medicore_app", "medicore.db"))
			// Fallback: direct medicore_app folder
			searchPaths = append(searchPaths, filepath.Join(appData, "medicore_app", "medicore.db"))
		}
		// Also check Local AppData
		localAppData := os.Getenv("LOCALAPPDATA")
		if localAppData != "" {
			searchPaths = append(searchPaths, filepath.Join(localAppData, "com.example", "medicore_app", "medicore.db"))
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
