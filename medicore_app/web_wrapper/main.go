package main

import (
	"embed"
	"fmt"
	"io/fs"
	"log"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"time"
)

//go:embed web/*
var webFiles embed.FS

func main() {
	// Get a free port
	port := getFreePort()
	if port == 0 {
		log.Fatal("Could not find free port")
	}

	serverURL := fmt.Sprintf("http://localhost:%d", port)

	// Start web server in background
	go startServer(port)

	// Wait a moment for server to start
	time.Sleep(time.Millisecond * 500)

	// Open in default browser in app mode (looks like native app)
	openBrowser(serverURL)

	// Keep running
	select {}
}

func startServer(port int) {
	// Get embedded web files
	webFS, err := fs.Sub(webFiles, "web")
	if err != nil {
		log.Fatal(err)
	}

	http.Handle("/", http.FileServer(http.FS(webFS)))

	addr := fmt.Sprintf(":%d", port)
	log.Printf("MediCore Web Server starting on http://localhost%s", addr)

	if err := http.ListenAndServe(addr, nil); err != nil {
		log.Fatal(err)
	}
}

func getFreePort() int {
	listener, err := net.Listen("tcp", ":0")
	if err != nil {
		return 0
	}
	defer listener.Close()
	return listener.Addr().(*net.TCPAddr).Port
}

func openBrowser(url string) {
	var cmd *exec.Cmd

	switch runtime.GOOS {
	case "windows":
		// Try Chrome app mode first (looks like native app)
		chromePaths := []string{
			filepath.Join(os.Getenv("ProgramFiles"), "Google", "Chrome", "Application", "chrome.exe"),
			filepath.Join(os.Getenv("ProgramFiles(x86)"), "Google", "Chrome", "Application", "chrome.exe"),
			filepath.Join(os.Getenv("LOCALAPPDATA"), "Google", "Chrome", "Application", "chrome.exe"),
		}

		for _, chromePath := range chromePaths {
			if _, err := os.Stat(chromePath); err == nil {
				cmd = exec.Command(chromePath, "--app="+url, "--window-size=1280,800")
				if err := cmd.Start(); err == nil {
					return
				}
			}
		}

		// Try Edge app mode
		edgePath := filepath.Join(os.Getenv("ProgramFiles(x86)"), "Microsoft", "Edge", "Application", "msedge.exe")
		if _, err := os.Stat(edgePath); err == nil {
			cmd = exec.Command(edgePath, "--app="+url, "--window-size=1280,800")
			if err := cmd.Start(); err == nil {
				return
			}
		}

		// Fallback: default browser
		cmd = exec.Command("rundll32", "url.dll,FileProtocolHandler", url)
	case "darwin":
		cmd = exec.Command("open", url)
	default:
		cmd = exec.Command("xdg-open", url)
	}

	if err := cmd.Start(); err != nil {
		log.Printf("Failed to open browser: %v", err)
	}
}
