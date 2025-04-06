package storage

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"sync"

	"github.com/gin-gonic/gin"
)

// File represents metadata about a stored file
type File struct {
	ID          string `json:"id"`
	FileName    string `json:"fileName"`
	ContentType string `json:"contentType"`
	Size        int64  `json:"size"`
	UploadedBy  string `json:"uploadedBy,omitempty"`
	UploadedAt  int64  `json:"uploadedAt"`
}

// FileResponse is the response returned after a successful upload
type FileResponse struct {
	File      *File  `json:"file"`
	URL       string `json:"url"`
	Reference string `json:"reference"` // This is what gets stored on-chain
}

// Handler for file storage operations
type Handler struct {
	files       map[string]*File
	storagePath string
	mu          sync.RWMutex
}

// NewHandler creates a new storage handler
func NewHandler() *Handler {
	// Create storage directory if it doesn't exist
	storagePath := "./storage"
	os.MkdirAll(storagePath, 0755)

	return &Handler{
		files:       make(map[string]*File),
		storagePath: storagePath,
		mu:          sync.RWMutex{},
	}
}

// UploadFile handles file uploads
func (h *Handler) UploadFile(c *gin.Context) {
	// Maximum file size of 10MB
	file, header, err := c.Request.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Error retrieving the file: " + err.Error()})
		return
	}
	defer file.Close()

	// Check content type (allow only images)
	contentType := header.Header.Get("Content-Type")
	if !isImageContentType(contentType) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Only image files are allowed"})
		return
	}

	// Read file data to calculate hash
	fileData, err := io.ReadAll(file)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error reading file: " + err.Error()})
		return
	}

	// Calculate file hash as ID
	fileHash := sha256.Sum256(fileData)
	fileID := hex.EncodeToString(fileHash[:])

	// Create file metadata
	fileObj := &File{
		ID:          fileID,
		FileName:    header.Filename,
		ContentType: contentType,
		Size:        header.Size,
		UploadedBy:  c.PostForm("address"), // Optional wallet address of uploader
		UploadedAt:  int64(0),              // TODO: use real timestamp
	}

	// Save file to disk
	filePath := filepath.Join(h.storagePath, fileID)
	err = os.WriteFile(filePath, fileData, 0644)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error saving file: " + err.Error()})
		return
	}

	// Store file metadata
	h.mu.Lock()
	h.files[fileID] = fileObj
	h.mu.Unlock()

	// Create response
	response := FileResponse{
		File:      fileObj,
		URL:       fmt.Sprintf("/api/files/%s", fileID),
		Reference: fileID, // This is what gets stored on the blockchain
	}

	// Return metadata in response
	c.JSON(http.StatusCreated, response)
}

// GetFile serves a file by its ID
func (h *Handler) GetFile(c *gin.Context) {
	fileID := c.Param("fileId")
	if fileID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "File ID is required"})
		return
	}

	// Check if file exists in our metadata
	h.mu.RLock()
	file, exists := h.files[fileID]
	h.mu.RUnlock()

	filePath := filepath.Join(h.storagePath, fileID)

	if !exists {
		// Try to serve the file anyway if it exists on disk
		if _, err := os.Stat(filePath); os.IsNotExist(err) {
			c.JSON(http.StatusNotFound, gin.H{"error": "File not found"})
			return
		}

		// If file exists but metadata doesn't, serve it with generic content type
		c.File(filePath)
		return
	}

	// Set content type and serve file
	c.Header("Content-Disposition", fmt.Sprintf("inline; filename=%s", file.FileName))
	c.Header("Content-Type", file.ContentType)
	c.File(filePath)
}

// Helper function to check if content type is an image
func isImageContentType(contentType string) bool {
	allowedTypes := map[string]bool{
		"image/jpeg":    true,
		"image/png":     true,
		"image/gif":     true,
		"image/webp":    true,
		"image/svg+xml": true,
	}
	return allowedTypes[contentType]
}
