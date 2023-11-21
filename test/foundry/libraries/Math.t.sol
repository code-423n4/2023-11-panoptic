// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {MathHarness} from "./harnesses/MathHarness.sol";
import {Errors} from "@libraries/Errors.sol";
import {LiquidityChunk} from "@types/LiquidityChunk.sol";
import {LiquidityAmounts} from "v3-periphery/libraries/LiquidityAmounts.sol";
import {TickMath} from "v3-core/libraries/TickMath.sol";
import {FullMath} from "v3-core/libraries/FullMath.sol";
import "forge-std/Test.sol";

/**
 * Test the Core Math library using Foundry and Fuzzing.
 *
 * @author Axicon Labs Limited
 */
contract MathTest is Test {
    MathHarness harness;

    function setUp() public {
        harness = new MathHarness();
    }

    function test_Success_toUint128(uint256 toDowncast) public {
        vm.assume(toDowncast <= type(uint128).max);
        assertEq(harness.toUint128(toDowncast), toDowncast);
    }

    function test_Fail_toUint128_Overflow(uint256 toDowncast) public {
        vm.assume(toDowncast > type(uint128).max);
        vm.expectRevert(Errors.CastingError.selector);
        harness.toUint128(toDowncast);
    }

    function test_Success_mulDiv64(uint96 a, uint96 b) public {
        uint256 expectedResult = FullMath.mulDiv(a, b, 2 ** 64);
        uint256 returnedResult = harness.mulDiv64(a, b);

        assertEq(expectedResult, returnedResult);
    }

    function test_Fail_mulDiv64() public {
        uint256 input = type(uint256).max;

        vm.expectRevert();
        harness.mulDiv64(input, input);
    }

    function test_Success_mulDiv192(uint128 a, uint128 b) public {
        uint256 expectedResult = FullMath.mulDiv(a, b, 2 ** 192);
        uint256 returnedResult = harness.mulDiv192(a, b);

        assertEq(expectedResult, returnedResult);
    }

    function test_Fail_mulDiv192() public {
        uint256 input = type(uint256).max;

        vm.expectRevert();
        harness.mulDiv192(input, input);
    }

    function test_Fail_getSqrtRatioAtTick() public {
        int24 x = int24(887273);
        vm.expectRevert();
        harness.getSqrtRatioAtTick(x);
        vm.expectRevert();
        harness.getSqrtRatioAtTick(-x);
    }

    function test_Success_getSqrtRatioAtTick(int24 x) public {
        x = int24(bound(x, int24(-887271), int24(887271)));
        uint160 uniV3Result = TickMath.getSqrtRatioAtTick(x);
        uint160 returnedResult = harness.getSqrtRatioAtTick(x);
        assertEq(uniV3Result, returnedResult);
    }

    function test_Success_getAmount0ForLiquidity(uint128 a) public {
        a = uint128(bound(a, uint128(1), uint128(2 ** 128 - 1)));
        uint256 uniV3Result = LiquidityAmounts.getAmount0ForLiquidity(
            TickMath.getSqrtRatioAtTick(int24(-14)),
            TickMath.getSqrtRatioAtTick(int24(10)),
            a
        );

        uint256 chunk = LiquidityChunk.addLiquidity(uint256(0), a);
        chunk = LiquidityChunk.addTickLower(chunk, int24(-14));
        chunk = LiquidityChunk.addTickUpper(chunk, int24(10));

        uint256 returnedResult = harness.getAmount0ForLiquidity(chunk);

        assertEq(uniV3Result, returnedResult);
    }

    function test_Success_getAmount1ForLiquidity(uint128 a) public {
        uint256 uniV3Result = LiquidityAmounts.getAmount1ForLiquidity(
            TickMath.getSqrtRatioAtTick(int24(-14)),
            TickMath.getSqrtRatioAtTick(int24(10)),
            a
        );

        uint256 chunk = LiquidityChunk.addLiquidity(uint256(0), a);
        chunk = LiquidityChunk.addTickLower(chunk, int24(-14));
        chunk = LiquidityChunk.addTickUpper(chunk, int24(10));

        uint256 returnedResult = harness.getAmount1ForLiquidity(chunk);

        assertEq(uniV3Result, returnedResult);
    }

    function test_Success_getLiquidityForAmount0(uint112 a) public {
        uint256 uniV3Result = LiquidityAmounts.getLiquidityForAmount0(
            TickMath.getSqrtRatioAtTick(int24(-14)),
            TickMath.getSqrtRatioAtTick(int24(10)),
            a
        );

        uint256 chunk = LiquidityChunk.addLiquidity(uint256(0), 0);
        chunk = LiquidityChunk.addTickLower(chunk, int24(-14));
        chunk = LiquidityChunk.addTickUpper(chunk, int24(10));

        uint256 returnedResult = harness.getLiquidityForAmount0(chunk, a);

        assertEq(uniV3Result, returnedResult);
    }

    function test_Success_getLiquidityForAmount1(uint112 a) public {
        uint256 uniV3Result = LiquidityAmounts.getLiquidityForAmount1(
            TickMath.getSqrtRatioAtTick(int24(-14)),
            TickMath.getSqrtRatioAtTick(int24(10)),
            a
        );

        uint256 chunk = LiquidityChunk.addLiquidity(uint256(0), 0);
        chunk = LiquidityChunk.addTickLower(chunk, int24(-14));
        chunk = LiquidityChunk.addTickUpper(chunk, int24(10));

        uint256 returnedResult = harness.getLiquidityForAmount1(chunk, a);

        assertEq(uniV3Result, returnedResult);
    }
}
