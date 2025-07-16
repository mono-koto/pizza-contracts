# SimpleSplitter - PYUSD Token Splitter for Arbitrum

A simplified smart contract for splitting ERC20 tokens (like PYUSD) among multiple recipients based on predefined shares. This project demonstrates smart contract development practices and provides a clean educational example for PYUSD integration on Arbitrum.

## What Does SimpleSplitter Do? 🤔

Think of SimpleSplitter like an automated accountant for splitting money:

**Real-world example**: You and two friends start a pizza delivery business. You agree that:
- You (the founder) get 50% of profits
- Friend A gets 30% of profits
- Friend B gets 20% of profits

Instead of manually calculating splits every day, SimpleSplitter:
1. **Stores** your business income when tokens are sent to it
2. **Calculates** each person's share based on your predefined agreement
3. **Distributes** the tokens to everyone's wallet when someone calls the `distribute()` function

**Why use smart contracts?** No arguments about math, no manual calculations, no trust issues - the code handles the splitting logic transparently and immutably on the blockchain.

**Educational Note**: This project is designed for learning smart contract development. It's not intended for production use without proper security audits.

## Overview

SimpleSplitter eliminates the complexity of factory patterns and upgradeable contracts in favor of a straightforward, constructor-based configuration approach. Each contract instance is configured at deployment with:

- A single ERC20 token address
- An array of recipient addresses  
- Corresponding share weights for each recipient

## Design Decisions

- **Simple Architecture**: No factory pattern, no upgrades - just deploy and use
- **Gas Optimized**: Efficient token distribution with minimal overhead
- **Immutable Configuration**: Recipients and shares set at deployment and can never be changed
- **Comprehensive Testing**: Full unit and fork test coverage
- **Arbitrum Ready**: Configured for Arbitrum testnet deployment

## Before You Start - What You Need to Know 📚

**Time Expectation**: About 60 minutes to go from no smart contract knowledge to a deployed splitter you can test on Arbitrum.

### You Should Be Comfortable With:
- **Basic programming concepts** (variables, functions, if/else statements)
- **Command line/terminal usage** (running commands, navigating directories)
- **Git and GitHub basics** (cloning repositories, basic version control)

### Don't Worry If You're New To:
- **Blockchain and smart contracts** - We'll explain the basics you need
- **Solidity programming language** - The code is well-commented
- **Arbitrum and testnets** - We'll show you what you need to know

### What This Repo Demonstrates:
- A practical smart contract example with real-world use case
- Modern development workflow with Foundry
- Comprehensive testing (unit tests and fork tests)
- Deployment to Arbitrum testnet
- Security patterns for token handling

## Smart Contract Basics 🧠

Before diving in, here are key concepts you'll encounter:

### Core Concepts

**Smart Contract**: A program that runs on the blockchain. Once deployed, it executes automatically according to its code - no human intervention needed.

**ERC20 Token**: A standard for digital tokens (like digital coins). PYUSD is an ERC20 token representing US dollars on the blockchain.

**Immutable**: Once set during deployment, these values can never be changed. This provides security and predictability - no one can alter the rules later.

**Gas**: The fee paid to run operations on the blockchain. Think of it like postage for sending transactions.

### Networks & Testing

**Arbitrum**: A "Layer 2" network that is built on top of Ethereum, but is faster and cheaper to use. 

**Testnet**: A practice version of the blockchain where you can experiment without real money. Perfect for learning!

**Mainnet**: The real blockchain where actual money is involved. We won't touch this in this tutorial, but with a few config changes, you could deploy to mainnet just as easily as testnet.

### Security Additions

**Reentrancy**: A type of attack where your contract calls a function of another contract that maliciously tries to call back into your contract before the first call finishes. SimpleSplitter uses OpenZeppelin's ReentrancyGuard to prevent this.

**SafeERC20**: A library that adds extra safety checks when transferring tokens, preventing common mistakes.

### Development Tools

**Foundry**: Your smart contract development toolkit - compiles, tests, and deploys contracts.

**Solidity**: The programming language for Ethereum smart contracts (similar to JavaScript or C++).

