<script lang="ts">
  import { NETWORKS, switchNetwork, type NetworkKey } from '../config/blockchain';
  import { networkName, isConnected } from '../stores/wallet';

  let isOpen = false;
  let switchingNetwork = false;
  let error = '';

  // Handle network switch
  async function handleNetworkSwitch(network: NetworkKey) {
    if (!$isConnected) return;

    switchingNetwork = true;
    error = '';

    try {
      const success = await switchNetwork(network);
      if (success) {
        networkName.set(network);
        isOpen = false;
      } else {
        error = `Failed to switch to ${NETWORKS[network]?.name || network}`;
      }
    } catch (err) {
      error = err instanceof Error ? err.message : String(err);
    } finally {
      switchingNetwork = false;
    }
  }
</script>

<div class="relative">
  <button
    class="bg-monad-purple/20 text-monad-purple-light px-3 py-1 rounded-full text-sm flex items-center"
    on:click={() => isOpen = !isOpen}
    disabled={!$isConnected || switchingNetwork}
  >
    <span class="inline-block w-2 h-2 rounded-full bg-green-400 mr-1"></span>
    {NETWORKS[$networkName as NetworkKey]?.name || 'Unknown Network'}
    <svg class="w-4 h-4 ml-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
    </svg>
  </button>

  {#if isOpen}
    <div class="absolute top-full left-0 mt-1 bg-gray-800 rounded-lg shadow-lg z-10 w-48 py-1">
      {#each Object.entries(NETWORKS) as [key, network]}
        <button
          class="w-full text-left px-4 py-2 hover:bg-gray-700 text-sm {$networkName === key ? 'bg-gray-700' : ''}"
          on:click={() => handleNetworkSwitch(key as NetworkKey)}
          disabled={switchingNetwork || $networkName === key}
        >
          <div class="flex items-center">
            <span class="inline-block w-2 h-2 rounded-full {$networkName === key ? 'bg-green-400' : 'bg-gray-400'} mr-2"></span>
            {network.name}
            {#if network.isTestnet}
              <span class="ml-1 text-xs bg-yellow-800 text-yellow-300 px-1 rounded">Testnet</span>
            {/if}
          </div>
        </button>
      {/each}
    </div>
  {/if}

  {#if error}
    <div class="absolute top-full left-0 mt-1 bg-red-900 text-white text-xs p-2 rounded-lg z-10">
      {error}
    </div>
  {/if}
</div>