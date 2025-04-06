package main

import (
	"os"
	"os/signal"
	"syscall"

	"github.com/jonathonjulian/web3_message_board/backend/pkg/logger"
	"github.com/jonathonjulian/web3_message_board/backend/server"
)

const DefaultPort = "8080"

// Version is set during build using ldflags
var Version = "dev"

func main() {
	log := logger.New(logger.DefaultConfig())

	port := os.Getenv("PORT")
	if port == "" {
		port = DefaultPort
		log.Info("No PORT environment variable found, using default", "port", port)
	}

	addr := ":" + port

	log.Info("Starting API server", "version", Version)
	apiServer := server.New(Version)

	done := make(chan os.Signal, 1)
	signal.Notify(done, os.Interrupt, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		if err := apiServer.Start(addr); err != nil {
			log.Error("Failed to start server", "error", err)
			os.Exit(1)
		}
	}()

	log.Info("Server started", "address", addr)
	log.Info("Press Ctrl+C to stop")

	<-done
	log.Info("Server shutting down...")
}
