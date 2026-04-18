// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IPyth} from "@pyth-sdk-solidity/IPyth.sol";
import {PythStructs} from "@pyth-sdk-solidity/PythStructs.sol";

/**
 * @title Pyth Oracle Wrapper
 * @author Agustin Acosta
 * @notice Standard interface for reading prices from the Pyth Network.
 * @dev Uses external visibility and immutable state where applicable for gas efficiency.
 */
contract PythOracle {
    /// @notice The Pyth Network contract interface
    IPyth public immutable PYTH_CONTRACT;
    
    /// @notice The Pyth Price ID for the asset (e.g., ETH/USD)
    bytes32 public immutable PRICE_ID;

    /// @notice Error thrown when insufficient fee is sent for price update
    error InsufficientUpdateFee(uint256 sent, uint256 required);

    /**
     * @notice Initializes the Pyth oracle with network-specific parameters.
     * @param _pythContract The address of the IPyth contract.
     * @param _priceId The specific bytes32 ID for the price feed.
     */
    constructor(address _pythContract, bytes32 _priceId) {
        PYTH_CONTRACT = IPyth(_pythContract);
        PRICE_ID = _priceId;
    }

    /**
     * @notice Returns the latest price stored on-chain (unsafe if not updated).
     * @dev This method is "unsafe" because it doesn't check for staleness. Use only for cost-efficient reads.
     * @return price The recorded price.
     * @return confidence Confidence interval.
     * @return exponent Decimal exponent for the price.
     */
    function getLatestPrice() external view returns (int64 price, uint64 confidence, int32 exponent) {
        PythStructs.Price memory _priceData = PYTH_CONTRACT.getPriceUnsafe(PRICE_ID);
        return (_priceData.price, _priceData.conf, _priceData.expo);
    }

    /**
     * @notice Submits a price update to the Pyth network.
     * @dev Requires value in msg.value to pay for the update fee.
     * @param _updateData The encoded update data from the Pyth off-chain service.
     */
    function updatePrice(bytes[] calldata _updateData) external payable {
        uint256 _fee = PYTH_CONTRACT.getUpdateFee(_updateData);
        if (msg.value < _fee) revert InsufficientUpdateFee(msg.value, _fee);
        
        PYTH_CONTRACT.updatePriceFeeds{value: _fee}(_updateData);
    }

    /**
     * @notice Standard receive function to handle accidental ETH transfers or contract logic.
     */
    receive() external payable {}
}
