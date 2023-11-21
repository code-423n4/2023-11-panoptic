// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IUniswapV3Pool} from "univ3-core/interfaces/IUniswapV3Pool.sol";
import {FeesCalc} from "@libraries/FeesCalc.sol";

/// @title FeesCalcHarness: A harness to expose the Feescalc library for code coverage analysis.
/// @notice Replicates the interface of the Feescalc library, passing through any function calls
/// @author Axicon Labs Limited
contract FeesCalcHarness {
    // used to pass into libraries
    mapping(uint256 tokenId => uint256 balance) public userBalance;

    function calculateAMMSwapFeesLiquidityChunk(
        IUniswapV3Pool univ3pool,
        int24 currentTick,
        uint128 startingLiquidity,
        uint256 liquidityChunk
    ) public view returns (int256 feesEachToken) {
        int256 feesEachToken = FeesCalc.calculateAMMSwapFeesLiquidityChunk(
            univ3pool,
            currentTick,
            startingLiquidity,
            liquidityChunk
        );
        return (feesEachToken);
    }

    function getAMMSwapFeesPerLiquidityCollected(
        IUniswapV3Pool univ3pool,
        int24 currentTick,
        int24 tickLower,
        int24 tickUpper
    ) public view returns (uint256, uint256) {
        (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) = FeesCalc
            ._getAMMSwapFeesPerLiquidityCollected(univ3pool, currentTick, tickLower, tickUpper);

        return (feeGrowthInside0X128, feeGrowthInside1X128);
    }

    function addBalance(uint256 tokenId, uint128 balance) public {
        userBalance[tokenId] = balance;
    }
}
