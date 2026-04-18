// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {PythOracle} from "../src/PythOracle.sol";
import {MockPyth} from "./mocks/MockPyth.sol";

contract PythOracleTest is Test {
    PythOracle public oracle;
    MockPyth public mockPyth;
    
    bytes32 public constant PRICE_ID = keccak256("ETH/USD");
    int64 public constant INITIAL_PRICE = 200000000000; // $2000 with 8 decimals (as int64)
    int32 public constant EXPO = -8;

    function setUp() public {
        mockPyth = new MockPyth();
        oracle = new PythOracle(address(mockPyth), PRICE_ID);
        
        mockPyth.setPrice(PRICE_ID, INITIAL_PRICE, 1000, EXPO, block.timestamp);
    }

    function test_GetLatestPrice_Unsafe() public view {
        (int64 price, uint64 conf, int32 expo) = oracle.getLatestPrice();
        assertEq(price, INITIAL_PRICE);
        assertEq(conf, 1000);
        assertEq(expo, EXPO);
    }

    function test_UpdatePrice() public {
        bytes[] memory updateData = new bytes[](1);
        updateData[0] = hex"1234";
        
        uint256 fee = mockPyth.getUpdateFee(updateData);
        oracle.updatePrice{value: fee}(updateData);
        
        // Fee was paid, call successful
    }

    function test_Revert_UpdatePrice_InsufficientFee() public {
        bytes[] memory updateData = new bytes[](1);
        vm.expectRevert(abi.encodeWithSelector(PythOracle.InsufficientUpdateFee.selector, 0, 1));
        oracle.updatePrice{value: 0}(updateData);
    }

    function test_Receive() public {
        (bool success, ) = address(oracle).call{value: 1 ether}("");
        assertTrue(success);
    }
}
