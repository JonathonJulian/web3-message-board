package rpc

import (
	"encoding/json"
	"fmt"
	"net/http"
	"sync"
	"time"

	"github.com/jonathonjulian/web3_message_board/backend/pkg/contracts"
	"github.com/jonathonjulian/web3_message_board/backend/pkg/logger"
)

// RPCServer defines the interface for Ethereum RPC servers
type RPCServer interface {
	Handler(w http.ResponseWriter, r *http.Request)
	GetContractAddress() string
}

// Common JSON-RPC structures
type JSONRPCRequest struct {
	JSONRPC string        `json:"jsonrpc"`
	Method  string        `json:"method"`
	Params  []interface{} `json:"params"`
	ID      interface{}   `json:"id"`
}

type JSONRPCResponse struct {
	JSONRPC string      `json:"jsonrpc"`
	Result  interface{} `json:"result,omitempty"`
	Error   *RPCError   `json:"error,omitempty"`
	ID      interface{} `json:"id"`
}

type RPCError struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
}

// Transaction represents an Ethereum transaction
type Transaction struct {
	Hash             string `json:"hash"`
	BlockHash        string `json:"blockHash"`
	BlockNumber      string `json:"blockNumber"`
	From             string `json:"from"`
	To               string `json:"to"`
	Gas              string `json:"gas"`
	GasPrice         string `json:"gasPrice"`
	Input            string `json:"input"`
	Nonce            string `json:"nonce"`
	TransactionIndex string `json:"transactionIndex"`
	Value            string `json:"value"`
	V                string `json:"v"`
	R                string `json:"r"`
	S                string `json:"s"`
}

// TransactionReceipt represents an Ethereum transaction receipt
type TransactionReceipt struct {
	TransactionHash   string        `json:"transactionHash"`
	TransactionIndex  string        `json:"transactionIndex"`
	BlockHash         string        `json:"blockHash"`
	BlockNumber       string        `json:"blockNumber"`
	From              string        `json:"from"`
	To                string        `json:"to"`
	CumulativeGasUsed string        `json:"cumulativeGasUsed"`
	GasUsed           string        `json:"gasUsed"`
	ContractAddress   string        `json:"contractAddress"`
	Logs              []interface{} `json:"logs"`
	LogsBloom         string        `json:"logsBloom"`
	Status            string        `json:"status"`
}

// SimulatedRPCServer implements a simplified Ethereum RPC server for testing
type SimulatedRPCServer struct {
	contractAddress   string
	rpcURL            string
	useSimulation     bool
	messageBoard      *contracts.SimulatedMessageBoard
	transactions      map[string]*Transaction
	receipts          map[string]*TransactionReceipt
	blockNumber       int64
	logger            *logger.Logger
	transactionsMutex sync.RWMutex
}

// NewSimulatedRPCServer creates a new simulated RPC server
func NewSimulatedRPCServer(logger *logger.Logger) *SimulatedRPCServer {
	return &SimulatedRPCServer{
		contractAddress:   "0xd0139AD9718a6C634Ebf0b21f75dE5BD2936035E", // Deployed contract on Arbitrum Sepolia
		rpcURL:            "https://arbitrum-sepolia.infura.io/v3/95267af4ac9947e488119d2052311552",
		useSimulation:     true, // Default to simulation mode
		messageBoard:      contracts.NewSimulatedMessageBoard(),
		transactions:      make(map[string]*Transaction),
		receipts:          make(map[string]*TransactionReceipt),
		blockNumber:       1,
		logger:            logger,
		transactionsMutex: sync.RWMutex{},
	}
}

