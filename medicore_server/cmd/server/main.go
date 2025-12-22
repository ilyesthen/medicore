package main

import (
	"log"
	"net"
	"net/http"
	"os"

	"medicore/internal/api"
	"medicore/internal/database"
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

	// Connect to PostgreSQL database
	dbConfig := database.DefaultConfig()
	db, err := database.NewPostgresConnection(dbConfig)
	if err != nil {
		log.Fatalf("❌ Failed to connect to PostgreSQL: %v", err)
	}
	defer db.Close()

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
