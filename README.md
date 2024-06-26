<!--
parent:
  order: false
-->

<div align="center">
  <h1> DappLink Treasure </h1>
</div>

<div align="center">
  <a href="https://github.com/eniac-x-labs/dapplink-treasure/releases/latest">
    <img alt="Version" src="https://img.shields.io/github/tag/eniac-x-labs/dapplink-treasure.svg" />
  </a>
  <a href="https://github.com/eniac-x-labs/dapplink-treasure/blob/main/LICENSE">
    <img alt="License: Apache-2.0" src="https://img.shields.io/github/license/eniac-x-labs/dapplink-treasure.svg" />
  </a>
</div>

DappLink Treasure Manager Project

## Installation

For prerequisites and detailed build instructions please read the [Installation](https://github.com/eniac-x-labs/dapplink-treasure/) instructions. Once the dependencies are installed, run:

```bash
git submodule update --init --recursive --remote
```

Or check out the latest [release](https://github.com/eniac-x-labs/dapplink-treasure).

##  Test And Depoly

### test
```
forge test 
```

### Depoly

```
forge script script/TreasureManager.s.sol:TreasureManagerScript --rpc-url $RPC_URL --private-key $PRIVKEY

```


## Community


## Contributing

Looking for a good place to start contributing? Check out some [`good first issues`](https://github.com/eniac-x-labs/dapplink-treasure/issues?q=is%3Aopen+is%3Aissue+label%3A%22good+first+issue%22).

For additional instructions, standards and style guides, please refer to the [Contributing](./CONTRIBUTING.md) document.
