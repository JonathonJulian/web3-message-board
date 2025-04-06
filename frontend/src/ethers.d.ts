declare module 'ethers' {
  export namespace providers {
    export class Web3Provider {
      constructor(provider: any);
      getSigner(): Signer;
      getNetwork(): Promise<{ chainId: number }>;
    }
    export class JsonRpcProvider {
      constructor(url: string);
    }
  }

  export class Contract {
    constructor(address: string, abi: any, signerOrProvider: any);
    connect(signer: Signer): Contract;
    getMessages(): Promise<any[]>;
    postMessage(content: string): Promise<{ wait(): Promise<any> }>;
    likeMessage(messageId: number): Promise<{ wait(): Promise<any> }>;
  }

  export class Wallet {
    static createRandom(): Wallet;
    connect(provider: providers.JsonRpcProvider): Signer;
  }

  export interface Signer {
    getAddress(): Promise<string>;
  }
}