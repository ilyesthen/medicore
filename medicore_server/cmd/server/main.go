package main

import (
	"fmt"
	"log"
	"net"
	"os"

	"medicore-server/internal/database"
	"medicore-server/internal/service"
	pb "medicore-server/proto"

	"google.golang.org/grpc"
)

const (
	port = ":50051"
)

func main() {
	log.Println("🚀 Starting MediCore Server...")

	// Database configuration
	dbConfig := getDBConfig()
	
	// Connect to PostgreSQL
	log.Printf("📊 Connecting to PostgreSQL at %s:%d...", dbConfig.Host, dbConfig.Port)
	db, err := database.NewPostgresConnection(dbConfig)
	if err != nil {
		log.Fatalf("❌ Failed to connect to database: %v", err)
	}
	defer db.Close()
	log.Println("✅ Database connected successfully")

	// Create gRPC server
	grpcServer := grpc.NewServer()
	
	// Register services
	usersService := service.NewUsersService(db)
	pb.RegisterUsersServiceServer(grpcServer, usersService)
	log.Println("✅ UsersService registered")

	// Start listening
	lis, err := net.Listen("tcp", port)
	if err != nil {
		log.Fatalf("❌ Failed to listen on %s: %v", port, err)
	}

	log.Printf("🎯 MediCore gRPC Server listening on %s", port)
	log.Println("📡 Ready to accept client connections...")
	
	if err := grpcServer.Serve(lis); err != nil {
		log.Fatalf("❌ Failed to serve: %v", err)
	}
}

// getDBConfig returns database configuration from environment or defaults
func getDBConfig() database.Config {
	config := database.DefaultConfig()
	
	// Override with environment variables if present
	if host := os.Getenv("DB_HOST"); host != "" {
		config.Host = host
	}
	if port := os.Getenv("DB_PORT"); port != "" {
		fmt.Sscanf(port, "%d", &config.Port)
	}
	if user := os.Getenv("DB_USER"); user != "" {
		config.User = user
	}
	if pass := os.Getenv("DB_PASSWORD"); pass != "" {
		config.Password = pass
	}
	if dbname := os.Getenv("DB_NAME"); dbname != "" {
		config.DBName = dbname
	}
	if sslmode := os.Getenv("DB_SSLMODE"); sslmode != "" {
		config.SSLMode = sslmode
	}
	
	return config
}
