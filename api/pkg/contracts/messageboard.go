package contracts

import (
	"errors"
	"math/big"
	"strconv"
	"sync"
	"time"
)

// Message struct matches the structure from the blockchain contract
type Message struct {
	Sender    string   `json:"sender"`
	Content   string   `json:"content"`
	Timestamp *big.Int `json:"timestamp"`
	Likes     *big.Int `json:"likes"`
}

// SimulatedMessageBoard simulates the MessageBoard smart contract functionality
type SimulatedMessageBoard struct {
	messages []Message
	likes    map[string]map[string]bool // messageID -> sender -> liked?
	mu       sync.RWMutex
}

// NewSimulatedMessageBoard creates a new simulated message board contract
func NewSimulatedMessageBoard() *SimulatedMessageBoard {
	return &SimulatedMessageBoard{
		messages: []Message{},
		likes:    make(map[string]map[string]bool),
	}
}

// PostMessage simulates the contract's postMessage function
func (s *SimulatedMessageBoard) PostMessage(sender, content string) (string, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	messageID := len(s.messages)
	timestamp := big.NewInt(time.Now().Unix())

	message := Message{
		Sender:    sender,
		Content:   content,
		Timestamp: timestamp,
		Likes:     big.NewInt(0),
	}

	s.messages = append(s.messages, message)
	s.likes[strconv.Itoa(messageID)] = make(map[string]bool)

	// Return a fake transaction hash
	fakeTransactionHash := "0x" + generateRandomHexString(64)
	return fakeTransactionHash, nil
}

// GetMessages simulates the contract's getMessages function
func (s *SimulatedMessageBoard) GetMessages() ([]Message, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	// Return a copy of the messages to avoid data races
	messagesCopy := make([]Message, len(s.messages))
	copy(messagesCopy, s.messages)

	return messagesCopy, nil
}

// LikeMessage simulates the contract's likeMessage function
func (s *SimulatedMessageBoard) LikeMessage(sender string, messageID int) (string, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	if messageID < 0 || messageID >= len(s.messages) {
		return "", ErrMessageNotFound
	}

	messageIDStr := strconv.Itoa(messageID)
	if s.likes[messageIDStr][sender] {
		return "", ErrAlreadyLiked
	}

	// Mark this message as liked by the sender
	if _, exists := s.likes[messageIDStr]; !exists {
		s.likes[messageIDStr] = make(map[string]bool)
	}
	s.likes[messageIDStr][sender] = true

	// Increment like count
	s.messages[messageID].Likes = new(big.Int).Add(s.messages[messageID].Likes, big.NewInt(1))

	// Return a fake transaction hash
	fakeTransactionHash := "0x" + generateRandomHexString(64)
	return fakeTransactionHash, nil
}

// Generate a random hex string of the given length
func generateRandomHexString(length int) string {
	const hexChars = "0123456789abcdef"
	result := make([]byte, length)

	for i := 0; i < length; i++ {
		result[i] = hexChars[time.Now().UnixNano()%16]
		time.Sleep(1 * time.Nanosecond) // Ensure uniqueness
	}

	return string(result)
}

// Standard errors
var (
	ErrMessageNotFound = errors.New("message does not exist")
	ErrAlreadyLiked    = errors.New("you already liked this message")
)
