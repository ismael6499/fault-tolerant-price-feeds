// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PythStructs} from "@pyth-sdk-solidity/PythStructs.sol";

contract MockPyth {
    mapping(bytes32 => PythStructs.Price) public prices;
    uint256 public constant updateFee = 1 wei;

    function setPrice(
        bytes32 id,
        int64 price,
        uint64 conf,
        int32 expo,
        uint256 publishTime
    ) public {
        prices[id] = PythStructs.Price({
            price: price,
            conf: conf,
            expo: expo,
            publishTime: publishTime
        });
    }

    function getPriceUnsafe(bytes32 id) external view returns (PythStructs.Price memory) {
        return prices[id];
    }

    function getPriceNoOlderThan(bytes32 id, uint256 age) external view returns (PythStructs.Price memory) {
        PythStructs.Price memory price = prices[id];
        require(block.timestamp - price.publishTime <= age, "no price available");
        return price;
    }

    function getUpdateFee(bytes[] calldata updateData) external pure returns (uint) {
        return updateData.length * updateFee;
    }

    function updatePriceFeeds(bytes[] calldata updateData) external payable {
        uint required = updateData.length * updateFee;
        require(msg.value >= required, "insufficient fee");
        // Mocking: updateData could contain encoded price updates, but for mocks we just assume the prices were already set or updated.
    }
}
