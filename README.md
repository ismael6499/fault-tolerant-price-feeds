# 🛡️ Fault-Tolerant Price Feeds

![Solidity](https://img.shields.io/badge/Solidity-0.8.24-363636?style=flat-square&logo=solidity)
![Security](https://img.shields.io/badge/Security-Fault_Tolerant-blueviolet?style=flat-square)
![Coverage](https://img.shields.io/badge/Coverage-100%25-brightgreen?style=flat-square)

Resilient smart contract wrappers for integrating decentralized price feeds (Chainlink and Pyth). 

This project evolved from a basic integration workshop into a hardened infrastructure. It focuses on mitigating common oracle attack vectors, ensuring data freshness, and providing seamless fallback mechanisms when external data providers experience outages.

## 🏗 Architecture & Security Features

### 1. Chainlink: Fallback Redundancy
- **Context:** Relying on a single oracle feed creates a single point of failure. Network congestion or deprecation can halt the protocol.
- **Implementation:** The `SecureChainlinkOracle` implements a Primary-Secondary fallback pattern. It uses a `try/catch` block to fetch from the primary aggregator. If the call fails, reverts, or returns stale data, it automatically routes the request to a secondary backup feed.

### 2. Chainlink: Staleness Checks
- **Implementation:** Strict validation of the `updatedAt` timestamp against a predefined `STALE_THRESHOLD`. Prevents the protocol from consuming outdated prices during network outages.

### 3. Pyth: Confidence Interval Validation
- **Context:** During high market volatility, price feeds can widen their spread. Using a median price without checking the confidence interval opens the door to arbitrage attacks.
- **Implementation:** The `SecurePythOracle` validates the ratio between the price and its confidence interval. If the interval exceeds the `MIN_CONFIDENCE_RATIO` (e.g., extreme volatility or low liquidity), the transaction reverts, protecting the protocol's accounting.

### 4. Gas Optimization & State Management
- Replaced all string-based `require` statements with Custom Errors.
- Migrated address state variables to `immutable`, moving them from storage slots directly into the contract bytecode.
- Enforced `external` visibility for data-fetching functions.

## 🧪 Testing & Quality Assurance

The test suite is built with Foundry and achieves 100% coverage across all core contracts.
It includes custom mock contracts (`MockV3Aggregator` and `MockPyth`) to simulate network failures, extreme volatility, and stale timestamps.

To execute the test suite:
```bash
forge test
```

To view the coverage report:
```bash
forge coverage
```

**Coverage Output:**

| File                           | % Lines   | % Statements | % Branches | % Funcs   |
|--------------------------------|-----------|--------------|------------|-----------|
| src/SecureChainlinkOracle.sol  | 100.00%   | 100.00%      | 100.00%    | 100.00%   |
| src/SecurePythOracle.sol       | 100.00%   | 100.00%      | 100.00%    | 100.00%   |