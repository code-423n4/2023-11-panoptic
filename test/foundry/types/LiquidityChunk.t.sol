// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// foundry
import "forge-std/Test.sol";
// internal
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {LiquidityChunkHarness} from "./harnesses/LiquidityChunkHarness.sol";

/**
 * Test Liquidity Chunk using Foundry and Fuzzing.
 *
 * @author Axicon Labs Limited
 */
contract LiquidityChunkTest is Test {
    // harness
    LiquidityChunkHarness harness;

    function setUp() public {
        harness = new LiquidityChunkHarness();
    }

    function test_Success_AddLiq(uint128 y) public {
        uint256 x;

        x = harness.addLiquidity(x, y);
        uint128 z = harness.liquidity(x);

        assertEq(y, z);
    }

    function test_Success_TickLower(int24 y) public {
        uint256 x;

        x = harness.addTickLower(x, y);
        int24 z = harness.tickLower(x);

        assertEq(y, z);
    }

    function test_Success_TickUpper(int24 y) public {
        uint256 x;

        x = harness.addTickUpper(x, y);
        int24 z = harness.tickUpper(x);

        assertEq(y, z);
    }

    function test_Success_AddTicksLiquidity(int24 y, int24 z, uint128 u) public {
        uint256 x;

        x = harness.createChunk(x, y, z, u);

        assertEq(harness.tickLower(x), y);
        assertEq(harness.tickUpper(x), z);
        assertEq(harness.liquidity(x), u);
    }
}