// Handler handles Ethereum JSON-RPC requests
func (s *SimulatedRPCServer) Handler(w http.ResponseWriter, r *http.Request) {
	// Only POST requests are allowed
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Decode the request
	var req JSONRPCRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendJSONRPCError(w, req.ID, -32700, "Parse error")
		return
	}

	s.logger.Info("Received RPC call", "method", req.Method, "params", fmt.Sprintf("%v", req.Params))

	// Process the request based on method
	var result interface{}
	var err *RPCError

	switch req.Method {
	case "eth_chainId":
		result = "0x66ee6" // Arbitrum Sepolia (421614)
	case "eth_blockNumber":
		result = fmt.Sprintf("0x%x", s.blockNumber)
	case "eth_sendTransaction":
		result, err = s.handleSendTransaction(req)
	case "eth_call":
		result, err = s.handleCall(req)
	case "eth_getTransactionReceipt":
		result, err = s.handleGetTransactionReceipt(req)
	case "eth_getTransactionByHash":
		result, err = s.handleGetTransactionByHash(req)
	case "eth_getBalance":
		result = "0x56bc75e2d63100000" // 100 ETH in wei
	case "eth_gasPrice":
		result = "0x4a817c800" // 20 Gwei
	case "eth_getBlockByNumber":
		result, err = s.handleGetBlockByNumber(req)
	case "eth_getBlockByHash":
		result, err = s.handleGetBlockByHash(req)
	case "eth_estimateGas":
		result = "0x5208" // 21000 gas (standard tx cost)
	default:
		err = &RPCError{
			Code:    -32601,
			Message: "Method not found",
		}
	}

	if err != nil {
		sendJSONRPCError(w, req.ID, err.Code, err.Message)
		return
	}

	// Send the response
	response := JSONRPCResponse{
		JSONRPC: "2.0",
		Result:  result,
		ID:      req.ID,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// handleSendTransaction handles eth_sendTransaction
func (s *SimulatedRPCServer) handleSendTransaction(req JSONRPCRequest) (string, *RPCError) {
	if len(req.Params) < 1 {
		return "", &RPCError{Code: -32602, Message: "Invalid params"}
	}

	// Extract transaction data
	txParam, ok := req.Params[0].(map[string]interface{})
	if !ok {
		return "", &RPCError{Code: -32602, Message: "Invalid transaction format"}
	}

	from, _ := txParam["from"].(string)
	to, _ := txParam["to"].(string)
	data, _ := txParam["data"].(string)

	// If to is our contract address and we have data
	if to == s.contractAddress && data != "" {
		txHash := "0x" + generateRandomHexString(64)
		s.simulateTransaction(txHash, from, to, data)
		s.incrementBlockNumber()
		return txHash, nil
	}

	return "", &RPCError{Code: -32000, Message: "Transaction rejected"}
}

// handleCall handles eth_call
func (s *SimulatedRPCServer) handleCall(req JSONRPCRequest) (string, *RPCError) {
	if len(req.Params) < 1 {
		return "", &RPCError{Code: -32602, Message: "Invalid params"}
	}

	// Extract call data
	callParam, ok := req.Params[0].(map[string]interface{})
	if !ok {
		return "", &RPCError{Code: -32602, Message: "Invalid call format"}
	}

	to, _ := callParam["to"].(string)
	data, _ := callParam["data"].(string)

	// If to is our contract address
	if to == s.contractAddress && data != "" {
		// Check if it's a getMessages call (function selector is the first 4 bytes/8 hex chars of the data)
		// getMessages selector should be "0x8da5cb5b" or similar
		if len(data) >= 10 && (data[:10] == "0x8da5cb5b" || data[:10] == "0x9507d39a") {
			// Get messages from the message board - unused for now but will be used for a real implementation
			_, err := s.messageBoard.GetMessages()
			if err != nil {
				return "0x", &RPCError{
					Code:    -32000,
					Message: "Error getting messages: " + err.Error(),
				}
			}

			// Return sample message data for testing
			// This is a simple ABI-encoded response with two messages
			return "0x0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000120000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb922660000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000006460a48a00000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000010486572652773206d6573736167652031000000000000000000000000000000000000000000000000000000003c44cdddb6a900fa2b585dd299e03d12fa4293bc0000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000006460a5e300000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000010486572652773206d657373616765203200000000000000000000000000000000", nil
		}

		// For other function calls, return a generic response
		return "0x0000000000000000000000000000000000000000000000000000000000000001", nil
	}

	return "0x", nil
}

// handleGetTransactionReceipt handles eth_getTransactionReceipt
func (s *SimulatedRPCServer) handleGetTransactionReceipt(req JSONRPCRequest) (*TransactionReceipt, *RPCError) {
	if len(req.Params) < 1 {
		return nil, &RPCError{Code: -32602, Message: "Invalid params"}
	}

	txHash, ok := req.Params[0].(string)
	if !ok {
		return nil, &RPCError{Code: -32602, Message: "Invalid transaction hash"}
	}

	s.transactionsMutex.RLock()
	receipt, exists := s.receipts[txHash]
	s.transactionsMutex.RUnlock()

	if !exists {
		return nil, nil // Ethereum returns null for non-existent receipts
	}

	return receipt, nil
}

// handleGetTransactionByHash handles eth_getTransactionByHash
func (s *SimulatedRPCServer) handleGetTransactionByHash(req JSONRPCRequest) (*Transaction, *RPCError) {
	if len(req.Params) < 1 {
		return nil, &RPCError{Code: -32602, Message: "Invalid params"}
	}

	txHash, ok := req.Params[0].(string)
	if !ok {
		return nil, &RPCError{Code: -32602, Message: "Invalid transaction hash"}
	}

	s.transactionsMutex.RLock()
	tx, exists := s.transactions[txHash]
	s.transactionsMutex.RUnlock()

	if !exists {
		return nil, nil // Ethereum returns null for non-existent transactions
	}

	return tx, nil
}

// simulateTransaction simulates an Ethereum transaction
func (s *SimulatedRPCServer) simulateTransaction(hash, from, to, data string) {
	s.transactionsMutex.Lock()
	defer s.transactionsMutex.Unlock()

	blockNumberHex := fmt.Sprintf("0x%x", s.blockNumber)

	// Create a new transaction
	tx := &Transaction{
		Hash:             hash,
		BlockHash:        "0x" + generateRandomHexString(64),
		BlockNumber:      blockNumberHex,
		From:             from,
		To:               to,
		Gas:              "0x76c0",
		GasPrice:         "0x4a817c800",
		Input:            data,
		Nonce:            "0x1",
		TransactionIndex: "0x0",
		Value:            "0x0",
		V:                "0x25",
		R:                "0x" + generateRandomHexString(64),
		S:                "0x" + generateRandomHexString(64),
	}

	// Create a receipt
	receipt := &TransactionReceipt{
		TransactionHash:   hash,
		TransactionIndex:  "0x0",
		BlockHash:         tx.BlockHash,
		BlockNumber:       blockNumberHex,
		From:              from,
		To:                to,
		CumulativeGasUsed: "0x76c0",
		GasUsed:           "0x76c0",
		ContractAddress:   "",
		Logs:              []interface{}{},
		LogsBloom:         "0x" + generateRandomHexString(512),
		Status:            "0x1", // Success
	}

	// Store them
	s.transactions[hash] = tx
	s.receipts[hash] = receipt
}

// incrementBlockNumber increases the block number
func (s *SimulatedRPCServer) incrementBlockNumber() {
	s.blockNumber++
}

// sendJSONRPCError sends a JSON-RPC error response
func sendJSONRPCError(w http.ResponseWriter, id interface{}, code int, message string) {
	response := JSONRPCResponse{
		JSONRPC: "2.0",
		Error: &RPCError{
			Code:    code,
			Message: message,
		},
		ID: id,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
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

// handleGetBlockByNumber handles eth_getBlockByNumber
func (s *SimulatedRPCServer) handleGetBlockByNumber(req JSONRPCRequest) (map[string]interface{}, *RPCError) {
	if len(req.Params) < 2 {
		return nil, &RPCError{Code: -32602, Message: "Invalid params"}
	}

	blockNumber := "0x1" // Default to block 1
	includeTransactions := false

	if req.Params[0] != nil {
		if tag, ok := req.Params[0].(string); ok {
			if tag == "latest" || tag == "pending" {
				blockNumber = fmt.Sprintf("0x%x", s.blockNumber)
			} else {
				blockNumber = tag
			}
		}
	}

	if req.Params[1] != nil {
		if full, ok := req.Params[1].(bool); ok {
			includeTransactions = full
		}
	}

	// Prepare a fake block response
	// Parse block number for future use if needed
	// blockNumberInt, _ := strconv.ParseInt(blockNumber[2:], 16, 64) // Remove '0x' prefix
	blockHash := "0x" + generateRandomHexString(64)

	blockResponse := map[string]interface{}{
		"number":           blockNumber,
		"hash":             blockHash,
		"parentHash":       "0x" + generateRandomHexString(64),
		"nonce":            "0x" + generateRandomHexString(16),
		"sha3Uncles":       "0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347",
		"logsBloom":        "0x" + generateRandomHexString(512),
		"transactionsRoot": "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
		"stateRoot":        "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
		"receiptsRoot":     "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
		"miner":            "0x0000000000000000000000000000000000000000",
		"difficulty":       "0x0",
		"totalDifficulty":  "0x0",
		"extraData":        "0x",
		"size":             "0x3e8",
		"gasLimit":         "0x1c9c380",
		"gasUsed":          "0x0",
		"timestamp":        fmt.Sprintf("0x%x", time.Now().Unix()),
		"transactions":     []interface{}{},
		"uncles":           []interface{}{},
	}

	// Include transactions if requested
	if includeTransactions {
		// Add sample transactions if needed
		blockResponse["transactions"] = []interface{}{}
	}

	return blockResponse, nil
}

// handleGetBlockByHash handles eth_getBlockByHash
func (s *SimulatedRPCServer) handleGetBlockByHash(req JSONRPCRequest) (map[string]interface{}, *RPCError) {
	if len(req.Params) < 2 {
		return nil, &RPCError{Code: -32602, Message: "Invalid params"}
	}

	blockHash, ok := req.Params[0].(string)
	if !ok {
		return nil, &RPCError{Code: -32602, Message: "Invalid block hash"}
	}

	includeTransactions := false
	if req.Params[1] != nil {
		if full, ok := req.Params[1].(bool); ok {
			includeTransactions = full
		}
	}

	// Prepare a fake block response
	blockResponse := map[string]interface{}{
		"number":           fmt.Sprintf("0x%x", s.blockNumber),
		"hash":             blockHash,
		"parentHash":       "0x" + generateRandomHexString(64),
		"nonce":            "0x" + generateRandomHexString(16),
		"sha3Uncles":       "0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347",
		"logsBloom":        "0x" + generateRandomHexString(512),
		"transactionsRoot": "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
		"stateRoot":        "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
		"receiptsRoot":     "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
		"miner":            "0x0000000000000000000000000000000000000000",
		"difficulty":       "0x0",
		"totalDifficulty":  "0x0",
		"extraData":        "0x",
		"size":             "0x3e8",
		"gasLimit":         "0x1c9c380",
		"gasUsed":          "0x0",
		"timestamp":        fmt.Sprintf("0x%x", time.Now().Unix()),
		"transactions":     []interface{}{},
		"uncles":           []interface{}{},
	}

	// Include transactions if requested
	if includeTransactions {
		// Add sample transactions if needed
		blockResponse["transactions"] = []interface{}{}
	}

	return blockResponse, nil
}

// GetContractAddress returns the contract address used by the server
func (s *SimulatedRPCServer) GetContractAddress() string {
	return s.contractAddress
}
