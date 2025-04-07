<script lang="ts">
  import { onMount } from 'svelte';
  import {
    wallet,
    isConnected,
    isSimulated,
    messages,
    connectWallet,
    connectSimulatedWallet,
    disconnectWallet,
    fetchMessages,
    postMessage,
    likeMessage
  } from './lib/stores/wallet';
  import { clearProfile } from './lib/stores/profile';
  import MonadLogo from './lib/components/MonadLogo.svelte';
  import ErrorAlert from './lib/components/ErrorAlert.svelte';
  import ProfileCard from './lib/components/ProfileCard.svelte';
  import './app.css';

  // Import the contract address from wallet store
  import { CONTRACT_ADDRESS } from './lib/stores/wallet';

  let newMessage = '';
  let isPosting = false;
  let isLiking: Record<number, boolean> = {};
  let errorMessage = '';
  let showError = false;
  let isLoadingMessages = false;
  let activeTab = 'messages'; // 'messages' or 'profile'

  // Format timestamp to human-readable date
  function formatDate(timestamp: number): string {
    return new Date(timestamp * 1000).toLocaleString();
  }

  // Short address format
  function shortenAddress(address: string): string {
    return `${address.slice(0, 6)}...${address.slice(-4)}`;
  }

  // Handle connect wallet
  async function handleConnect() {
    try {
      await connectWallet();
      if ($isConnected) {
        loadMessages();
      }
    } catch (error) {
      errorMessage = `Failed to connect wallet: ${error instanceof Error ? error.message : String(error)}`;
      showError = true;
    }
  }

  // Enhanced simulated wallet connection
  async function handleSimulatedConnect() {
    try {
      const result = await connectSimulatedWallet();
      console.log("Simulated wallet connection result:", result);
    } catch (error) {
      console.error("Frontend error connecting simulated wallet:", error);
      errorMessage = `Failed to connect simulated wallet: ${error instanceof Error ? error.message : String(error)}`;
      showError = true;
    }
  }

  // Handle disconnect
  function handleDisconnect() {
    disconnectWallet();
    clearProfile(); // Also clear profile data on disconnect
  }

  // Handle post message
  async function handlePostMessage() {
    if (!newMessage.trim() || isPosting) return;

    isPosting = true;
    try {
      const success = await postMessage(newMessage);
      if (success) {
        newMessage = '';
      } else {
        throw new Error("Failed to post message");
      }
    } catch (error) {
      errorMessage = `Error posting message: ${error instanceof Error ? error.message : String(error)}`;
      showError = true;
    } finally {
      isPosting = false;
    }
  }

  // Handle like message
  async function handleLikeMessage(index: number) {
    if (isLiking[index]) return;

    isLiking[index] = true;
    try {
      await likeMessage(index);
    } catch (error) {
      errorMessage = `Error liking message: ${error instanceof Error ? error.message : String(error)}`;
      showError = true;
    } finally {
      isLiking[index] = false;
    }
  }

  // Load messages with loading state
  async function loadMessages() {
    isLoadingMessages = true;
    try {
      await fetchMessages();
    } catch (error) {
      console.error("Error loading messages:", error);
    } finally {
      isLoadingMessages = false;
    }
  }

  // Check if backend is reachable
  async function checkBackendConnection() {
    try {
      // Check API endpoint
      console.log("Checking API endpoint...");
      const apiResponse = await fetch('/api/messages');
      if (!apiResponse.ok) {
        throw new Error(`API HTTP error ${apiResponse.status}: ${apiResponse.statusText}`);
      }
      console.log("API endpoint is reachable:", apiResponse.status);

      // Check Monad RPC endpoint
      console.log("Checking Monad RPC endpoint...");
      const rpcResponse = await fetch('https://arbitrum-sepolia.infura.io/v3/95267af4ac9947e488119d2052311552', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          jsonrpc: '2.0',
          method: 'eth_chainId',
          params: [],
          id: 1
        })
      });

      if (!rpcResponse.ok) {
        throw new Error(`RPC HTTP error ${rpcResponse.status}: ${rpcResponse.statusText}`);
      }

      const rpcData = await rpcResponse.json();
      console.log("RPC endpoint response:", rpcData);

      if (rpcData.error) {
        throw new Error(`RPC error: ${rpcData.error.message || JSON.stringify(rpcData.error)}`);
      }

      console.log("Backend connection check successful");
    } catch (error) {
      console.error("Backend connection check failed:", error);

      // Specific error messages for different error cases
      if (error instanceof Error) {
        if (error.message.includes('405')) {
          errorMessage = 'Backend API error: Method Not Allowed (405). The backend server is running but might not support all necessary methods.';
        } else if (error.message.includes('Failed to fetch') || error.message.includes('NetworkError')) {
          errorMessage = 'Cannot connect to backend server. Please make sure the Go backend server is running on port 8080.';
        } else if (error.message.includes('RPC error')) {
          errorMessage = error.message + '. The blockchain RPC endpoint is not responding correctly.';
        } else {
          errorMessage = `Backend connection error: ${error.message}`;
        }
      } else {
        errorMessage = `Backend connection error: ${String(error)}`;
      }

      showError = true;
    }
  }

  onMount(() => {
    // Check backend connection
    checkBackendConnection();

    // Auto-connect if cached provider exists
    if (typeof window !== 'undefined' && window.localStorage.getItem('WEB3_CONNECT_CACHED_PROVIDER')) {
      handleConnect();
    }
  });
