// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// Libraries
import {Math} from "@libraries/Math.sol";
// Custom types
import {LeftRight} from "@types/LeftRight.sol";
import {LiquidityChunk} from "@types/LiquidityChunk.sol";
import {TokenId} from "@types/TokenId.sol";

/// @title Compute general math quantities relevant to Panoptic and AMM pool management.
/// @author Axicon Labs Limited
library PanopticMath {
    // enables packing of types within int128|int128 or uint128|uint128 containers.
    using LeftRight for int256;
    using LeftRight for uint256;
    // represents a single liquidity chunk in Uniswap. Contains tickLower, tickUpper, and amount of liquidity
    using LiquidityChunk for uint256;
    // represents an option position of up to four legs as a sinlge ERC1155 tokenId
    using TokenId for uint256;

    /*//////////////////////////////////////////////////////////////
                              MATH HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Given an address to a Uniswap v3 pool, return its 64-bit ID as used in the `TokenId` of Panoptic.
    /// @dev Example:
    ///      the 64 bits are the 64 *last* (most significant) bits - and thus corresponds to the *first* 16 hex characters (reading left to right)
    ///      of the Uniswap v3 pool address, e.g.:
    ///        univ3pool = 0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8
    ///      the returned id is then:
    ///        0x8ad599c3A0ff1De0
    ///      which as a uint64 is:
    ///        10004071212772171232.
    ///
    /// @param univ3pool the Uniswap v3 pool to get the ID of
    /// @return a uint64 representing a fingerprint of the uniswap v3 pool address
    function getPoolId(address univ3pool) internal pure returns (uint64) {
        return uint64(uint160(univ3pool) >> 96);
    }

    /// @notice Returns the resultant pool ID for the given 64-bit base pool ID and parameters.
    /// @param basePoolId the 64-bit base pool ID
    /// @param token0 the address of the first token in the pool
    /// @param token1 the address of the second token in the pool
    /// @param fee the fee of the pool in hundredths of a bi
    /// @return finalPoolId the final 64-bit pool id as encoded in the `TokenId` type - composed of the last 64 bits of the address and a hash of the parameters
    function getFinalPoolId(
        uint64 basePoolId,
        address token0,
        address token1,
        uint24 fee
    ) internal pure returns (uint64) {
        unchecked {
            return
                basePoolId +
                (uint64(uint256(keccak256(abi.encodePacked(token0, token1, fee)))) >> 32);
        }
    }

    /*//////////////////////////////////////////////////////////////
                         LIQUIDITY CALCULATION
    //////////////////////////////////////////////////////////////*/

    /// @notice For a given option position (`tokenId`), leg index within that position (`legIndex`), and `positionSize` get the tick range spanned and its
    /// liquidity (share ownership) in the Univ3 pool; this is a liquidity chunk.

    ///          Liquidity chunk  (defined by tick upper, tick lower, and its size/amount: the liquidity)
    ///   liquidity    │
    ///         ▲      │
    ///         │     ┌▼┐
    ///         │  ┌──┴─┴──┐
    ///         │  │       │
    ///         │  │       │
    ///         └──┴───────┴────► price
    ///         Uniswap v3 Pool
    /// @param tokenId the option position id
    /// @param legIndex the leg index of the option position, can be {0,1,2,3}
    /// @param positionSize the number of contracts held by this leg
    /// @param tickSpacing the tick spacing of the underlying univ3 pool
    /// @return liquidityChunk a uint256 bit-packed (see `LiquidityChunk.sol`) with `tickLower`, `tickUpper`, and `liquidity`
    function getLiquidityChunk(
        uint256 tokenId,
        uint256 legIndex,
        uint128 positionSize,
        int24 tickSpacing
    ) internal pure returns (uint256 liquidityChunk) {
        // get the tick range for this leg
        (int24 tickLower, int24 tickUpper) = tokenId.asTicks(legIndex, tickSpacing);

        // Get the amount of liquidity owned by this leg in the univ3 pool in the above tick range
        // Background:
        //
        //  In Uniswap v3, the amount of liquidity received for a given amount of token0 when the price is
        //  not in range is given by:
        //     Liquidity = amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
        //  For token1, it is given by:
        //     Liquidity = amount1 / (sqrt(upper) - sqrt(lower))
        //
        //  However, in Panoptic, each position has a asset parameter. The asset is the "basis" of the position.
        //  In TradFi, the asset is always cash and selling a $1000 put requires the user to lock $1000, and selling
        //  a call requires the user to lock 1 unit of asset.
        //
        //  Because Uni v3 chooses token0 and token1 from the alphanumeric order, there is no consistency as to whether token0 is
        //  stablecoin, ETH, or an ERC20. Some pools may want ETH to be the asset (e.g. ETH-DAI) and some may wish the stablecoin to
        //  be the asset (e.g. DAI-ETH) so that K asset is moved for puts and 1 asset is moved for calls.
        //  But since the convention is to force the order always we have no say in this.
        //
        //  To solve this, we encode the asset value in tokenId. This parameter specifies which of token0 or token1 is the
        //  asset, such that:
        //     when asset=0, then amount0 moved at strike K =1.0001**currentTick is 1, amount1 moved to strike K is 1/K
        //     when asset=1, then amount1 moved at strike K =1.0001**currentTick is K, amount0 moved to strike K is 1
        //
        //  The following function takes this into account when computing the liquidity of the leg and switches between
        //  the definition for getLiquidityForAmount0 or getLiquidityForAmount1 when relevant.
        //
        //
        uint128 legLiquidity;
        uint256 amount = uint256(positionSize) * tokenId.optionRatio(legIndex);
        if (tokenId.asset(legIndex) == 0) {
            legLiquidity = Math.getLiquidityForAmount0(
                uint256(0).addTickLower(tickLower).addTickUpper(tickUpper),
                amount
            );
        } else {
            legLiquidity = Math.getLiquidityForAmount1(
                uint256(0).addTickLower(tickLower).addTickUpper(tickUpper),
                amount
            );
        }

        // now pack this info into the bit pattern of the uint256 and return it
        liquidityChunk = liquidityChunk.createChunk(tickLower, tickUpper, legLiquidity);
    }

    /*//////////////////////////////////////////////////////////////
                         TOKEN CONVERSION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Convert an amount of token0 into an amount of token1 given the sqrtPriceX96 in a Uniswap pool defined as sqrt(1/0)*2^96.
    /// @dev Uses reduced precision after tick 443636 in order to accomodate the full range of ticks
    /// @param amount the amount of token0 to convert into token1
    /// @param sqrtPriceX96 the square root of the price at which to convert `amount` of token0 into token1
    /// @return the converted `amount` of token0 represented in terms of token1
    function convert0to1(int256 amount, uint160 sqrtPriceX96) internal pure returns (int256) {
        unchecked {
            // the tick 443636 is the maximum price where (price) * 2**192 fits into a uint256 (< 2**256-1)
            // above that tick, we are forced to reduce the amount of decimals in the final price by 2**64 to 2**128
            if (sqrtPriceX96 < 340275971719517849884101479065584693834) {
                int256 absResult = Math
                    .mulDiv192(Math.absUint(amount), uint256(sqrtPriceX96) ** 2)
                    .toInt256();
                return amount < 0 ? -absResult : absResult;
            } else {
                int256 absResult = Math
                    .mulDiv128(Math.absUint(amount), Math.mulDiv64(sqrtPriceX96, sqrtPriceX96))
                    .toInt256();
                return amount < 0 ? -absResult : absResult;
            }
        }
    }

    /// @notice Convert an amount of token0 into an amount of token1 given the sqrtPriceX96 in a Uniswap pool defined as sqrt(1/0)*2^96.
    /// @dev Uses reduced precision after tick 443636 in order to accomodate the full range of ticks
    /// @param amount the amount of token0 to convert into token1
    /// @param sqrtPriceX96 the square root of the price at which to convert `amount` of token0 into token1
    /// @return the converted `amount` of token0 represented in terms of token1
    function convert1to0(int256 amount, uint160 sqrtPriceX96) internal pure returns (int256) {
        unchecked {
            // the tick 443636 is the maximum price where (price) * 2**192 fits into a uint256 (< 2**256-1)
            // above that tick, we are forced to reduce the amount of decimals in the final price by 2**64 to 2**128
            if (sqrtPriceX96 < 340275971719517849884101479065584693834) {
                int256 absResult = Math
                    .mulDiv(Math.absUint(amount), 2 ** 192, uint256(sqrtPriceX96) ** 2)
                    .toInt256();
                return amount < 0 ? -absResult : absResult;
            } else {
                int256 absResult = Math
                    .mulDiv(
                        Math.absUint(amount),
                        2 ** 128,
                        Math.mulDiv64(sqrtPriceX96, sqrtPriceX96)
                    )
                    .toInt256();
                return amount < 0 ? -absResult : absResult;
            }
        }
    }
}
