# Adapted from https://github.com/smartcontractkit/foundry-starter-kit/blob/main/Makefile

# -include .env

# .SILENT:

.PHONY: all test clean 

all: clean update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test 

snapshot :; forge snapshot

slither :; slither ./src 

format :; forge fmt

abi:
	mkdir -p artifacts
	forge inspect PizzaFactory abi > artifacts/PizzaFactory.abi.json && forge inspect Pizza abi > artifacts/Pizza.abi.json

# solhint should be installed globally
lint :; solhint src/**/*.sol && solhint src/*.sol

anvil :; anvil -m 'test test test test test test test test test test test junk'

# use the "@" to hide the command from your shell 
deploy-mainnet :; @forge script script/PizzaFactory.s.sol:DeployPizzaFactory --rpc-url mainnet --private-key ${PRIVATE_KEY} -vvvv

# use the "@" to hide the command from your shell 
deploy-sepolia :; @forge script script/PizzaFactory.s.sol:DeployPizzaFactory --rpc-url sepolia --private-key ${PRIVATE_KEY} -vvvv

# anvil deploy with the default user
deploy-anvil :; @forge script script/PizzaFactory.s.sol:DeployPizzaFactory --rpc-url http://localhost:8545  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast 

# anvil deploy with the default user
deploy-anvil-sample-pizza :; @forge script script/PizzaFactory.s.sol:DeploySamplePizza --rpc-url http://localhost:8545  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast  -vvvv

-include ${FCT_PLUGIN_PATH}/makefile-external