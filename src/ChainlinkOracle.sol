// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title Chainlink Oracle Wrapper
 * @author Agustin Acosta
 * @notice Provides a standardized interface to interact with Chainlink Price Feeds.
 * @dev Implements gas-optimized state management using immutable variables.
 */
contract ChainlinkOracle {
    /// @notice The Chainlink Price Feed interface
    /// @dev Immutable to save gas by storing in bytecode instead of storage.
    AggregatorV3Interface internal immutable priceFeed;

    /**
     * @notice Initializes the contract with an existing Chainlink Aggregator address.
     * @param _priceFeed The address of the Chainlink AggregatorV3Interface contract.
     */
    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    /**
     * @notice Returns the latest price from the aggregator.
     * @dev Uses latestRoundData to ensure compatibility with modern aggregator interfaces.
     * @return price The latest asset price with the feed's decimals.
     */
    function getLatestPrice() external view returns (int256 price) {
        (
            , 
            price,
            ,
            ,
            
        ) = priceFeed.latestRoundData();
    }

    /**
     * @notice Returns comprehensive round data for historical or multifaceted queries.
     * @return roundId The unique identifier for this round.
     * @return price The price data for this round.
     * @return startedAt Timestamp when the round started.
     * @return updatedAt Timestamp when the round was last updated.
     * @return answeredInRound The round ID in which the answer was computed.
     */
    function getRoundData() external view returns (
        uint80 roundId,
        int256 price,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return priceFeed.latestRoundData();
    }
}