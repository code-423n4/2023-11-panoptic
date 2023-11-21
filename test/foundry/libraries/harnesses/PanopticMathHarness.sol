// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Internal
import {PanopticMath} from "@libraries/PanopticMath.sol";
// Uniswap
import {IUniswapV3Pool} from "v3-core/interfaces/IUniswapV3Pool.sol";
import "forge-std/Test.sol";

/// @title PanopticMathHarness: A harness to expose the PanopticMath library for code coverage analysis.
/// @notice Replicates the interface of the PanopticMath library, passing through any function calls
/// @author Axicon Labs Limited
contract PanopticMathHarness is Test {
    function getLiquidityChunk(
        uint256 tokenId,
        uint256 legIndex,
        uint128 positionSize,
        int24 tickSpacing
    ) public view returns (uint256) {
        uint256 liquidityChunk = PanopticMath.getLiquidityChunk(
            tokenId,
            legIndex,
            positionSize,
            tickSpacing
        );
        return liquidityChunk;
    }

    function getPoolId(address univ3pool) public pure returns (uint64) {
        uint64 poolId = PanopticMath.getPoolId(univ3pool);
        return poolId;
    }

    function getFinalPoolId(
        uint64 basePoolId,
        address token0,
        address token1,
        uint24 fee
    ) public pure returns (uint64) {
        uint64 finalPoolId = PanopticMath.getFinalPoolId(basePoolId, token0, token1, fee);
        return finalPoolId;
    }

    function convert0to1(int256 amount, uint160 sqrtPriceX96) public pure returns (int256) {
        int256 result = PanopticMath.convert0to1(amount, sqrtPriceX96);
        return result;
    }

    function convert1to0(int256 amount, uint160 sqrtPriceX96) public pure returns (int256) {
        int256 result = PanopticMath.convert1to0(amount, sqrtPriceX96);
        return result;
    }
}
