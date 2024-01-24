# 🍕 PYUSD.pizza Contracts

This is the smart contracts repo for pizza.split, a little protocol + [dApp](/mono-koto/pizza-ui) for splitting ETH and ERC-20s among friends.

This project was created in collaboration with [Garden Labs](https://gardenlabs.xyz) and funded by [PayPal](https://paypal.com/) to explore and demonstrate developer use cases of the [PYUSD ERC-20 stablecoin](https://www.paypal.com/us/digital-wallet/manage-money/crypto/pyusd).

## Dependencies

[Install Foundry](https://book.getfoundry.sh/getting-started/installation).

Clone the repo.

Run `forge install`.

## Configuration

Copy the `.env.example` file to `.env` and fill in your own values.

## Testing

For this project I've gone ahead and just created a Makefile for common build targets. You can run tests with the bare `make` command:

```
make
```

See Foundry docs for more testing options.

## Deployment

Check out the [Makefile](./Makefile) for build/deploy targets. Example:

```
make deploy-sepolia-dryrun
make deploy-sepolia
```

## Private key management

The private key is only used for deployment.

Depending on your development needs and risk tolerance, your key can be managed any way you like. My recommended approach is to use some kind of encrypted key storage. Check out [Foundry's encrypted keystore](https://book.getfoundry.sh/reference/cast/cast-wallet-import), or use something like [1Password's `op` CLI](https://developer.1password.com/docs/cli/get-started/).
