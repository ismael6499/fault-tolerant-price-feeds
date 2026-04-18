// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IPyth} from "@pyth-sdk-solidity/IPyth.sol";
import {PythStructs} from "@pyth-sdk-solidity/PythStructs.sol";

/**
 * @title Secure Pyth Oracle
 * @author Agustin Acosta
 * @notice Implements Pyth Network best practices for price validation, including confidence intervals and age checks.
 * @dev Enforces strict validation logic during price retrieval.
 */
contract SecurePythOracle {
    /// @notice The Pyth Network contract interface
    IPyth public immutable PYTH_CONTRACT;
    
    /// @notice The Pyth Price ID for the asset
    bytes32 public immutable PRICE_ID;

    /// @notice Maximum acceptable age for a price update (1 hour default)
    uint256 public constant MAX_AGE_SECONDS = 3600;
    
    /// @notice Minimum acceptable decimal exponent for precision safety
    int32 public constant MIN_ACCEPTABLE_EXPO = -18;
    
    /// @notice Minimum ratio between price and confidence interval (100x default)
    uint256 public constant MIN_CONFIDENCE_RATIO = 10000;

    /// @notice Error thrown when price is non-positive
    error InvalidPrice();
    /// @notice Error thrown when decimal exponent is too low
    error InvalidExponent();
    /// @notice Error thrown when confidence interval is too wide
    error UntrustedPrice();
    /// @notice Error thrown when fee is insufficient
    error InsufficientUpdateFee(uint256 sent, uint256 required);

    /**
     * @notice Initializes the secure Pyth oracle.
     * @param _pythContract The IPyth contract address.
     * @param _priceId The specific bytes32 ID for the price feed.
     */
    constructor(address _pythContract, bytes32 _priceId) {
        PYTH_CONTRACT = IPyth(_pythContract);
        PRICE_ID = _priceId;
    }

    /**
     * @notice Updates the price feed and returns a validated price.
     * @dev Atomically updates the feed and performs best-practice validation checks.
     * @param _updateData The encoded update data from Pyth.
     * @return price The validated price.
     * @return confidence The confidence interval.
     * @return exponent The decimal exponent.
     */
    function getLatestPrice(bytes[] calldata _updateData) external payable returns (int64 price, uint64 confidence, int32 exponent) {
        _updatePrice(_updateData);
        
        PythStructs.Price memory _priceData = PYTH_CONTRACT.getPriceNoOlderThan(PRICE_ID, MAX_AGE_SECONDS);
        _validatePrice(_priceData.price, _priceData.conf, _priceData.expo);
        
        return (_priceData.price, _priceData.conf, _priceData.expo);
    }

    /**
     * @notice Updates the Pyth network state with fresh data.
     * @param _updateData The encoded update data.
     */
    function updatePrice(bytes[] calldata _updateData) external payable {
        _updatePrice(_updateData);
    }

    /**
     * @dev Internal update logic to manage fees and msg.value.
     */
    function _updatePrice(bytes[] calldata _updateData) internal {
        uint256 _fee = PYTH_CONTRACT.getUpdateFee(_updateData);
        if (msg.value < _fee) revert InsufficientUpdateFee(msg.value, _fee);
        
        PYTH_CONTRACT.updatePriceFeeds{value: _fee}(_updateData);
    }

    /**
     * @dev Validates price data against institutional-grade security thresholds.
     */
    function _validatePrice(int64 _price, uint64 _confidence, int32 _expo) internal pure {
        if (_price <= 0) revert InvalidPrice();
        if (_expo < MIN_ACCEPTABLE_EXPO) revert InvalidExponent();

        // Check if confidence interval is too wide (must be > MIN_CONFIDENCE_RATIO basis points)
        if (_confidence == 0 || (uint256(uint64(_abs(_price))) * 1e4 / uint256(_confidence)) <= MIN_CONFIDENCE_RATIO) {
            revert UntrustedPrice();
        }
    }

    /**
     * @dev Helper to compute the absolute value of an int64.
     */
    function _abs(int64 _x) internal pure returns (int64) {
        return _x >= 0 ? _x : -_x;
    }

    /**
     * @notice Standard receive function.
     */
    receive() external payable {}
}
