# SimpleSplitter Project Commands
# Use `just <command>` to run these commands

# Load environment variables from .env file
set dotenv-load

# Default recipe - run tests
default:
    forge test

# Build contracts
build:
    forge build

# Run all tests
test:
    forge test

# Run tests with verbose output
test-verbose:
    forge test -vvv

# Run only unit tests
test-unit:
    forge test --match-contract SimpleSplitterTest

# Run only fork tests
test-fork:
    forge test --match-contract SimpleSplitterForkTest

# Format code
format:
    forge fmt

# Clean build artifacts
clean:
    forge clean

# Deploy MockToken to Arbitrum testnet
deploy-mock-token name symbol:
    forge create src/MockToken.sol:MockToken \
        --broadcast \
        --verify \
        --verifier etherscan \
        --rpc-url arbitrum_sepolia \
        --private-key "$PRIVATE_KEY" \
        --constructor-args "{{name}}" "{{symbol}}"

# Deploy SimpleSplitter to Arbitrum testnet
# Usage: just deploy-splitter <token_address> <recipient1,recipient2,recipient3> <share1,share2,share3>
deploy-splitter token_address recipients shares:
    forge create src/SimpleSplitter.sol:SimpleSplitter \
        --broadcast \
        --rpc-url arbitrum_sepolia \
        --private-key "$PRIVATE_KEY" \
        --constructor-args "{{token_address}}" "[{{recipients}}]" "[{{shares}}]" \
        --verify \
        --etherscan-api-key "$ARBISCAN_API_KEY"

# Generate a new wallet for deployment
generate-wallet:
    cast wallet new

# Get wallet address from private key
wallet-address:
    cast wallet address --private-key "$PRIVATE_KEY"

# Check ETH balance on Arbitrum testnet
check-balance address:
    cast balance {{address}} --rpc-url arbitrum_sepolia

# Show help
help:
    @just --list