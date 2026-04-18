// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title Secure Chainlink Oracle
 * @author Agustin Acosta
 * @notice Implements advanced validation checks for Chainlink Price Feeds, including staleness and redundancy.
 * @dev Uses the Checks-Effects-Interactions pattern and custom errors for maximum security and gas efficiency.
 */
contract SecureChainlinkOracle {
    /// @notice Primary price feed source
    AggregatorV3Interface public immutable PRIMARY_FEED;
    
    /// @notice Secondary price feed source (fallback)
    AggregatorV3Interface public immutable SECONDARY_FEED;
    
    /// @notice Maximum allowed age for a price update before it is considered stale
    uint256 public immutable STALE_THRESHOLD;

    /// @notice Signal that both price feeds have failed or returned invalid data
    error AllPriceFeedsFailed();
    /// @notice Signal that the provided feed address is zero
    error InvalidFeedAddress();
    /// @notice Signal that the provided staleness threshold is invalid
    error InvalidThreshold();
    /// @notice Signal that a specific feed has returned stale or invalid data
    error FeedValidationFailed(address feed);

    /**
     * @notice Initializes the secure oracle with primary and secondary sources.
     * @param _primaryFeed Address of the primary AggregatorV3Interface.
     * @param _secondaryFeed Address of the secondary AggregatorV3Interface.
     * @param _staleThreshold SECONDS allowed since last update.
     */
    constructor(
        address _primaryFeed,
        address _secondaryFeed,
        uint256 _staleThreshold
    ) {
        if (_primaryFeed == address(0) || _secondaryFeed == address(0)) revert InvalidFeedAddress();
        if (_staleThreshold == 0) revert InvalidThreshold();

        PRIMARY_FEED = AggregatorV3Interface(_primaryFeed);
        SECONDARY_FEED = AggregatorV3Interface(_secondaryFeed);
        STALE_THRESHOLD = _staleThreshold;
    }

    /**
     * @notice Fetches the latest price with fallback logic.
     * @dev Attempts to fetch from primary feed; if stale or failed, falls back to secondary.
     * @return price The validated price.
     * @return decimals The number of decimals of the returned price.
     */
    function getLatestPrice() external view returns (int256 price, uint8 decimals) {
        try PRIMARY_FEED.latestRoundData() returns (
            uint80, int256 _answer, uint256, uint256 _updatedAt, uint80
        ) {
            if (_answer <= 0 || _updatedAt == 0 || block.timestamp - _updatedAt > STALE_THRESHOLD) {
                return _fallbackToSecondary();
            }
            return (_answer, PRIMARY_FEED.decimals());
        } catch {
            return _fallbackToSecondary();
        }
    }

    /**
     * @notice Internal fallback logic for retrieving the secondary price.
     */
    function _fallbackToSecondary() internal view returns (int256 price, uint8 decimals) {
        (
            , int256 _answer, , uint256 _updatedAt, 
        ) = SECONDARY_FEED.latestRoundData();

        if (_answer <= 0 || _updatedAt == 0 || block.timestamp - _updatedAt > STALE_THRESHOLD) {
            revert AllPriceFeedsFailed();
        }
        return (_answer, SECONDARY_FEED.decimals());
    }

    /**
     * @notice Returns the decimal precision of the price feed.
     * @return The number of decimals.
     */
    function getDecimals() external view returns (uint8) {
        return PRIMARY_FEED.decimals();
    }

    /**
     * @notice Returns the address of the primary price feed.
     * @return The feed address.
     */
    function getPriceFeedAddress() external view returns (address) {
        return address(PRIMARY_FEED);
    }
}
