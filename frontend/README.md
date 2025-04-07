# Message Board Frontend

This directory contains the web frontend for the Web3 message board application.

## Overview

The frontend provides a responsive, user-friendly interface for interacting with the blockchain message board, allowing users to:
- View and post messages stored on the blockchain
- Connect their Web3 wallet (MetaMask or other providers)
- Like messages using blockchain transactions
- View real-time updates of message board content

## Technology Stack

- [Svelte](https://svelte.dev/) - UI framework
- [TypeScript](https://www.typescriptlang.org/) - Type-safe JavaScript
- [Tailwind CSS](https://tailwindcss.com/) - Utility-first CSS framework
- [ethers.js](https://docs.ethers.io/) - Blockchain library for Nomad interaction
- [Web3Modal](https://github.com/Web3Modal/web3modal) - Wallet connection library

## Directory Structure

```
frontend/
├── public/            # Static assets
├── src/               # Source code
│   ├── components/    # Reusable UI components
│   ├── lib/           # Shared code and utilities
│   ├── routes/        # Page components
│   ├── stores/        # State management
│   ├── types/         # TypeScript type definitions
│   ├── app.html       # HTML template
│   └── main.js        # Entry point
├── static/            # Static files copied to build
├── svelte.config.js   # Svelte configuration
├── tailwind.config.js # Tailwind configuration
├── package.json       # Dependencies and scripts
└── README.md          # This file
```

## Setup and Running

### Prerequisites
- Node.js 18 or later
- npm or yarn

### Local Development

1. Install dependencies:
   ```bash
   npm install
   # or
   yarn
   ```

2. Start the development server:
   ```bash
   npm run dev
   # or
   yarn dev
   ```

3. Build for production:
   ```bash
   npm run build
   # or
   yarn build
   ```

## Deployment

The frontend is deployed using Ansible as part of the Nginx configuration:

```bash
make ansible-static_site
```

This will:
1. Build the frontend application
2. Copy the built files to the Nginx web root
3. Configure Nginx to serve the static files
4. Set up routing for API requests

## Features

### Web3 Integration
- Wallet connection via Web3Modal
- Transaction signing for posting and liking messages
- Chain detection and network switching
- Gas estimation and transaction management

### Messaging
- View message feed from blockchain
- Create new messages stored on-chain
- Like messages with blockchain transactions
- Real-time updates through blockchain events

### User Interface
- Responsive design for mobile and desktop
- Dark/light theme support
- Accessibility features

## Integration with Nomad Blockchain

The frontend communicates directly with the deployed MessageBoard smart contract on the Nomad blockchain, as well as with the Go API service that provides additional functionality:

- Direct contract interactions for core message board features
- API integration for additional metadata and indexing
- WebSocket connection for real-time Nomad blockchain event updates

## Logging and Monitoring

The frontend includes:
- Error tracking with detailed reports
- Performance monitoring
- User interaction analytics
- Console logging (development) and remote logging (production)

## Browser Compatibility

The application is tested and supported on:
- Chrome (latest 2 versions)
- Firefox (latest 2 versions)
- Safari (latest 2 versions)
- Edge (latest 2 versions)