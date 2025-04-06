package messageboard

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/jonathonjulian/web3_message_board/backend/pkg/contracts"
	"github.com/jonathonjulian/web3_message_board/backend/pkg/logger"
)

// MessageRequest represents a message request from the client
type MessageRequest struct {
	Sender  string `json:"sender"`
	Content string `json:"content"`
}

// LikeRequest represents a like request from the client
type LikeRequest struct {
	Sender    string `json:"sender"`
	MessageID int    `json:"messageId"`
}

// Handler handles the message board API endpoints
type Handler struct {
	contract *contracts.SimulatedMessageBoard
	logger   *logger.Logger
}

// NewHandler creates a new message board handler
func NewHandler() *Handler {
	// Create a default logger
	log := logger.New(logger.DefaultConfig())

	return &Handler{
		contract: contracts.NewSimulatedMessageBoard(),
		logger:   log,
	}
}

// GetMessages returns all messages from the simulated contract
func (h *Handler) GetMessages(c *gin.Context) {
	h.logger.Info("Fetching messages", "method", c.Request.Method, "path", c.Request.URL.Path)

	messages, err := h.contract.GetMessages()
	if err != nil {
		h.logger.Error("Failed to get messages", "error", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get messages"})
		return
	}

	// Convert the messages to a JSON-friendly format
	jsonMessages := make([]map[string]interface{}, len(messages))
	for i, msg := range messages {
		jsonMessages[i] = map[string]interface{}{
			"sender":    msg.Sender,
			"content":   msg.Content,
			"timestamp": msg.Timestamp.Int64(),
			"likes":     msg.Likes.Int64(),
		}
	}

	c.JSON(http.StatusOK, jsonMessages)
}

// AddMessage adds a new message to the simulated contract
func (h *Handler) AddMessage(c *gin.Context) {
	var req MessageRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		h.logger.Error("Invalid request body", "error", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	h.logger.Info("Adding message", "sender", req.Sender, "content", req.Content)

	txHash, err := h.contract.PostMessage(req.Sender, req.Content)
	if err != nil {
		h.logger.Error("Failed to post message", "error", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to post message"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"txHash": txHash})
}

// LikeMessage likes a message in the simulated contract
func (h *Handler) LikeMessage(c *gin.Context) {
	var req LikeRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		h.logger.Error("Invalid request body", "error", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	h.logger.Info("Liking message", "sender", req.Sender, "messageId", req.MessageID)

	txHash, err := h.contract.LikeMessage(req.Sender, req.MessageID)
	if err != nil {
		h.logger.Error("Failed to like message", "error", err, "code", http.StatusBadRequest)
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"txHash": txHash})
}