</script>

<div class="container mx-auto px-4 py-8 max-w-4xl">
  <header class="mb-8 flex flex-col items-center">
    <div class="flex justify-center mb-4">
      <MonadLogo size={60} />
    </div>
    <h1 class="text-4xl font-bold text-center mb-2 gradient-text">Monad Message Board</h1>
    <p class="text-center text-gray-400 mb-4">
      A decentralized message board on the blockchain
    </p>

    <!-- Network badge -->
    <div class="bg-yellow-900/30 border border-yellow-700/50 text-yellow-400 px-4 py-2 rounded-lg text-sm text-center mb-6">
      Running on Monad (Chain ID: 10143)
    </div>

    <!-- Wallet section -->
    {#if $isConnected}
      <div class="flex flex-col sm:flex-row items-center gap-2 mb-6">
        <span class="bg-monad-purple/20 text-monad-purple-light px-4 py-2 rounded-lg text-sm flex items-center">
          {#if $isSimulated}
            <span class="inline-block w-2 h-2 rounded-full bg-yellow-400 mr-2"></span>
            Simulated Wallet:
          {:else}
            <span class="inline-block w-2 h-2 rounded-full bg-green-400 mr-2"></span>
            Connected Wallet:
          {/if}
          <span class="font-mono ml-1">{shortenAddress($wallet || '')}</span>
        </span>
        <button
          class="btn-danger px-4 py-2 rounded-lg"
          on:click={handleDisconnect}
        >
          Disconnect
        </button>
      </div>

      <!-- Navigation tabs -->
      <div class="flex border-b border-gray-800 mb-8">
        <button
          class={`px-4 py-3 font-medium text-sm ${activeTab === 'messages' ? 'text-monad-purple-light border-b-2 border-monad-purple-light' : 'text-gray-400 hover:text-gray-300'}`}
          on:click={() => activeTab = 'messages'}
        >
          <div class="flex items-center">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-5 h-5 mr-2">
              <path fill-rule="evenodd" d="M4.804 21.644A6.707 6.707 0 006 21.75a6.721 6.721 0 003.583-1.029c.774.182 1.584.279 2.417.279 5.322 0 9.75-3.97 9.75-9 0-5.03-4.428-9-9.75-9s-9.75 3.97-9.75 9c0 2.409 1.025 4.587 2.674 6.192.232.226.277.428.254.543a3.73 3.73 0 01-.814 1.686.75.75 0 00.44 1.223zM8.25 10.875a1.125 1.125 0 100 2.25a1.125 1.125 0 000-2.25zM10.875 12a1.125 1.125 0 112.25 0 1.125 1.125 0 01-2.25 0zm4.875-1.125a1.125 1.125 0 100 2.25 1.125 1.125 0 000-2.25z" clip-rule="evenodd" />
            </svg>
            Messages
          </div>
        </button>
        <button
          class={`px-4 py-3 font-medium text-sm ${activeTab === 'profile' ? 'text-monad-purple-light border-b-2 border-monad-purple-light' : 'text-gray-400 hover:text-gray-300'}`}
          on:click={() => activeTab = 'profile'}
        >
          <div class="flex items-center">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-5 h-5 mr-2">
              <path fill-rule="evenodd" d="M7.5 6a4.5 4.5 0 119 0 4.5 4.5 0 01-9 0zM3.751 20.105a8.25 8.25 0 0116.498 0 .75.75 0 01-.437.695A18.683 18.683 0 0112 22.5c-2.786 0-5.433-.608-7.812-1.7a.75.75 0 01-.437-.695z" clip-rule="evenodd" />
            </svg>
            Profile
          </div>
        </button>
      </div>
    {:else}
      <div class="flex flex-col items-center gap-3 mb-6">
        <p class="text-yellow-400 mb-2">Connect your wallet to interact with the message board</p>
        <div class="flex flex-col sm:flex-row gap-2">
          <button
            class="btn-primary px-6 py-2 rounded-lg flex items-center justify-center"
            on:click={handleConnect}
          >
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-5 h-5 mr-2">
              <path d="M21 6.375c0 2.692-4.03 4.875-9 4.875S3 9.067 3 6.375 7.03 1.5 12 1.5s9 2.183 9 4.875z" />
              <path d="M12 12.75c2.685 0 5.19-.586 7.078-1.609a8.283 8.283 0 001.897-1.384c.016.121.025.244.025.368C21 12.817 16.97 15 12 15s-9-2.183-9-4.875c0-.124.009-.247.025-.368a8.285 8.285 0 001.897 1.384C6.809 12.164 9.315 12.75 12 12.75z" />
              <path d="M12 16.5c2.685 0 5.19-.586 7.078-1.609a8.282 8.282 0 001.897-1.384c.016.121.025.244.025.368 0 2.692-4.03 4.875-9 4.875s-9-2.183-9-4.875c0-.124.009-.247.025-.368a8.284 8.284 0 001.897 1.384C6.809 15.914 9.315 16.5 12 16.5z" />
              <path d="M12 20.25c2.685 0 5.19-.586 7.078-1.609a8.282 8.282 0 001.897-1.384c.016.121.025.244.025.368 0 2.692-4.03 4.875-9 4.875s-9-2.183-9-4.875c0-.124.009-.247.025-.368a8.284 8.284 0 001.897 1.384C6.809 19.664 9.315 20.25 12 20.25z" />
            </svg>
            Connect Real Wallet
          </button>
          <button
            class="btn-secondary px-6 py-2 rounded-lg flex items-center justify-center"
            on:click={handleSimulatedConnect}
          >
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-5 h-5 mr-2">
              <path d="M4.5 3.75a3 3 0 00-3 3v.75h21v-.75a3 3 0 00-3-3h-15z" />
              <path fill-rule="evenodd" d="M22.5 9.75h-21v7.5a3 3 0 003 3h15a3 3 0 003-3v-7.5zm-18 3.75a.75.75 0 01.75-.75h6a.75.75 0 010 1.5h-6a.75.75 0 01-.75-.75zm.75 2.25a.75.75 0 000 1.5h3a.75.75 0 000-1.5h-3z" clip-rule="evenodd" />
            </svg>
            Use Demo Wallet
          </button>
        </div>
      </div>
    {/if}
  </header>

  <main>
    {#if $isConnected}
      {#if activeTab === 'messages'}
        <!-- Post message section -->
        <div class="mb-8">
          <div class="card p-6 mb-4 border border-gray-800 rounded-lg shadow-lg">
            <h2 class="text-xl font-semibold mb-4 text-white flex items-center">
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-5 h-5 mr-2 text-monad-purple-light">
                <path fill-rule="evenodd" d="M12 2.25c-5.385 0-9.75 4.365-9.75 9.75s4.365 9.75 9.75 9.75 9.75-4.365 9.75-9.75S17.385 2.25 12 2.25zM12.75 9a.75.75 0 00-1.5 0v2.25H9a.75.75 0 000 1.5h2.25V15a.75.75 0 001.5 0v-2.25H15a.75.75 0 000-1.5h-2.25V9z" clip-rule="evenodd" />
              </svg>
              Post a New Message
            </h2>
            <div class="flex flex-col gap-3">
              <textarea
                bind:value={newMessage}
                class="input min-h-[100px] resize-none border border-gray-700 bg-gray-900 rounded-lg p-3 focus:border-monad-purple transition"
                placeholder="What's on your mind? Your message will be posted to the blockchain..."
              ></textarea>
              <button
                class="btn-primary py-3 rounded-lg font-medium flex items-center justify-center"
                on:click={handlePostMessage}
                disabled={!newMessage.trim() || isPosting}
              >
                {#if isPosting}
                  <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                    <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  Posting to Blockchain...
                {:else}
                  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-5 h-5 mr-2">
                    <path d="M3.478 2.405a.75.75 0 00-.926.94l2.432 7.905H13.5a.75.75 0 010 1.5H4.984l-2.432 7.905a.75.75 0 00.926.94 60.519 60.519 0 0018.445-8.986.75.75 0 000-1.218A60.517 60.517 0 003.478 2.405z" />
                  </svg>
                  Post Message
                {/if}
              </button>
            </div>
          </div>
        </div>

        <!-- Messages section -->
        <div>
          <h2 class="text-xl font-semibold mb-4 text-white flex items-center">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-5 h-5 mr-2 text-monad-purple-light">
              <path fill-rule="evenodd" d="M4.804 21.644A6.707 6.707 0 006 21.75a6.721 6.721 0 003.583-1.029c.774.182 1.584.279 2.417.279 5.322 0 9.75-3.97 9.75-9 0-5.03-4.428-9-9.75-9s-9.75 3.97-9.75 9c0 2.409 1.025 4.587 2.674 6.192.232.226.277.428.254.543a3.73 3.73 0 01-.814 1.686.75.75 0 00.44 1.223zM8.25 10.875a1.125 1.125 0 100 2.25a1.125 1.125 0 000-2.25zM10.875 12a1.125 1.125 0 112.25 0 1.125 1.125 0 01-2.25 0zm4.875-1.125a1.125 1.125 0 100 2.25 1.125 1.125 0 000-2.25z" clip-rule="evenodd" />
            </svg>
            Messages
          </h2>

          {#if isLoadingMessages}
            <div class="space-y-4">
              {#each Array(3) as _}
                <div class="card p-4 border border-gray-800 rounded-lg animate-pulse">
                  <div class="flex justify-between">
                    <div class="h-4 bg-gray-700 rounded w-1/4"></div>
                    <div class="h-4 bg-gray-700 rounded w-12"></div>
                  </div>
                  <div class="h-4 bg-gray-700 rounded w-3/4 mt-4"></div>
                  <div class="h-4 bg-gray-700 rounded w-1/2 mt-2"></div>
                </div>
              {/each}
            </div>
          {:else if $messages.length > 0}
            <div class="space-y-4">
              {#each $messages as message, i}
                <div class="card p-5 border border-gray-800 rounded-lg transition-all duration-200 hover:border-gray-700">
                  <div class="flex justify-between items-start">
                    <div class="text-sm text-gray-400 mb-2 flex items-center">
                      <span class="font-mono text-monad-purple-light">{shortenAddress(message.sender)}</span>
                      <span class="mx-2 text-gray-600">•</span>
                      <span class="text-gray-500">{formatDate(message.timestamp)}</span>
                    </div>
                    <button
                      class="flex items-center gap-1 text-sm text-gray-400 hover:text-monad-purple-light transition rounded-full px-2 py-1 hover:bg-monad-purple/10"
                      on:click={() => handleLikeMessage(i)}
                      disabled={isLiking[i]}
                    >
                      {#if isLiking[i]}
                        <svg class="animate-pulse h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 10h4.764a2 2 0 011.789 2.894l-3.5 7A2 2 0 0115.263 21h-4.017c-.163 0-.326-.02-.485-.06L7 20m7-10V5a2 2 0 00-2-2h-.095c-.5 0-.905.405-.905.905 0 .714-.211 1.412-.608 2.006L7 11v9m7-10h-2M7 20H5a2 2 0 01-2-2v-6a2 2 0 012-2h2.5" />
                        </svg>
                      {:else}
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-5 h-5">
                          <path d="M7.493 18.75c-.425 0-.82-.236-.975-.632A7.48 7.48 0 016 15.375c0-1.75.599-3.358 1.602-4.634.151-.192.373-.309.6-.397.473-.183.89-.514 1.212-.924a9.042 9.042 0 012.861-2.4c.723-.384 1.35-.956 1.653-1.715a4.498 4.498 0 00.322-1.672V3a.75.75 0 01.75-.75 2.25 2.25 0 012.25 2.25c0 1.152-.26 2.243-.723 3.218-.266.558.107 1.282.725 1.282h3.126c1.026 0 1.945.694 2.054 1.715.045.422.068.85.068 1.285a11.95 11.95 0 01-2.649 7.521c-.388.482-.987.729-1.605.729H14.23c-.483 0-.964-.078-1.423-.23l-3.114-1.04a4.501 4.501 0 00-1.423-.23h-.777zM2.331 10.977a11.969 11.969 0 00-.831 4.398 12 12 0 00.52 3.507c.26.85 1.084 1.368 1.973 1.368H4.9c.445 0 .72-.498.523-.898a8.963 8.963 0 01-.924-3.977c0-1.708.476-3.305 1.302-4.666.245-.403-.028-.959-.5-.959H4.25c-.832 0-1.612.453-1.918 1.227z" />
                        </svg>
                      {/if}
                      <span class="font-medium">{message.likes}</span>
                    </button>
                  </div>
                  <p class="mt-2 whitespace-pre-wrap text-white">{message.content}</p>
                </div>
              {/each}
            </div>
          {:else}
            <div class="card p-8 text-center border border-gray-800 rounded-lg">
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-12 h-12 mx-auto mb-4 text-gray-600">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 20.25c4.97 0 9-3.694 9-8.25s-4.03-8.25-9-8.25S3 7.444 3 12c0 2.104.859 4.023 2.273 5.48.432.447.74 1.04.586 1.641a4.483 4.483 0 01-.923 1.785A5.969 5.969 0 006 21c1.282 0 2.47-.402 3.445-1.087.81.22 1.668.337 2.555.337z" />
              </svg>
              <p class="text-gray-400">No messages yet. Be the first to post!</p>
            </div>
          {/if}
        </div>
      {:else if activeTab === 'profile'}
        <!-- Profile tab -->
        <div>
          <h2 class="text-xl font-semibold mb-4 text-white flex items-center">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-5 h-5 mr-2 text-monad-purple-light">
              <path fill-rule="evenodd" d="M7.5 6a4.5 4.5 0 119 0 4.5 4.5 0 01-9 0zM3.751 20.105a8.25 8.25 0 0116.498 0 .75.75 0 01-.437.695A18.683 18.683 0 0112 22.5c-2.786 0-5.433-.608-7.812-1.7a.75.75 0 01-.437-.695z" clip-rule="evenodd" />
            </svg>
            Your Profile
          </h2>

          <ProfileCard address={$wallet || ''} />
        </div>
      {/if}
    {:else}
      <!-- Not connected state -->
      <div class="card p-8 text-center border border-gray-800 rounded-lg bg-gray-900/50 shadow-xl">
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-16 h-16 mx-auto mb-6 text-gray-600">
          <path stroke-linecap="round" stroke-linejoin="round" d="M20.25 6.375c0 2.278-3.694 4.125-8.25 4.125S3.75 8.653 3.75 6.375m16.5 0c0-2.278-3.694-4.125-8.25-4.125S3.75 4.097 3.75 6.375m16.5 0v11.25c0 2.278-3.694 4.125-8.25 4.125s-8.25-1.847-8.25-4.125V6.375m16.5 0v3.75m-16.5-3.75v3.75m16.5 0v3.75C20.25 16.153 16.556 18 12 18s-8.25-1.847-8.25-4.125v-3.75m16.5 0c0 2.278-3.694 4.125-8.25 4.125s-8.25-1.847-8.25-4.125" />
        </svg>
        <div class="space-y-4">
          <h3 class="text-xl font-semibold text-white">Welcome to the Message Board</h3>
          <p class="text-gray-400 mb-2">Connect your wallet to view and post messages</p>
          <div class="bg-yellow-900/30 border border-yellow-700/50 text-yellow-400 px-4 py-3 rounded-lg text-sm inline-block">
            <p class="font-medium">Network Requirements</p>
            <p class="mt-1">This app requires Monad (Chain ID: 10143)</p>
          </div>
        </div>
      </div>
    {/if}
  </main>

  <footer class="mt-12 text-center text-gray-500 text-sm border-t border-gray-800 pt-6">
    <div class="flex flex-col items-center justify-center gap-2">
      <div class="flex items-center">
        <span>Built on</span>
        <span class="text-monad-purple-light font-medium mx-1">Monad</span>
        <span class="text-gray-600 mx-1">•</span>
        <span>Contract deployed on</span>
        <span class="text-yellow-400 font-medium ml-1">Monad</span>
      </div>
      <div class="text-xs text-gray-600 font-mono">{CONTRACT_ADDRESS}</div>
    </div>
  </footer>
</div>

<ErrorAlert message={errorMessage} bind:visible={showError} type="error" />
