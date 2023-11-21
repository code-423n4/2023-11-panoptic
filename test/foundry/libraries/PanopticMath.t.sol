// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Foundry
import "forge-std/Test.sol";
// Internal
import {TickMath} from "v3-core/libraries/TickMath.sol";
import {BitMath} from "v3-core/libraries/BitMath.sol";
import {Errors} from "@libraries/Errors.sol";
import {PanopticMathHarness} from "./harnesses/PanopticMathHarness.sol";
import {LiquidityChunk} from "@types/LiquidityChunk.sol";
import {TokenId} from "@types/TokenId.sol";
import {LeftRight} from "@types/LeftRight.sol";
import {PanopticMath} from "@libraries/PanopticMath.sol";
import {Math} from "@libraries/Math.sol";
// Uniswap
import {IUniswapV3Pool} from "v3-core/interfaces/IUniswapV3Pool.sol";
import {LiquidityAmounts} from "v3-periphery/libraries/LiquidityAmounts.sol";
import {FixedPoint96} from "v3-core/libraries/FixedPoint96.sol";
import {FixedPoint128} from "v3-core/libraries/FixedPoint128.sol";
import {FullMath} from "v3-core/libraries/FullMath.sol";
// Test util
import {PositionUtils} from "../testUtils/PositionUtils.sol";

/**
 * Test the PanopticMath functionality with Foundry and Fuzzing.
 *
 * @author Axicon Labs Limited
 */
