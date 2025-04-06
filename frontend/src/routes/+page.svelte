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
  } from '../lib/stores/wallet';
  import MonadLogo from '../lib/components/MonadLogo.svelte';

  let newMessage = '';
  let isPosting = false;
  let isLiking: Record<number, boolean> = {};

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
    await connectWallet();
    if ($isConnected) {
      await fetchMessages();
    }
  }

  // Handle simulated wallet connect
  async function handleSimulatedConnect() {
    await connectSimulatedWallet();
  }

  // Handle post message
  async function handlePostMessage() {
    if (!newMessage.trim() || isPosting) return;

    isPosting = true;
    const success = await postMessage(newMessage);
    isPosting = false;

    if (success) {
      newMessage = '';
    }
  }

  // Handle like message
  async function handleLikeMessage(index: number) {
    if (isLiking[index]) return;

    isLiking[index] = true;
    await likeMessage(index);
    isLiking[index] = false;
  }

  onMount(() => {
    // Auto-connect if cached provider exists
    if (typeof window !== 'undefined' && window.localStorage.getItem('WEB3_CONNECT_CACHED_PROVIDER')) {
      handleConnect();
    }
  });
</script>

<div class="container mx-auto px-4 py-8 max-w-4xl">
  <header class="mb-8">
    <div class="flex justify-center mb-4">
      <MonadLogo size={60} />
    </div>
    <h1 class="text-4xl font-bold text-center mb-2 gradient-text">Monad Message Board</h1>
    <p class="text-center text-gray-400 mb-6">
      A decentralized message board running on Monad blockchain
    </p>

    <div class="flex justify-center mb-6">
      {#if $isConnected}
        <div class="flex flex-col sm:flex-row items-center gap-2">
          <span class="bg-monad-purple/20 text-monad-purple-light px-3 py-1 rounded-full text-sm">
            {#if $isSimulated}
              <span class="inline-block w-2 h-2 rounded-full bg-yellow-400 mr-1"></span>
              Simulated:
            {:else}
              <span class="inline-block w-2 h-2 rounded-full bg-green-400 mr-1"></span>
              Connected:
            {/if}
            {shortenAddress($wallet || '')}
          </span>
          <button
            class="btn-danger"
            on:click={disconnectWallet}
          >
            Disconnect
          </button>
        </div>
      {:else}
        <div class="flex flex-col sm:flex-row gap-2">
          <button
            class="btn-primary px-6 py-2 rounded-lg"
            on:click={handleConnect}
          >
            Connect Wallet
          </button>
          <button
            class="btn-secondary px-6 py-2 rounded-lg"
            on:click={handleSimulatedConnect}
          >
            Use Simulated Wallet
          </button>
        </div>
      {/if}
    </div>
  </header>

  {#if $isConnected}
    <div class="mb-8">
      <div class="card p-4 mb-4">
        <h2 class="text-xl font-semibold mb-3 text-white">Post a Message</h2>
        <div class="flex flex-col gap-3">
          <textarea
            bind:value={newMessage}
            class="input min-h-[100px]"
            placeholder="What's on your mind?"
          ></textarea>
          <button
            class="btn-primary"
            on:click={handlePostMessage}
            disabled={!newMessage.trim() || isPosting}
          >
            {isPosting ? 'Posting...' : 'Post Message'}
          </button>
        </div>
      </div>
    </div>

    <div>
      <h2 class="text-xl font-semibold mb-4 text-white">Messages</h2>
      {#if $messages.length > 0}
        <div class="space-y-4">
          {#each $messages as message, i}
            <div class="card p-4">
              <div class="flex justify-between items-start">
                <div class="text-sm text-gray-400 mb-1">
                  <span class="font-medium text-monad-purple-light">{shortenAddress(message.sender)}</span>
                  <span class="mx-1">•</span>
                  <span>{formatDate(message.timestamp)}</span>
                </div>
                <button
                  class="flex items-center gap-1 text-sm text-gray-400 hover:text-monad-purple-light transition"
                  on:click={() => handleLikeMessage(i)}
                  disabled={isLiking[i]}
                >
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 10h4.764a2 2 0 011.789 2.894l-3.5 7A2 2 0 0115.263 21h-4.017c-.163 0-.326-.02-.485-.06L7 20m7-10V5a2 2 0 00-2-2h-.095c-.5 0-.905.405-.905.905 0 .714-.211 1.412-.608 2.006L7 11v9m7-10h-2M7 20H5a2 2 0 01-2-2v-6a2 2 0 012-2h2.5" />
                  </svg>
                  <span>{message.likes}</span>
                </button>
              </div>
              <p class="mt-2 whitespace-pre-wrap text-white">{message.content}</p>
            </div>
          {/each}
        </div>
      {:else}
        <div class="card p-8 text-center">
          <p class="text-gray-400">No messages yet. Be the first to post!</p>
        </div>
      {/if}
    </div>
  {:else}
    <div class="card p-8 text-center">
      <p class="text-gray-400 mb-4">Connect your wallet to view and post messages</p>
      <div class="flex flex-col sm:flex-row justify-center gap-2">
        <button
          class="btn-primary"
          on:click={handleConnect}
        >
          Connect Wallet
        </button>
        <button
          class="btn-secondary"
          on:click={handleSimulatedConnect}
        >
          Use Simulated Wallet
        </button>
      </div>
    </div>
  {/if}

  <footer class="mt-12 text-center text-gray-500 text-sm">
    <p>Built on <span class="text-monad-purple-light">Monad</span> • The High-Performance L1 Blockchain</p>
  </footer>
</div>

<style>
  /* Any component-specific styles can go here */
</style>
