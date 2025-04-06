package search

import (
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
)

// Message represents a message from the message board
type Message struct {
	ID        string    `json:"id"`
	Message   string    `json:"message"`
	Author    string    `json:"author"`
	Likes     int       `json:"likes"`
	Timestamp time.Time `json:"timestamp"`
	ImageRef  string    `json:"imageRef,omitempty"` // Reference to an uploaded image
}

// Handler manages search functionality
type Handler struct {
	messages []Message
	mu       sync.RWMutex
}

// SearchResult contains paginated search results
type SearchResult struct {
	Results    []Message `json:"results"`
	Total      int       `json:"total"`
	Page       int       `json:"page"`
	PageSize   int       `json:"pageSize"`
	TotalPages int       `json:"totalPages"`
	QueryTime  float64   `json:"queryTimeMs"`
}

// NewHandler creates a new search handler
func NewHandler() *Handler {
	return &Handler{
		messages: []Message{},
		mu:       sync.RWMutex{},
	}
}

// IndexMessage adds a message to the search index
func (h *Handler) IndexMessage(message Message) {
	h.mu.Lock()
	defer h.mu.Unlock()

	// Check if message already exists
	for i, m := range h.messages {
		if m.ID == message.ID {
			// Update existing message
			h.messages[i] = message
			return
		}
	}

	// Add new message
	h.messages = append(h.messages, message)
}

// SearchMessages handles message search requests
func (h *Handler) SearchMessages(c *gin.Context) {
	// Extract search parameters
	query := c.Query("q")
	author := c.Query("author")
	page := 1      // Default page
	pageSize := 20 // Default page size

	// Track search time
	startTime := time.Now()

	// Perform search
	h.mu.RLock()
	var results []Message

	// Filter messages based on search criteria
	for _, msg := range h.messages {
		matchesQuery := query == "" || strings.Contains(strings.ToLower(msg.Message), strings.ToLower(query))
		matchesAuthor := author == "" || strings.EqualFold(msg.Author, author)

		if matchesQuery && matchesAuthor {
			results = append(results, msg)
		}
	}
	h.mu.RUnlock()

	// Calculate pagination
	total := len(results)
	totalPages := (total + pageSize - 1) / pageSize

	// Apply pagination
	start := (page - 1) * pageSize
	end := start + pageSize
	if end > total {
		end = total
	}

	// Avoid index out of range
	if start < total {
		results = results[start:end]
	} else {
		results = []Message{}
	}

	// Calculate query time
	queryTime := float64(time.Since(startTime).Microseconds()) / 1000.0 // Convert to milliseconds

	// Create response
	response := SearchResult{
		Results:    results,
		Total:      total,
		Page:       page,
		PageSize:   pageSize,
		TotalPages: totalPages,
		QueryTime:  queryTime,
	}

	// Return results
	c.JSON(http.StatusOK, response)
}

// Helper function to index messages from the main message board
func (h *Handler) SyncMessagesFromBoard(messages []Message) {
	h.mu.Lock()
	defer h.mu.Unlock()

	// Replace all messages with the updated set
	h.messages = messages
}
