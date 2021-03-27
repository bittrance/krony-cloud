package main

import (
	"context"
	"flag"
	"log"
	"net/http"
	"os"
	"os/signal"
	"sync"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
)

type Entries = map[string][]time.Time

func RunReceiver(bindAddress string, verbose bool) *http.Server {
	var entries = make(Entries)
	var lock = sync.Mutex{}
	if !verbose {
		gin.SetMode("release")
	}
	router := gin.New()
	if verbose {
		router.Use(gin.LoggerWithWriter(gin.DefaultWriter))
	}
	router.Use(gin.Recovery())
	router.PUT("/log/:token", func(c *gin.Context) {
		token := c.Param("token")
		lock.Lock()
		entries[token] = append(entries[token], time.Now())
		lock.Unlock()
		c.String(200, "ok")
	})
	router.GET("/logs", func(c *gin.Context) {
		c.JSON(200, &entries)
	})
	router.DELETE("/logs", func(c *gin.Context) {
		entries = make(Entries)
		c.String(200, "ok")
	})

	server := &http.Server{
		Addr:    bindAddress,
		Handler: router,
	}

	go func() {
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Cannot bind %s: %s\n", bindAddress, err)
		}
	}()
	return server
}

func main() {
	var bindAddress string
	var verbose bool
	flag.StringVar(&bindAddress, "bind", ":8080", "Bind address as [host]:port")
	flag.BoolVar(&verbose, "verbose", false, "Turn on verbose logging")
	flag.Parse()
	log.Printf("Webhook receiver listening to %s\n", bindAddress)
	server := RunReceiver(bindAddress, verbose)
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	log.Println("Webhook receiver terminated")
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := server.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %s", err)
	}
}
