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
	"google.golang.org/grpc"

	"medicore/internal/api"
	"medicore/internal/service"
	pb "medicore/proto"
)

const (
	// Listen on all interfaces (0.0.0.0) so LAN clients can connect
	listenAddr = "0.0.0.0:50051"
	restAddr   = "0.0.0.0:50052"
	port       = 50051
	restPort   = 50052
)

func main() {
	log.Println("")
	log.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	log.Println("🚀 MediCore gRPC Server Starting...")
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

	// Create gRPC server with options for LAN performance
	grpcServer := grpc.NewServer(
		grpc.MaxRecvMsgSize(50*1024*1024), // 50MB max message size
		grpc.MaxSendMsgSize(50*1024*1024),
	)

	// Register the unified MediCore service
	mediCoreService := service.NewMediCoreService(db)
	pb.RegisterMediCoreServiceServer(grpcServer, mediCoreService)

	log.Println("✅ MediCoreService registered")

	// Get local IP for display
	localIP := getLocalIP()

	// Start listening on all interfaces for LAN access
	lis, err := net.Listen("tcp", listenAddr)
	if err != nil {
		log.Fatalf("❌ Failed to listen on %s: %v", listenAddr, err)
	}

	// Start REST API server in background for Flutter clients
	go func() {
		restHandler := api.NewRESTHandler(db)
		mux := http.NewServeMux()
		restHandler.SetupRoutes(mux)

		log.Printf("🌐 REST API server starting on %s", restAddr)
		if err := http.ListenAndServe(restAddr, mux); err != nil {
			log.Printf("⚠️ REST API server error: %v", err)
		}
	}()

	log.Println("")
	log.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	log.Println("✅ MEDICORE SERVER READY FOR LAN CONNECTIONS")
	log.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	log.Printf("🔌 gRPC Server: %s:%d", localIP, port)
	log.Printf("🌐 REST API:    %s:%d", localIP, restPort)
	log.Printf("💻 Computer:    %s", getHostname())
	log.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	log.Println("📡 Flutter clients connect via REST API (port 50052)")
	log.Println("📡 gRPC clients connect via gRPC (port 50051)")
	log.Println("")

	if err := grpcServer.Serve(lis); err != nil {
		log.Fatalf("❌ Failed to serve: %v", err)
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
