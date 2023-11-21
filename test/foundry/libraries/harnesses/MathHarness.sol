// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Math} from "@libraries/Math.sol";

/// @title MathHarness: A harness to expose the Math library for code coverage analysis.
/// @notice Replicates the interface of the Math library, passing through any function calls
/// @author Axicon Labs Limited
contract MathHarness {
    /*****************************************************************
     *
     * GENERAL MATH HELPERS
     *
     *****************************************************************/

    /**
     * @notice Downcast uint256 to uint128. Revert on overflow or underflow.
     * @param toDowncast The uint256 to be downcasted
     * @return the downcasted int (uint128 now).
     */
    function toUint128(uint256 toDowncast) public pure returns (uint128) {
        uint128 r = Math.toUint128(toDowncast);
        return r;
    }

    function mulDiv128(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 result = Math.mulDiv128(a, b);
        return result;
    }

    function mulDiv64(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 result = Math.mulDiv64(a, b);
        return result;
    }

    function mulDiv192(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 result = Math.mulDiv192(a, b);
        return result;
    }

    function getSqrtRatioAtTick(int24 a) public pure returns (uint160) {
        uint160 result = Math.getSqrtRatioAtTick(a);
        return result;
    }

    function getAmount0ForLiquidity(uint256 a) public pure returns (uint256) {
        uint256 result = Math.getAmount0ForLiquidity(a);
        return result;
    }

    function getAmount1ForLiquidity(uint256 a) public pure returns (uint256) {
        uint256 result = Math.getAmount1ForLiquidity(a);
        return result;
    }

    function getLiquidityForAmount0(uint256 c, uint256 a0) public pure returns (uint256) {
        uint256 result = Math.getLiquidityForAmount0(c, a0);
        return result;
    }

    function getLiquidityForAmount1(uint256 c, uint256 a1) public pure returns (uint256) {
        uint256 result = Math.getLiquidityForAmount1(c, a1);
        return result;
    }
}
