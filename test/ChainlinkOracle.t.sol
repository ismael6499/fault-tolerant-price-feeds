// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ChainlinkOracle} from "../src/ChainlinkOracle.sol";
import {MockV3Aggregator} from "./mocks/MockV3Aggregator.sol";

contract ChainlinkOracleTest is Test {
    ChainlinkOracle public oracle;
    MockV3Aggregator public mockAggregator;
    
    int256 public constant INITIAL_PRICE = 2000e8; // $2000 with 8 decimals
    uint8 public constant DECIMALS = 8;

    function setUp() public {
        mockAggregator = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        oracle = new ChainlinkOracle(address(mockAggregator));
    }

    function test_GetLatestPrice() public view {
        int256 price = oracle.getLatestPrice();
        assertEq(price, INITIAL_PRICE);
    }

    function test_GetRoundData() public view {
        (
            uint80 roundId,
            int256 price,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = oracle.getRoundData();

        assertEq(price, INITIAL_PRICE);
        assertEq(roundId, mockAggregator.latestRound());
        assertEq(updatedAt, mockAggregator.latestTimestamp());
        assertEq(startedAt, updatedAt);
        assertEq(answeredInRound, roundId);
    }

    function test_PriceUpdate() public {
        int256 newPrice = 2100e8;
        mockAggregator.updateAnswer(newPrice);
        
        int256 price = oracle.getLatestPrice();
        assertEq(price, newPrice);
    }
}
