import { writable } from 'svelte/store';
import * as ethers from 'ethers';
import Web3Modal from 'web3modal';

// Message Board ABI - will be replaced with the actual ABI after contract compilation
const MessageBoardABI = [
  "function postMessage(string memory _content) public",
  "function getMessages() public view returns (tuple(address sender, string content, uint256 timestamp, uint256 likes)[] memory)",
  "function likeMessage(uint256 _messageId) public"
];

// Contract address
export const CONTRACT_ADDRESS = '0xd0139AD9718a6C634Ebf0b21f75dE5BD2936035E'; // Updated contract address on Monad

// RPC URLs
export const MONAD_RPC_URL = 'https://arbitrum-sepolia.infura.io/v3/95267af4ac9947e488119d2052311552';
// Fallback for local development - keep as reference for debugging
// const LOCAL_RPC_URL = 'http://localhost:8080';

// Use Monad by default
// const RPC_URL = MONAD_RPC_URL;

// Define if we're in simulation mode
const IS_SIMULATION_MODE = false; // Set to false since we're using real Monad

// Define types
type Message = {
  sender: string;
  content: string;
  timestamp: number;
  likes: number;
};

export const wallet = writable<string | null>(null);
export const provider = writable<any>(null);
export const messageBoardContract = writable<any>(null);
export const messages = writable<Message[]>([]);
export const isConnected = writable<boolean>(false);
export const chainId = writable<number | null>(null);
export const isSimulated = writable<boolean>(false);
export const networkName = writable<string>('monad'); // Default to Monad network

// Initialize Web3Modal
let web3Modal: any;

if (typeof window !== 'undefined') {
  web3Modal = new Web3Modal({
    cacheProvider: true,
    providerOptions: {}
  });
}

// Add this near the top of the file after the imports
let fetchInProgress = false;
let lastFetchTime = 0;
const FETCH_COOLDOWN_MS = 1000; // Prevent refetching more than once per second

// Connect wallet
export async function connectWallet() {
  try {
    const instance = await web3Modal.connect();
    const ethersProvider = new ethers.providers.Web3Provider(instance);
    const signer = ethersProvider.getSigner();
    const address = await signer.getAddress();
    const network = await ethersProvider.getNetwork();

    // Initialize contract
    const contract = new ethers.Contract(CONTRACT_ADDRESS, MessageBoardABI, signer);

    // Update stores
    wallet.set(address);
    provider.set(ethersProvider);
    messageBoardContract.set(contract);
    isConnected.set(true);
    chainId.set(network.chainId);

    // Set simulation flag based on our constant
    isSimulated.set(IS_SIMULATION_MODE);

    // Setup event listeners
    instance.on('accountsChanged', (accounts: string[]) => {
      if (accounts.length === 0) {
        disconnectWallet();
      } else {
        wallet.set(accounts[0]);
      }
    });

    instance.on('chainChanged', () => {
      window.location.reload();
    });

    return true;
  } catch (error) {
    console.error('Error connecting wallet:', error);
    return false;
  }
}

// Connect with simulated wallet for local development
export async function connectSimulatedWallet() {
  console.log("Attempting to connect simulated wallet");
  try {
    // Create a random wallet address for simulation
    const randomWallet = ethers.Wallet.createRandom();
    // Cast the wallet to any to access the address property
    const address = (randomWallet as any).address;
    console.log("Simulated wallet address:", address);

    // Update stores directly without attempting RPC
    wallet.set(address);
    isConnected.set(true);
    isSimulated.set(true);

    // Use mock data instead of trying to fetch from contract
    console.log("Setting up mock data for simulation");
    messages.set([
      {
        sender: '0x71C7656EC7ab88b098defB751B7401B5f6d8976F',
        content: 'Welcome to Monad Message Board! This is a simulated message.',
        timestamp: Math.floor(Date.now() / 1000) - 3600, // 1 hour ago
        likes: 5
      },
      {
        sender: '0x90F79bf6EB2c4f870365E785982E1f101E93b906',
        content: 'This is a simulated message. In production, messages would be stored on the Monad blockchain.',
        timestamp: Math.floor(Date.now() / 1000) - 1800, // 30 minutes ago
        likes: 3
      },
      {
        sender: address, // Use the current simulated wallet address
        content: 'You are using a simulated wallet. Your messages will appear here but won\'t be saved permanently.',
        timestamp: Math.floor(Date.now() / 1000) - 300, // 5 minutes ago
        likes: 1
      }
    ]);

    console.log("Simulated wallet connection complete");
    return true;
  } catch (error) {
    console.error("Error connecting simulated wallet:", error);
    return false;
  }
}

// Disconnect wallet
export function disconnectWallet() {
  wallet.set(null);
  provider.set(null);
  messageBoardContract.set(null);
  isConnected.set(false);
  chainId.set(null);
  isSimulated.set(false);

  if (web3Modal) {
    web3Modal.clearCachedProvider();
  }
}

