# Web3 Message Board Smart Contracts

This directory contains the Solidity smart contracts for the Web3 Message Board application, built using the Foundry development framework.

## Overview

The core smart contract is `MessageBoard.sol`, which implements the on-chain messaging functionality:

- Posting messages to the blockchain
- Retrieving messages from the blockchain
- Liking messages with on-chain tracking
- Maintaining message metadata (sender, timestamp, like count)

## Contract Details

### MessageBoard.sol

The main contract that implements the messaging functionality:

```solidity
contract MessageBoard {
    struct Message {
        address sender;
        string content;
        uint256 timestamp;
        uint256 likes;
    }

    Message[] public messages;
    mapping(uint256 => mapping(address => bool)) public messageLikes;

    event MessagePosted(address indexed sender, uint256 indexed messageId, string content, uint256 timestamp);
    event MessageLiked(address indexed liker, uint256 indexed messageId, uint256 newLikeCount);

    function postMessage(string memory _content) public { ... }
    function getMessages() public view returns (Message[] memory) { ... }
    function likeMessage(uint256 _messageId) public { ... }
    function getMessageCount() public view returns (uint256) { ... }
}
```

Key features:
- **Message Storage**: Each message includes sender address, content, timestamp, and like count
- **Like Tracking**: Prevents double-liking through address tracking
- **Events**: Emits events for frontend integration and historical tracking
- **View Functions**: Provides methods to retrieve board state

## Development and Testing

The contract development uses Foundry, a fast, portable and modular toolkit for Ethereum development.

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)

### Installation

```bash
# Install dependencies
forge install
```

### Building

```bash
forge build
```

### Testing

```bash
forge test
```

### Deployment

To deploy the contract to a testnet:

```bash
# Using script
forge script script/DeployMessageBoard.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY>

# Using the project Makefile
make contracts-deploy NETWORK=sepolia
```

## Contract Addresses

| Network | Address |
|---------|---------|
| Sepolia | 0x1234...5678 |
| Mumbai  | 0xabcd...ef01 |

## Contract Interface (ABI)

The contract ABI is available in the `out/MessageBoard.sol/MessageBoard.json` file after building. This is used by the frontend and API to interact with the deployed contract.

## Security Considerations

- The contract has no access controls - anyone can post messages
- Message content is stored directly on-chain, which can be expensive for long messages
- Consider gas optimization for high-volume usage
- No content moderation is implemented at the contract level

## Security Best Practices

### Private Key Management
**IMPORTANT: Never commit private keys to Git!**

This project uses environment variables for secure key management:

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and add your private keys and API tokens
   ```
   PRIVATE_KEY=your_actual_private_key_here
   ```

3. Use environment variables in your deployment scripts:
   ```solidity
   // In script/Deploy.s.sol
   function getDeployerPrivateKey() internal returns (uint256) {
       try vm.envUint("PRIVATE_KEY") returns (uint256 privateKey) {
           return privateKey;
       } catch {
           revert("Missing PRIVATE_KEY environment variable");
       }
   }
   ```

### Alternative for CI/CD
For GitHub Actions or other CI/CD workflows, use repository secrets:

```yaml
- name: Deploy contracts
  run: forge script script/Deploy.s.sol --broadcast --verify -vvvv
  env:
    PRIVATE_KEY: ${{ secrets.PRIVATE_KEY }}
    ETHERSCAN_API_KEY: ${{ secrets.ETHERSCAN_API_KEY }}
```
