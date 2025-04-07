// Network configuration for the application
export type NetworkKey = 'monad' | 'localhost';

export type NetworkConfig = {
  name: string;
  chainId: number;
  rpcUrl: string;
  isTestnet: boolean;
};

export const NETWORKS: Record<NetworkKey, NetworkConfig> = {
  monad: {
    name: 'Monad',
    chainId: 10143,
    rpcUrl: 'https://arbitrum-sepolia.infura.io/v3/95267af4ac9947e488119d2052311552',
    isTestnet: true
  },
  localhost: {
    name: 'Localhost',
    chainId: 1337,
    rpcUrl: 'http://localhost:8545',
    isTestnet: true
  }
};

/**
 * Switch the wallet to a different network
 * @param networkKey Key of the network in the NETWORKS object
 * @returns Success status
 */
export async function switchNetwork(networkKey: NetworkKey): Promise<boolean> {
  if (!window.ethereum || !NETWORKS[networkKey]) return false;

  try {
    const provider = window.ethereum;
    const network = NETWORKS[networkKey];
    const chainIdHex = `0x${network.chainId.toString(16)}`;

    try {
      // Try to switch to the network
      await provider.request({
        method: 'wallet_switchEthereumChain',
        params: [{ chainId: chainIdHex }],
      });
      return true;
    } catch (error: any) {
      // This error code means the chain has not been added to MetaMask
      if (error.code === 4902) {
        await provider.request({
          method: 'wallet_addEthereumChain',
          params: [
            {
              chainId: chainIdHex,
              chainName: network.name,
              rpcUrls: [network.rpcUrl],
              nativeCurrency: {
                name: 'Nomad',
                symbol: 'NMD',
                decimals: 18
              }
            },
          ],
        });
        return true;
      }
      throw error;
    }
  } catch (error) {
    console.error('Error switching network:', error);
    return false;
  }
}