// Get messages from the contract or API
export async function fetchMessages() {
  // Prevent concurrent fetches and rate limit
  const now = Date.now();
  if (fetchInProgress || (now - lastFetchTime < FETCH_COOLDOWN_MS)) {
    console.log('Fetch already in progress or too frequent, skipping');
    return;
  }

  fetchInProgress = true;
  lastFetchTime = now;

  try {
    // Try to get messages from contract first
    let contractInstance: any;
    messageBoardContract.subscribe((value: any) => {
      contractInstance = value;
    })();

    if (contractInstance) {
      try {
        const result = await contractInstance.getMessages();
        const formattedMessages = result.map((msg: any) => ({
          sender: msg.sender,
          content: msg.content,
          timestamp: parseInt(msg.timestamp.toString()),
          likes: parseInt(msg.likes.toString())
        }));

        messages.set(formattedMessages);
        fetchInProgress = false;
        return;
      } catch (error) {
        console.error('Error fetching messages from contract:', error);
      }
    }

    // Fallback to REST API if contract call fails
    try {
      const response = await fetch(`/api/messages`);
      if (response.ok) {
        const data = await response.json();
        messages.set(data);
      }
    } catch (error) {
      console.error('Error fetching messages from API:', error);

      // Emergency fallback: Show mock data if all else fails
      console.log('Using emergency mock data fallback');
      messages.set([
        {
          sender: '0x71C7656EC7ab88b098defB751B7401B5f6d8976F',
          content: 'Welcome to Monad Message Board! This is a mock message since the backend is not accessible.',
          timestamp: Math.floor(Date.now() / 1000) - 3600, // 1 hour ago
          likes: 5
        },
        {
          sender: '0x90F79bf6EB2c4f870365E785982E1f101E93b906',
          content: 'This is a simulated message. In production, messages would be stored on the Monad blockchain.',
          timestamp: Math.floor(Date.now() / 1000) - 1800, // 30 minutes ago
          likes: 3
        },
        {
          sender: '0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC',
          content: 'Once the backend is running, you will see real messages from the blockchain or API here!',
          timestamp: Math.floor(Date.now() / 1000) - 600, // 10 minutes ago
          likes: 1
        }
      ]);
    }
  } finally {
    fetchInProgress = false;
  }
}

// Post a new message
export async function postMessage(content: string) {
  // For simulated mode, just add to the mock data
  let isSimulatedMode = false;
  isSimulated.subscribe(value => {
    isSimulatedMode = value;
  })();

  if (isSimulatedMode) {
    // Get current wallet address
    let currentWallet = '';
    wallet.subscribe(value => {
      currentWallet = value || '';
    })();

    // Get current messages
    let currentMessages: Message[] = [];
    messages.subscribe(value => {
      currentMessages = [...value];
    })();

    // Add new message to the beginning
    currentMessages.unshift({
      sender: currentWallet,
      content: content,
      timestamp: Math.floor(Date.now() / 1000),
      likes: 0
    });

    // Update the store
    messages.set(currentMessages);
    return true;
  }

  // Regular contract interaction
  let contractInstance: any;
  messageBoardContract.subscribe((value: any) => {
    contractInstance = value;
  })();

  if (!contractInstance) {
    console.error("No contract instance available");
    return false;
  }

  let walletProvider: any;
  provider.subscribe(value => {
    walletProvider = value;
  })();

  try {
    // Check if network is correct
    if (walletProvider) {
      const network = await walletProvider.getNetwork();
      console.log("Current network:", network);

      if (network.chainId !== 10143) {
        console.error(`Wrong network! Connected to ${network.name} (${network.chainId}), need to be on Monad (10143)`);
        throw new Error(`Please connect to Monad network in your wallet (current: ${network.name})`);
      }
    }

    console.log("Attempting to post message:", content);
    console.log("Using contract at address:", CONTRACT_ADDRESS);

    const tx = await contractInstance.postMessage(content);
    console.log("Transaction submitted:", tx.hash);

    const receipt = await tx.wait();
    console.log("Transaction confirmed:", receipt);

    await fetchMessages();
    return true;
  } catch (error: any) {
    console.error('Error posting message:', error);

    // More detailed error analysis
    if (error.code && error.message) {
      console.error(`Error details - Code: ${error.code}, Message: ${error.message}`);
    }

    // Try to extract deeper error if available
    if (error.error && error.error.message) {
      console.error("Inner error:", error.error.message);
    }

    return false;
  }
}

// Like a message
export async function likeMessage(messageId: number) {
  // For simulated mode, just update the mock data
  let isSimulatedMode = false;
  isSimulated.subscribe(value => {
    isSimulatedMode = value;
  })();

  if (isSimulatedMode) {
    // Get current messages
    let currentMessages: Message[] = [];
    messages.subscribe(value => {
      currentMessages = [...value];
    })();

    // Increment likes for the specified message
    if (messageId >= 0 && messageId < currentMessages.length) {
      currentMessages[messageId].likes += 1;
      messages.set(currentMessages);
    }

    return true;
  }

  // Regular contract interaction
  let contractInstance: any;
  messageBoardContract.subscribe((value: any) => {
    contractInstance = value;
  })();

  if (!contractInstance) {
    console.error("No contract instance available for liking message");
    return false;
  }

  let walletProvider: any;
  provider.subscribe(value => {
    walletProvider = value;
  })();

  try {
    // Check if network is correct
    if (walletProvider) {
      const network = await walletProvider.getNetwork();
      console.log("Current network for like operation:", network);

      if (network.chainId !== 10143) {
        console.error(`Wrong network! Connected to ${network.name} (${network.chainId}), need to be on Monad (10143)`);
        throw new Error(`Please connect to Monad network in your wallet (current: ${network.name})`);
      }
    }

    console.log("Attempting to like message:", messageId);
    console.log("Using contract at address:", CONTRACT_ADDRESS);

    const tx = await contractInstance.likeMessage(messageId);
    console.log("Like transaction submitted:", tx.hash);

    const receipt = await tx.wait();
    console.log("Like transaction confirmed:", receipt);

    await fetchMessages();
    return true;
  } catch (error: any) {
    console.error('Error liking message:', error);

    // More detailed error analysis
    if (error.code && error.message) {
      console.error(`Error details - Code: ${error.code}, Message: ${error.message}`);
    }

    // Try to extract deeper error if available
    if (error.error && error.error.message) {
      console.error("Inner error:", error.error.message);
    }

    return false;
  }
}
