// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {SecureChainlinkOracle} from "../src/SecureChainlinkOracle.sol";
import {MockV3Aggregator} from "./mocks/MockV3Aggregator.sol";

contract SecureChainlinkOracleTest is Test {
    SecureChainlinkOracle public oracle;
    MockV3Aggregator public primaryMock;
    MockV3Aggregator public secondaryMock;
    
    uint256 public constant STALE_THRESHOLD = 3600; // 1 hour
    int256 public constant PRIMARY_PRICE = 2000e8;
    int256 public constant SECONDARY_PRICE = 1990e8;

    function setUp() public {
        primaryMock = new MockV3Aggregator(8, PRIMARY_PRICE);
        secondaryMock = new MockV3Aggregator(8, SECONDARY_PRICE);
        oracle = new SecureChainlinkOracle(
            address(primaryMock),
            address(secondaryMock),
            STALE_THRESHOLD
        );
    }

    function test_GetLatestPrice_Primary() public view {
        (int256 price, uint8 decimals) = oracle.getLatestPrice();
        assertEq(price, PRIMARY_PRICE);
        assertEq(decimals, 8);
    }

    function test_Fallback_WhenPrimaryStale() public {
        // Mocking staleness by moving time forward
        uint256 warpTime = block.timestamp + STALE_THRESHOLD + 1;
        vm.warp(warpTime);
        
        // Update secondary so it stays fresh
        secondaryMock.updateRoundData(1, SECONDARY_PRICE, warpTime, 1);
        
        // Primary is stale, should return secondary price
        (int256 price, ) = oracle.getLatestPrice();
        assertEq(price, SECONDARY_PRICE);
    }

    function test_Fallback_WhenPrimaryNegative() public {
        primaryMock.updateAnswer(-1);
        
        (int256 price, ) = oracle.getLatestPrice();
        assertEq(price, SECONDARY_PRICE);
    }

    function test_Revert_WhenBothFail() public {
        vm.warp(block.timestamp + STALE_THRESHOLD + 1);
        // Warp secondary too
        // Secondary round updated time is also old now by nature of block.timestamp
        
        vm.expectRevert(SecureChainlinkOracle.AllPriceFeedsFailed.selector);
        oracle.getLatestPrice();
    }

    function test_Revert_OnInvalidConstructorArgs() public {
        vm.expectRevert(SecureChainlinkOracle.InvalidFeedAddress.selector);
        new SecureChainlinkOracle(address(0), address(secondaryMock), STALE_THRESHOLD);
        
        vm.expectRevert(SecureChainlinkOracle.InvalidThreshold.selector);
        new SecureChainlinkOracle(address(primaryMock), address(secondaryMock), 0);
    }

    function test_Fallback_WhenPrimaryReverts() public {
        primaryMock.setShouldRevert(true);
        
        // Primary reverts, should fall back to secondary
        (int256 price, ) = oracle.getLatestPrice();
        assertEq(price, SECONDARY_PRICE);
    }

    function test_Getters() public view {
        assertEq(oracle.getDecimals(), 8);
        assertEq(oracle.getPriceFeedAddress(), address(primaryMock));
    }
}
