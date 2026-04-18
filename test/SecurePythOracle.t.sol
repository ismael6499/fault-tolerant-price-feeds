// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {SecurePythOracle} from "../src/SecurePythOracle.sol";
import {MockPyth} from "./mocks/MockPyth.sol";

contract SecurePythOracleTest is Test {
    SecurePythOracle public oracle;
    MockPyth public mockPyth;
    
    bytes32 public constant PRICE_ID = keccak256("ETH/USD");
    int64 public constant INITIAL_PRICE = 200000000000;
    int32 public constant EXPO = -8;

    function setUp() public {
        vm.warp(10000); // Prevent underflow in staleness tests
        mockPyth = new MockPyth();
        oracle = new SecurePythOracle(address(mockPyth), PRICE_ID);
        
        mockPyth.setPrice(PRICE_ID, INITIAL_PRICE, 100, EXPO, block.timestamp);
    }

    function test_GetLatestPrice_Success() public {
        bytes[] memory updateData = new bytes[](0);
        (int64 price, uint64 confidence, int32 exponent) = oracle.getLatestPrice(updateData);
        
        assertEq(price, INITIAL_PRICE);
        assertEq(confidence, 100);
        assertEq(exponent, EXPO);
    }

    function test_Revert_WhenPriceNegative() public {
        mockPyth.setPrice(PRICE_ID, -1, 100, EXPO, block.timestamp);
        bytes[] memory updateData = new bytes[](0);
        
        vm.expectRevert(SecurePythOracle.InvalidPrice.selector);
        oracle.getLatestPrice(updateData);
    }

    function test_Revert_WhenExpoTooLow() public {
        mockPyth.setPrice(PRICE_ID, INITIAL_PRICE, 100, -20, block.timestamp);
        bytes[] memory updateData = new bytes[](0);
        
        vm.expectRevert(SecurePythOracle.InvalidExponent.selector);
        oracle.getLatestPrice(updateData);
    }

    function test_Revert_WhenConfidenceTooWide() public {
        // Price = 200, Confidence = 4 -> Ratio = 200/4 = 50x.
        // We want Confidence to be huge so Ratio is small.
        // If price is 2000 and confidence is 2001, ratio < 1.
        mockPyth.setPrice(PRICE_ID, INITIAL_PRICE, uint64(uint256(uint64(INITIAL_PRICE)) + 1), EXPO, block.timestamp);
        bytes[] memory updateData = new bytes[](0);
        
        vm.expectRevert(SecurePythOracle.UntrustedPrice.selector);
        oracle.getLatestPrice(updateData);
    }

    function test_Revert_WhenStale() public {
        mockPyth.setPrice(PRICE_ID, INITIAL_PRICE, 100, EXPO, block.timestamp - 3601);
        bytes[] memory updateData = new bytes[](0);
        
        // MockPyth's getPriceNoOlderThan reverts with "no price available"
        vm.expectRevert("no price available");
        oracle.getLatestPrice(updateData);
    }

    function test_Revert_WhenConfidenceIsZero() public {
        mockPyth.setPrice(PRICE_ID, INITIAL_PRICE, 0, EXPO, block.timestamp);
        bytes[] memory updateData = new bytes[](0);
        
        vm.expectRevert(SecurePythOracle.UntrustedPrice.selector);
        oracle.getLatestPrice(updateData);
    }

    function test_Receive() public {
        (bool success, ) = address(oracle).call{value: 1 ether}("");
        assertTrue(success);
    }

    function test_UpdatePrice_Public() public {
        bytes[] memory updateData = new bytes[](1);
        updateData[0] = hex"abcd";
        uint256 fee = mockPyth.getUpdateFee(updateData);
        oracle.updatePrice{value: fee}(updateData);
    }

    function test_Revert_UpdatePrice_InsufficientFee() public {
        bytes[] memory updateData = new bytes[](1);
        vm.expectRevert(abi.encodeWithSelector(SecurePythOracle.InsufficientUpdateFee.selector, 0, 1));
        oracle.updatePrice{value: 0}(updateData);
    }
}
