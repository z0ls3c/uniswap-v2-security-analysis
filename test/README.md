# Uniswap V2 Test Suite

Foundry tests demonstrating core mechanics and security patterns on mainnet fork.

## Prerequisites

### Configure Environment Variables

```bash
# Copy the example env file
cp .env.example .env

# Edit .env and add your RPC URL
nano .env
# OR
code .env

# Example .env content:
# MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY
```

### Install Foundry

If you don't have Foundry installed:

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash

# Restart your terminal, then run:
foundryup

# Verify installation
forge --version
```

### Get a Mainnet RPC URL

You need an Ethereum mainnet RPC endpoint to fork state for testing.

**Option 1: Alchemy (Recommended - Free)**

1. Go to [alchemy.com](https://www.alchemy.com/)
2. Sign up for free account
3. Create new app → Select "Ethereum" → "Mainnet"
4. Copy the HTTPS URL from dashboard
5. Export it: `export MAINNET_RPC_URL="https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY"`

**Option 2: Infura (Free)**

1. Go to [infura.io](https://infura.io/)
2. Sign up and create new project
3. Copy the Ethereum mainnet endpoint
4. Export it: `export MAINNET_RPC_URL="https://mainnet.infura.io/v3/YOUR_KEY"`

**Option 3: Public Endpoint (Rate-Limited)**

```bash
export MAINNET_RPC_URL="https://eth.llamarpc.com"
```

## Setup

```bash
# Clone the repository
git clone https://github.com/z0ls3c/uniswap-v2-security-analysis
cd uniswap-v2-security-analysis

# Install dependencies
forge install

# Set your mainnet RPC URL
export MAINNET_RPC_URL="your-rpc-url-here"

# Run tests
forge test --fork-url $MAINNET_RPC_URL -vv
```

## Test Coverage

### Core Mechanics (`CoreMechanics.t.sol`)

Demonstrates basic Uniswap V2 functionality:

- ✅ **Swap** - ETH → USDC via Router
- ✅ **Add Liquidity** - Provide ETH/USDC liquidity, receive LP tokens
- ✅ **Remove Liquidity** - Burn LP tokens, withdraw ETH/USDC

These tests verify the happy path and serve as baseline for security pattern testing.

### Security Patterns (Planned)

Future test suite covering attack scenarios:

- ⏳ **K Invariant** - Attempts to break `x × y = k` invariant
- ⏳ **Donation Attack** - `MINIMUM_LIQUIDITY` inflation prevention
- ⏳ **Reentrancy** - Lock modifier effectiveness
- ⏳ **Fee-on-Transfer** - Weird token handling with `skim()`/`sync()`
- ⏳ **Oracle Manipulation** - Flash loan price impact

## Running Tests

### Run All Tests

```bash
forge test --fork-url $MAINNET_RPC_URL -vv
```

### Run a Single Test

```bash
# Swap test
forge test --match-test test_SwapETHForUSDC --fork-url $MAINNET_RPC_URL -vvv

# Add liquidity test
forge test --match-test test_AddLiquidity --fork-url $MAINNET_RPC_URL -vvv

# Remove liquidity test
forge test --match-test test_RemoveLiquidity --fork-url $MAINNET_RPC_URL -vvv
```

### Run by Contract

```bash
# All CoreMechanics tests
forge test --match-contract CoreMechanics --fork-url $MAINNET_RPC_URL -vv

# Useful when you have multiple test contracts (future security pattern tests)
```

### Verbosity Options

Control how much output you see:

- `-v` — Test results only
- `-vv` — + `console.log` output
- `-vvv` — + execution traces  
- `-vvvv` — + setup traces
- `-vvvvv` — + internal calls (full debug mode)

```bash
# Example: Full trace for debugging swap
forge test --match-test test_SwapETHForUSDC --fork-url $MAINNET_RPC_URL -vvvvv
```

### Additional Options

```bash
# Gas report
forge test --fork-url $MAINNET_RPC_URL --gas-report

# Watch mode (re-run on file changes)
forge test --fork-url $MAINNET_RPC_URL --watch

# No fork (will fail - showing for reference)
forge test -vv
```

## Expected Output

```bash
Running 3 tests for test/CoreMechanics.t.sol:CoreMechanics
[PASS] test_AddLiquidity() (gas: ~250000)
[PASS] test_RemoveLiquidity() (gas: ~300000)
[PASS] test_SwapETHForUSDC() (gas: ~150000)
Test result: ok. 3 passed; 0 failed; finished in 2.34s
```

## Structure

```bash
test/
├── CoreMechanics.t.sol      # Basic functionality tests
├── interfaces/
│   └── IUniswapV2.sol       # Router, Factory, ERC20 interfaces
└── README.md                # This file
```

## Troubleshooting

**"Error: Failed to get account" or "Error: Invalid project ID"**

- Your RPC URL is incorrect or expired
- Get a new one from Alchemy/Infura
- Or try the public endpoint: `https://eth.llamarpc.com`

**"Error: Could not find artifact"**

- Run `forge install` first
- Make sure you're in repo root

**Tests timeout or are very slow**

- Free RPC endpoints are rate-limited
- Consider upgrading to paid Alchemy tier
- Or use local archive node (advanced)

## Additional Foundry Commands

```bash
# Format code
forge fmt

# Build contracts (not needed for tests-only repo)
forge build

# Generate gas snapshots
forge snapshot

# Get help
forge test --help
```

## Learn More

- [Foundry Book](https://book.getfoundry.sh/)
- [Foundry GitHub](https://github.com/foundry-rs/foundry)
- [Uniswap V2 Docs](https://docs.uniswap.org/contracts/v2/overview)