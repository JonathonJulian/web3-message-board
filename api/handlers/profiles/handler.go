package profiles

import (
	"net/http"
	"sync"

	"github.com/gin-gonic/gin"
)

// Profile represents a user profile with additional metadata beyond blockchain address
type Profile struct {
	Address     string   `json:"address"`
	Username    string   `json:"username"`
	Bio         string   `json:"bio"`
	AvatarURL   string   `json:"avatarUrl,omitempty"`
	SocialLinks []string `json:"socialLinks,omitempty"`
	CreatedAt   int64    `json:"createdAt"`
	UpdatedAt   int64    `json:"updatedAt"`
}

// Handler for profile operations
type Handler struct {
	profiles map[string]*Profile
	mu       sync.RWMutex
}

// NewHandler creates a new profile handler
func NewHandler() *Handler {
	return &Handler{
		profiles: make(map[string]*Profile),
		mu:       sync.RWMutex{},
	}
}

// GetProfile returns a user profile by Ethereum address
func (h *Handler) GetProfile(c *gin.Context) {
	address := c.Param("address")
	if address == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Address parameter is required"})
		return
	}

	h.mu.RLock()
	profile, exists := h.profiles[address]
	h.mu.RUnlock()

	if !exists {
		c.JSON(http.StatusNotFound, gin.H{"error": "Profile not found"})
		return
	}

	c.JSON(http.StatusOK, profile)
}

// CreateOrUpdateProfile creates or updates a user profile
func (h *Handler) CreateOrUpdateProfile(c *gin.Context) {
	var profile Profile
	if err := c.ShouldBindJSON(&profile); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	// Validate the profile
	if profile.Address == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Address is required"})
		return
	}

	// Override address from URL if it's a PUT request
	if c.Request.Method == http.MethodPut {
		urlAddress := c.Param("address")
		if urlAddress != "" {
			profile.Address = urlAddress
		}
	}

	// Update timestamp
	now := currentTimestamp()
	profile.UpdatedAt = now

	h.mu.Lock()
	existing, exists := h.profiles[profile.Address]
	if exists {
		// Preserve creation time if profile already exists
		profile.CreatedAt = existing.CreatedAt
	} else {
		profile.CreatedAt = now
	}
	h.profiles[profile.Address] = &profile
	h.mu.Unlock()

	c.JSON(http.StatusOK, profile)
}

// Helper function to get current timestamp
func currentTimestamp() int64 {
	return int64(0) // TODO: Replace with actual timestamp
}