contract PanopticMathTest is Test, PositionUtils {
    // harness
    PanopticMathHarness harness;

    // libraries
    using LeftRight for int256;
    using LeftRight for uint256;
    using TokenId for uint256;
    using LiquidityChunk for uint256;

    // store a few different mainnet pairs - the pool used is part of the fuzz
    IUniswapV3Pool constant USDC_WETH_5 =
        IUniswapV3Pool(0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640);
    IUniswapV3Pool constant WBTC_ETH_30 =
        IUniswapV3Pool(0xCBCdF9626bC03E24f779434178A73a0B4bad62eD);
    IUniswapV3Pool constant USDC_WETH_30 =
        IUniswapV3Pool(0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8);
    IUniswapV3Pool[3] public pools = [USDC_WETH_5, WBTC_ETH_30, USDC_WETH_30];

    function setUp() public {
        harness = new PanopticMathHarness();
    }

    // use storage as temp to avoid stack to deeps
    IUniswapV3Pool selectedPool;
    int24 tickSpacing;
    int24 currentTick;

    int24 minTick;
    int24 maxTick;
    int24 lowerBound;
    int24 upperBound;
    int24 strikeOffset;

    function test_Success_getLiquidityChunk_asset0(
        uint16 optionRatio,
        uint16 isLong,
        uint16 tokenType,
        int24 strike,
        int24 width,
        uint64 positionSize
    ) public {
        vm.assume(positionSize != 0);
        uint256 tokenId;

        // contruct a tokenId
        {
            uint256 optionRatio = bound(optionRatio, 1, 127);

            // the following are all 1 bit so mask them:
            uint8 MASK = 0x1; // takes first 1 bit of the uint16
            isLong = isLong & MASK;
            tokenType = tokenType & MASK;

            // bound fuzzed tick
            selectedPool = pools[bound(positionSize, 0, 2)]; // resue position size as seed
            tickSpacing = selectedPool.tickSpacing();

            width = int24(bound(width, 1, 2048));
            int24 oneSidedRange = (width * tickSpacing) / 2;

            (, currentTick, , , , , ) = selectedPool.slot0();
            (strikeOffset, minTick, maxTick) = PositionUtils.getContext(
                uint256(uint24(tickSpacing)),
                currentTick,
                width
            );

            lowerBound = int24(minTick + oneSidedRange - strikeOffset);
            upperBound = int24(maxTick - oneSidedRange - strikeOffset);

            // Set current tick and pool price
            currentTick = int24(bound(currentTick, minTick, maxTick));

            // bound strike
            strike = int24(bound(strike, lowerBound / tickSpacing, upperBound / tickSpacing));
            strike = int24(strike * tickSpacing + strikeOffset);

            tokenId = tokenId.addLeg(0, optionRatio, 0, isLong, tokenType, 0, strike, width);
        }

        (int24 tickLower, int24 tickUpper) = tokenId.asTicks(0, tickSpacing);

        uint160 sqrtPriceBottom = (tokenId.width(0) == 4095)
            ? TickMath.getSqrtRatioAtTick(tokenId.strike(0))
            : TickMath.getSqrtRatioAtTick(tickLower);

        uint256 amount = uint256(positionSize) * tokenId.optionRatio(0);
        uint128 legLiquidity = LiquidityAmounts.getLiquidityForAmount0(
            sqrtPriceBottom,
            TickMath.getSqrtRatioAtTick(tickUpper),
            amount
        );

        uint256 expectedLiquidityChunk = uint256(0).createChunk(tickLower, tickUpper, legLiquidity);
        uint256 returnedLiquidityChunk = harness.getLiquidityChunk(
            tokenId,
            0,
            positionSize,
            tickSpacing
        );

        assertEq(expectedLiquidityChunk, returnedLiquidityChunk);
    }

    function test_Success_getLiquidityChunk_asset1(
        uint16 optionRatio,
        uint16 isLong,
        uint16 tokenType,
        int24 strike,
        int24 width,
        uint64 positionSize
    ) public {
        vm.assume(positionSize != 0);
        uint256 tokenId;

        // contruct a tokenId
        {
            uint256 optionRatio = bound(optionRatio, 1, 127);

            // the following are all 1 bit so mask them:
            uint8 MASK = 0x1; // takes first 1 bit of the uint16
            isLong = isLong & MASK;
            tokenType = tokenType & MASK;

            // bound fuzzed tick
            selectedPool = pools[bound(positionSize, 0, 2)]; // resue position size as seed
            tickSpacing = selectedPool.tickSpacing();

            width = int24(bound(width, 1, 2048));
            int24 oneSidedRange = (width * tickSpacing) / 2;

            (, currentTick, , , , , ) = selectedPool.slot0();
            (strikeOffset, minTick, maxTick) = PositionUtils.getContext(
                uint256(uint24(tickSpacing)),
                currentTick,
                width
            );

            lowerBound = int24(minTick + oneSidedRange - strikeOffset);
            upperBound = int24(maxTick - oneSidedRange - strikeOffset);

            // Set current tick and pool price
            currentTick = int24(bound(currentTick, minTick, maxTick));

            // bound strike
            strike = int24(bound(strike, lowerBound / tickSpacing, upperBound / tickSpacing));
            strike = int24(strike * tickSpacing + strikeOffset);

            tokenId = tokenId.addLeg(0, optionRatio, 1, isLong, tokenType, 0, strike, width);
        }

        (int24 tickLower, int24 tickUpper) = tokenId.asTicks(0, tickSpacing);

        uint160 sqrtPriceTop = (tokenId.width(0) == 4095)
            ? TickMath.getSqrtRatioAtTick(tokenId.strike(0))
            : TickMath.getSqrtRatioAtTick(tickUpper);

        uint256 amount = uint256(positionSize) * tokenId.optionRatio(0);
        uint128 legLiquidity = LiquidityAmounts.getLiquidityForAmount1(
            TickMath.getSqrtRatioAtTick(tickLower),
            sqrtPriceTop,
            amount
        );

        uint256 expectedLiquidityChunk = uint256(0).createChunk(tickLower, tickUpper, legLiquidity);
        uint256 returnedLiquidityChunk = harness.getLiquidityChunk(
            tokenId,
            0,
            positionSize,
            tickSpacing
        );

        assertEq(expectedLiquidityChunk, returnedLiquidityChunk);
    }

    function test_Success_getPoolId(address univ3pool) public {
        uint64 poolId = uint64(uint160(univ3pool) >> 96);
        assertEq(poolId, harness.getPoolId(univ3pool));
    }

    function test_Success_getFinalPoolId(
        uint64 basePoolId,
        address token0,
        address token1,
        uint8 feeSeed
    ) public {
        uint64 finalPoolId;
        uint24 fee = [30, 60, 100][bound(feeSeed, 0, 2)];
        unchecked {
            finalPoolId =
                basePoolId +
                (uint64(uint256(keccak256(abi.encodePacked(token0, token1, fee)))) >> 32);
        }

        assertEq(finalPoolId, harness.getFinalPoolId(basePoolId, token0, token1, fee));
    }

    function test_Success_convert0to1_PriceX192_Int(int256 amount, uint256 sqrtPriceSeed) public {
        // above this tick we use 128-bit precision because of overflow issues
        uint160 sqrtPrice = uint160(
            bound(sqrtPriceSeed, TickMath.MIN_SQRT_RATIO, 340275971719517849884101479065584693833)
        );

        uint256 priceX192 = uint256(sqrtPrice) ** 2;

        uint256 absAmount = Math.absUint(amount);

        // make sure the final result does not overflow
        unchecked {
            uint256 mm = mulmod(priceX192, absAmount, type(uint256).max);
            uint256 prod0 = priceX192 * absAmount;
            vm.assume((mm - prod0) - (mm < prod0 ? 1 : 0) < 2 ** 192);
        }
        vm.assume(FullMath.mulDiv(absAmount, priceX192, 2 ** 192) <= uint256(type(int256).max));
        assertEq(
            harness.convert0to1(amount, sqrtPrice),
            (amount < 0 ? -1 : int(1)) * int(FullMath.mulDiv(absAmount, priceX192, 2 ** 192))
        );
    }

    function test_Fail_convert0to1_PriceX192_Int_overflow(
        int256 amount,
        uint256 sqrtPriceSeed
    ) public {
        // above this tick we use 128-bit precision because of overflow issues
        uint160 sqrtPrice = uint160(
            bound(sqrtPriceSeed, TickMath.MIN_SQRT_RATIO, 340275971719517849884101479065584693833)
        );

        uint256 priceX192 = uint256(sqrtPrice) ** 2;

        uint256 absAmount = Math.absUint(amount);

        // make sure the final result does overflow
        unchecked {
            uint256 mm = mulmod(priceX192, absAmount, type(uint256).max);
            uint256 prod0 = priceX192 * absAmount;
            vm.assume((mm - prod0) - (mm < prod0 ? 1 : 0) >= 2 ** 192);
        }

        vm.expectRevert();
        harness.convert0to1(amount, sqrtPrice);
    }

    function test_Fail_convert0to1_PriceX192_Int_CastingError(
        int256 amount,
        uint256 sqrtPriceSeed
    ) public {
        // above this tick we use 128-bit precision because of overflow issues
        uint160 sqrtPrice = uint160(
            bound(sqrtPriceSeed, TickMath.MIN_SQRT_RATIO, 340275971719517849884101479065584693833)
        );

        uint256 priceX192 = uint256(sqrtPrice) ** 2;

        uint256 absAmount = Math.absUint(amount);

        // make sure the final result does overflow
        unchecked {
            uint256 mm = mulmod(priceX192, absAmount, type(uint256).max);
            uint256 prod0 = priceX192 * absAmount;
            vm.assume((mm - prod0) - (mm < prod0 ? 1 : 0) < 2 ** 192);
        }

        vm.assume(FullMath.mulDiv(absAmount, priceX192, 2 ** 192) > uint256(type(int256).max));
        vm.expectRevert(Errors.CastingError.selector);
        harness.convert0to1(amount, sqrtPrice);
    }

    function test_Success_convert1to0_PriceX192_Int(int256 amount, uint256 sqrtPriceSeed) public {
        // above this tick we use 128-bit precision because of overflow issues
        uint160 sqrtPrice = uint160(
            bound(sqrtPriceSeed, TickMath.MIN_SQRT_RATIO, 340275971719517849884101479065584693833)
        );

        uint256 priceX192 = uint256(sqrtPrice) ** 2;

        uint256 absAmount = Math.absUint(amount);

        // make sure the final result does not overflow
        unchecked {
            uint256 mm = mulmod(absAmount, 2 ** 192, type(uint256).max);
            uint256 prod0 = 2 ** 192 * absAmount;
            vm.assume((mm - prod0) - (mm < prod0 ? 1 : 0) < priceX192);
        }

        vm.assume(FullMath.mulDiv(absAmount, 2 ** 192, priceX192) <= uint256(type(int256).max));
        assertEq(
            harness.convert1to0(amount, sqrtPrice),
            (amount < 0 ? -1 : int(1)) * int(FullMath.mulDiv(absAmount, 2 ** 192, priceX192))
        );
    }

    function test_Fail_convert1to0_PriceX192_Int_overflow(
        int256 amount,
        uint256 sqrtPriceSeed
    ) public {
        // above this tick we use 128-bit precision because of overflow issues
        uint160 sqrtPrice = uint160(
            bound(sqrtPriceSeed, TickMath.MIN_SQRT_RATIO, 340275971719517849884101479065584693833)
        );

        uint256 priceX192 = uint256(sqrtPrice) ** 2;

        uint256 absAmount = Math.absUint(amount);

        // make sure the final result does not overflow
        unchecked {
            uint256 mm = mulmod(2 ** 192, absAmount, type(uint256).max);
            uint256 prod0 = 2 ** 192 * absAmount;
            vm.assume((mm - prod0) - (mm < prod0 ? 1 : 0) >= priceX192);
        }

        vm.expectRevert();
        harness.convert1to0(amount, sqrtPrice);
    }

    function test_Fail_convert1to0_PriceX192_Int_CastingError(
        int256 amount,
        uint256 sqrtPriceSeed
    ) public {
        // above this tick we use 128-bit precision because of overflow issues
        uint160 sqrtPrice = uint160(
            bound(sqrtPriceSeed, TickMath.MIN_SQRT_RATIO, 340275971719517849884101479065584693833)
        );

        uint256 priceX192 = uint256(sqrtPrice) ** 2;

        uint256 absAmount = Math.absUint(amount);

        // make sure the final result does not overflow
        unchecked {
            uint256 mm = mulmod(2 ** 192, absAmount, type(uint256).max);
            uint256 prod0 = 2 ** 192 * absAmount;
            vm.assume((mm - prod0) - (mm < prod0 ? 1 : 0) < priceX192);
        }

        vm.assume(FullMath.mulDiv(absAmount, 2 ** 192, priceX192) > uint256(type(int256).max));
        vm.expectRevert(Errors.CastingError.selector);
        harness.convert1to0(amount, sqrtPrice);
    }

    function test_Success_convert0to1_PriceX128_Int(int256 amount, uint256 sqrtPriceSeed) public {
        // above this tick we use 128-bit precision because of overflow issues
        uint160 sqrtPrice = uint160(
            bound(sqrtPriceSeed, 340275971719517849884101479065584693834, TickMath.MAX_SQRT_RATIO)
        );

        uint256 priceX128 = FullMath.mulDiv(sqrtPrice, sqrtPrice, 2 ** 64);

        uint256 absAmount = Math.absUint(amount);

        // make sure the final result does not overflow
        unchecked {
            uint256 mm = mulmod(priceX128, absAmount, type(uint256).max);
            uint256 prod0 = priceX128 * absAmount;
            vm.assume((mm - prod0) - (mm < prod0 ? 1 : 0) < 2 ** 128);
        }

        vm.assume(FullMath.mulDiv(absAmount, priceX128, 2 ** 128) <= uint256(type(int256).max));
        assertEq(
            harness.convert0to1(amount, sqrtPrice),
            (amount < 0 ? -1 : int(1)) * int(FullMath.mulDiv(absAmount, priceX128, 2 ** 128))
        );
    }

    function test_Fail_convert0to1_PriceX128_Int_overflow(
        int256 amount,
        uint256 sqrtPriceSeed
    ) public {
        // above this tick we use 128-bit precision because of overflow issues
        uint160 sqrtPrice = uint160(
            bound(sqrtPriceSeed, 340275971719517849884101479065584693834, TickMath.MAX_SQRT_RATIO)
        );

        uint256 priceX128 = FullMath.mulDiv(sqrtPrice, sqrtPrice, 2 ** 64);

        uint256 absAmount = Math.absUint(amount);

        // make sure the final result does overflow
        unchecked {
            uint256 mm = mulmod(priceX128, absAmount, type(uint256).max);
            uint256 prod0 = priceX128 * absAmount;
            vm.assume((mm - prod0) - (mm < prod0 ? 1 : 0) >= 2 ** 128);
        }

        vm.expectRevert();
        harness.convert0to1(amount, sqrtPrice);
    }

    function test_Fail_convert0to1_PriceX128_Int_CastingError(
        int256 amount,
        uint256 sqrtPriceSeed
    ) public {
        // above this tick we use 128-bit precision because of overflow issues
        uint160 sqrtPrice = uint160(
            bound(sqrtPriceSeed, 340275971719517849884101479065584693834, TickMath.MAX_SQRT_RATIO)
        );

        uint256 priceX128 = FullMath.mulDiv(sqrtPrice, sqrtPrice, 2 ** 64);

        uint256 absAmount = Math.absUint(amount);

        // make sure the final result does overflow
        unchecked {
            uint256 mm = mulmod(priceX128, absAmount, type(uint256).max);
            uint256 prod0 = priceX128 * absAmount;
            vm.assume((mm - prod0) - (mm < prod0 ? 1 : 0) < 2 ** 128);
        }

        vm.assume(FullMath.mulDiv(absAmount, priceX128, 2 ** 128) > uint256(type(int256).max));
        vm.expectRevert(Errors.CastingError.selector);
        harness.convert0to1(amount, sqrtPrice);
    }

    function test_Success_convert1to0_PriceX128_Int(int256 amount, uint256 sqrtPriceSeed) public {
        // above this tick we use 128-bit precision because of overflow issues
        uint160 sqrtPrice = uint160(
            bound(sqrtPriceSeed, 340275971719517849884101479065584693834, TickMath.MAX_SQRT_RATIO)
        );

        uint256 priceX128 = FullMath.mulDiv(sqrtPrice, sqrtPrice, 2 ** 64);

        uint256 absAmount = Math.absUint(amount);

        // make sure the final result does not overflow
        unchecked {
            uint256 mm = mulmod(2 ** 128, absAmount, type(uint256).max);
            uint256 prod0 = 2 ** 128 * absAmount;
            vm.assume((mm - prod0) - (mm < prod0 ? 1 : 0) < priceX128);
        }

        vm.assume(FullMath.mulDiv(absAmount, 2 ** 128, priceX128) <= uint256(type(int256).max));
        assertEq(
            harness.convert1to0(amount, sqrtPrice),
            (amount < 0 ? -1 : int(1)) * int(FullMath.mulDiv(absAmount, 2 ** 128, priceX128))
        );
    }
}