**Arbiscan**: A block explorer for Arbitrum, like Etherscan for Ethereum. It lets you view transactions, contracts, and balances on the Arbitrum network.

## Quick Start

### Prerequisites

You'll need these tools installed on your computer:

#### Required Tools

**Foundry** - Your smart contract development toolkit
- **What it does**: Compiles Solidity code, runs tests, and deploys contracts
- **Install**: Follow the [official installation guide](https://book.getfoundry.sh/getting-started/installation)
- **Verify installation**: Run `forge --version` (should show version number like `forge 0.2.0`)

**just** - Command runner (makes complex commands simple)
- **What it does**: Turns long, complex commands into short, memorable ones like `just test`
- **Install**: Follow the [installation guide](https://github.com/casey/just#installation)
- **Verify installation**: Run `just --version` (should show version number like `just 1.42.0`)

#### Alternative Installation (Optional)

You can use [mise-en-place](https://mise.jdx.dev/) to install both tools automatically if you prefer such an approach. There's already a `mise.toml` file in this repository.

#### Verify Your Setup

Run these commands to make sure everything is installed correctly:

```bash
# Check if tools are installed
forge --version    # Should show: forge 0.2.0 (or similar)
just --version     # Should show: just 1.42.0 (or similar)
git --version      # Should show: git version 2.x.x
```

If any command shows "command not found", revisit the installation guides above.

### Installation

```bash
git clone https://github.com/mono-koto/pyusd-simple-splitter.git
cd pyusd-simple-splitter
forge install
```

### Running Tests

```bash
# Run all tests
just test

# Run with verbose output
just test-verbose

# Run only unit tests
just test-unit

# Run only fork tests (requires RPC access)
just test-fork
```

## Development Setup

### 1. Generate a Deployment Wallet

If you don't have a wallet yet, you can generate a new one using the `just` command:

```bash
# Generate a new wallet
just generate-wallet

# This will output something like:
# Successfully created new keypair.
# Address: 0x1234567890123456789012345678901234567890
# Private key: 0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890
```

### 2. Set Environment Variables

Create a `.env` file or set these environment variables:

```bash
export PRIVATE_KEY="0xYourPrivateKeyHere"
export ARBISCAN_API_KEY="YourArbiscanApiKey"
```

> 🧐 **Security Note:** See how we put the private key in a `.env` file like that? Don't do that with keys you'll use in production or with mainnet. Use a more secure approach like a [keystore with secret](https://getfoundry.sh/cast/reference/cast-wallet-import/), [hardware wallet](https://getfoundry.sh/reference/common/multi-wallet-options-hardware), or a secrets manager.

### 3. Get Arbitrum Testnet ETH

Visit the [Arbitrum Sepolia Faucet](https://faucet.quicknode.com/arbitrum/sepolia) and request testnet ETH for your wallet address.

You can check your balance with:
```bash
just check-balance 0xYourWalletAddress
```

## Deployment Guide

### Deploy MockToken (for testing)

```bash
# Deploy a mock PYUSD-like token
just deploy-mock-token "Mock PYUSD" "MYPYUSD"
```

This will output the deployed contract address. Save this address for the next step.

### Deploy SimpleSplitter

```bash
# Deploy SimpleSplitter with your token and recipients
just deploy-splitter \
  0xYourTokenAddress \
  "0xRecipient1,0xRecipient2,0xRecipient3" \
  "50,30,20"
```

**Example:**
```bash
just deploy-splitter \
  0x1234567890123456789012345678901234567890 \
  "0xAlice123...,0xBob456...,0xCharlie789..." \
  "40,35,25"
```

This creates a splitter where:
- Alice receives 40% of distributed tokens
- Bob receives 35% of distributed tokens  
- Charlie receives 25% of distributed tokens

## Contract Architecture

### SimpleSplitter.sol

The main contract with the following key features:

**Constructor Parameters:**
- `token`: ERC20 token contract address
- `recipients`: Array of recipient addresses
- `shares`: Array of corresponding share weights

**Main Functions:**
- `distribute()`: Distributes current token balance among recipients
- `distributableBalance()`: Returns current distributable token balance
- `calculateRecipientAmount(index)`: Calculates amount for a specific recipient

**View Functions:**
- `token()`: Returns the configured token address
- `recipients(index)`: Returns recipient at index
- `shares(index)`: Returns shares at index
- `totalShares()`: Returns total shares
- `recipientCount()`: Returns number of recipients

### MockToken.sol

A 6-decimal ERC20 token for testing that mimics PYUSD characteristics:

- 6 decimal places (like PYUSD)
- Initial supply of 1M tokens
- Mintable for testing purposes

### ISimpleSplitter.sol

An interface that defines the SimpleSplitter contract's public API. This interface provides several benefits:

**Contract Size Optimization:**
When other contracts need to interact with SimpleSplitter, they can import the lightweight interface instead of the full implementation, significantly reducing their compiled size and deployment costs.

**Clear API Definition:**
The interface serves as a clear contract specification, defining all public functions, events, and errors that external contracts can expect.

**Usage Example:**
```solidity
import {ISimpleSplitter} from "./ISimpleSplitter.sol";

contract MyContract {
    ISimpleSplitter public splitter;
    
    constructor(address splitterAddress) {
        splitter = ISimpleSplitter(splitterAddress);
    }
    
    function triggerDistribution() external {
        // Use the interface to interact with SimpleSplitter
        uint256 balance = splitter.distributableBalance();
        if (balance > 0) {
            splitter.distribute();
        }
    }
}
```

**Interface Functions:**
- All view functions from SimpleSplitter
- `distribute()` function for triggering distributions
- Events: `TokensDistributed`, `RecipientPaid`
- Custom errors for better error handling

## Usage Examples

### Basic Distribution

```solidity
// Assume SimpleSplitter is deployed at splitterAddress
// and has been sent 1000 PYUSD tokens

SimpleSplitter splitter = SimpleSplitter(splitterAddress);

// Check distributable balance
uint256 balance = splitter.getDistributableBalance(); // Returns 1000 * 10^6

// Distribute tokens to all recipients
splitter.distribute();

// Recipients now have tokens according to their shares
```

### Integration Example

```solidity
contract MyContract {
    SimpleSplitter public splitter;
    IERC20 public token;
    
    constructor(address _splitter, address _token) {
        splitter = SimpleSplitter(_splitter);
        token = IERC20(_token);
    }
    
    function distributeRevenue(uint256 amount) external {
        // Transfer tokens to splitter
        token.transfer(address(splitter), amount);
        
        // Trigger distribution
        splitter.distribute();
    }
}
```

## Testing

The project includes comprehensive test coverage:

### Unit Tests (`test/SimpleSplitter.t.sol`)
- Constructor validation
- Distribution logic
- Edge cases and error conditions
- Fuzz testing for various amounts and configurations

### Fork Tests (`test/SimpleSplitter.fork.t.sol`)
- Integration testing against Arbitrum testnet
- Real ERC20 token interaction
- Gas usage validation
- End-to-end distribution scenarios

## Gas Optimization

SimpleSplitter is optimized for gas efficiency:

- **Immutable Configuration**: Recipients and shares stored as immutable arrays
- **Batch Distribution**: All recipients paid in a single transaction
- **Minimal Storage**: No unnecessary state tracking
- **Efficient Loops**: Optimized distribution algorithm

Typical gas usage:
- 3-recipient distribution: ~140k gas
- Single recipient: ~50k gas

## Security Considerations

- **Immutable Configuration**: Recipients and shares cannot be changed after deployment
- **Reentrancy Protection**: Uses OpenZeppelin's ReentrancyGuard
- **Safe Transfers**: Uses SafeERC20 for all token operations
- **Input Validation**: Comprehensive validation in constructor
- **Integer Division**: Remainder tokens stay in contract (can be distributed in future calls)

## Development Commands

We've added a `justfile` for easy command execution. 

```bash
# Test the contract
just test

# Get all available commands
just help
```

## License

MIT License - see LICENSE file for details.

