// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Custom Errors library.
/// @author Axicon Labs Limited
library Errors {
    /// Errors are alphabetically ordered

    /// @notice Casting error
    /// @dev e.g. uint128(uint256(a)) fails
    error CastingError();

    /// @notice Tick is not between MIN_TICK and MAX_TICK
    error InvalidTick();

    /// @notice A mint or swap callback was attempted from an address that did not match the canonical Uniswap V3 pool with the claimed features
    error InvalidUniswapCallback();

    /// @notice Invalid TokenId parameter detected
    /// @param parameterType poolId=0, ratio=1, tokenType=2, risk_partner=3 , strike=4, width=5
    error InvalidTokenIdParameter(uint256 parameterType);

    /// @notice Invalid input in LeftRight library.
    error LeftRightInputError();

    /// @notice None of the forced exercised legs are exerciseable (they are all in-the-money)
    error NoLegsExercisable();

    /// @notice max token amounts for position exceed 128 bits.
    error PositionTooLarge();

    /// @notice There is not enough liquidity to buy an option
    error NotEnoughLiquidity();

    /// @notice User's option balance is zero or does not exist
    error OptionsBalanceZero();

    /// @notice PanopticPool: Current tick not within range
    error PriceBoundFail();

    /// @notice Function has been called while reentrancy lock is active
    error ReentrantCall();

    /// @notice Transfer failed
    error TransferFailed();

    /// @notice The tick range given by the strike price and width is invalid
    /// because the upper and lower ticks are not multiples of `tickSpacing`
    error TicksNotInitializable();

    /// @notice Under/Overflow has happened
    error UnderOverFlow();

    /// @notice Uniswap v3 pool itself has not been initialized and therefore does not exist.
    error UniswapPoolNotInitialized();
}
