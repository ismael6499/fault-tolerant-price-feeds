# 🧿 Oracle Integration Workshop

![Solidity](https://img.shields.io/badge/Solidity-0.8.25-363636?style=flat-square&logo=solidity)
![DeFi](https://img.shields.io/badge/DeFi-Oracles-blueviolet?style=flat-square)
![Status](https://img.shields.io/badge/Status-Verified-brightgreen?style=flat-square)

A professional project focused on implementing decentralized oracle integrations using Chainlink and Pyth Network.

This repository demonstrates how to build robust wrappers and fallback mechanisms, focusing on common risks like price manipulation and data staleness.

---

## 🏗 Architecture & Safety

### 1. Price Redundancy (Fallback)
- **Context:** Dependency on a single oracle provider creates a point of failure.
- **Implementation:** The `SecureChainlinkOracle` implements a primary-secondary provider logic. If the primary feed fails validation, the system switches to a secondary aggregator to maintain accurate valuations.

### 2. Confidence & Precision (Pyth Optimization)
- **Context:** Volatile market conditions can lead to wider price gaps.
- **Implementation:** The `SecurePythOracle` utilizes Pyth's confidence interval data. We enforce a `MIN_CONFIDENCE_RATIO` to reject prices during periods of extreme uncertainty.

### 3. Staleness Guardrails
- **Context:** Stale oracle data can lead to incorrect logic or arbitrage.
- **Implementation:** Every retrieval is protected by a `STALE_THRESHOLD` check. For Chainlink, we validate `updatedAt`. For Pyth, we use `getPriceNoOlderThan(MAX_AGE_SECONDS)`, ensuring the data is fresh.

### 4. Gas Management & State Security
- **Implementation:** 
    - **Immutables:** Storage variables are cached as `immutable` to minimize gas costs.
    - **NatSpec:** 100% adherence to NatSpec to allow for better documentation.
    - **Custom Errors:** Usage of specialized error types instead of strings to optimize execution cost.

---

## 📂 Repository Structure

| Module | Contract | Core Purpose |
| :--- | :--- | :--- |
| **Chainlink** | `ChainlinkOracle.sol` | Wrapper for standard AggregatorV3. |
| **Chainlink (Secure)** | `SecureChainlinkOracle.sol` | Fallback implementation. |
| **Pyth** | `PythOracle.sol` | Update and fetcher for Pyth feeds. |
| **Pyth (Secure)** | `SecurePythOracle.sol` | Best-practice validation for confidence and age. |

---

## 🛠 Tech Stack

* **Core:** Solidity `0.8.25`
* **Foundry:** `forge`, `cast` (Industry standard for testing and scripts).
* **Integrations:** Chainlink AggregatorV3, Pyth SDK Solidity.
* **Libraries:** OpenZeppelin Contracts.

---

## 📊 Testing & Performance

The suite focuses on simulating oracle failures, extreme volatility, and staleness scenarios to ensure the defensive logic holds under stress.

To execute the verification suite:
```bash
forge test -vvv
```

**Security Coverage Metrics:**

| File                         | % Lines | % Functions | Status        |
|------------------------------|---------|-------------|---------------|
| `src/SecureChainlinkOracle.sol` | 100%    | 100%        | ✅ Verified |
| `src/SecurePythOracle.sol`      | 100%    | 100%        | ✅ Verified |

---

## 📚 Resources
- [Chainlink Security Docs](https://docs.chain.link/data-feeds/selecting-feeds)
- [Pyth Best Practices](https://docs.pyth.network/consumers/best-practices)
- [Foundry Book](https://book.getfoundry.sh/)
