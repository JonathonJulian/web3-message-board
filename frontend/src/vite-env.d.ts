/// <reference types="svelte" />
/// <reference types="vite/client" />

declare module 'svelte' {
  interface ComponentEvents<T = any> {}
}

declare module 'svelte/store' {
  export function writable<T>(value: T): Writable<T>;
  export interface Writable<T> {
    set(value: T): void;
    update(fn: (value: T) => T): void;
    subscribe(run: (value: T) => void): () => void;
  }
}

declare module 'web3modal' {
  export default class Web3Modal {
    constructor(options: any);
    connect(): Promise<any>;
    clearCachedProvider(): void;
  }
}

// Blockchain provider interface for window.ethereum
interface Window {
  ethereum?: {
    isMetaMask?: boolean;
    request: (request: { method: string; params?: any[] }) => Promise<any>;
    on: (eventName: string, callback: (...args: any[]) => void) => void;
    removeListener: (eventName: string, callback: (...args: any[]) => void) => void;
    selectedAddress?: string;
    chainId?: string;
    isConnected: () => boolean;
  };
}