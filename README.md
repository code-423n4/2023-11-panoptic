# Panoptic audit details
- Total Prize Pool: $60,500 USDC 
  - HM awards: $41,250 USDC 
  - Analysis awards: $2,500 USDC
  - QA awards: $1,250 USDC 
  - Bot Race awards: $3,750 USDC 
  - Gas awards: $1,250 USDC
  - Judge awards: $6,000 USDC
  - Lookout awards: $4,000 USDC 
  - Scout awards: $500 USDC 
- Join [C4 Discord](https://discord.gg/code4rena) to register
- Submit findings [using the C4 form](https://code4rena.com/contests/2023-11-panoptic/submit)
- [Read our guidelines for more details](https://docs.code4rena.com/roles/wardens)
- Starts November 27, 2023 20:00 UTC 
- Ends December 4, 2023 20:00 UTC

## Automated Findings / Publicly Known Issues

The 4naly3er report can be found [here](https://gist.github.com/JustDravee/0c80bf61962549e5b9ebd8b56e783155).

Automated findings output for the audit can be found [here](https://github.com/code-423n4/2023-11-panoptic/blob/main/bot-report.md) within 24 hours of audit opening.

_Note for C4 wardens: Anything included in this `Automated Findings / Publicly Known Issues` section is considered a publicly known issue and is ineligible for awards._

- Transfers of ERC1155 SFPM tokens are very limited by design. It is expected that certain accounts will be unable to transfer or receive tokens. 
Some tokens may not be transferable at all.
- Construction helper functions (prefixed with add) in the TokenId library and other types do not perform extensive input validation. Passing invalid or nonsensical inputs into these functions or attempting to overwrite already filled slots may yield unexpected or invalid results. This is by design, so it is expected that users
of these functions will validate the inputs beforehand. 
- Pools with a tick spacing of 1 are not currently supported. For the purposes of this audit, the only tick spacings that are supported are 10, 60, and 200 (corresponding to fee tiers of 5bps, 30bps, and 100bps respectively).
- Very large quantities of tokens are not supported. It should be assumed that for any given pool, the cumulative amount of tokens that enter the system (associated with that pool, through adding liquidity, collection, etc.) will not exceed 2^127 - 1. Note that this is only a per-pool assumption, so if it is broken on one pool it should not affect the operation of any other pools, only the pool in question.

# Overview

The SemiFungiblePositionManager gas-efficient alternative to Uniswap’s NonFungiblePositionManager that manages complex, multi-leg Uniswap positions encoded in ERC1155 tokenIds, performs swaps allowing users to mint positions with only one type of token, and, most crucially, supports the minting of both typical LP positions where liquidity is added to Uniswap and “long” positions where Uniswap liquidity is burnt.

This contract is a component of the Panoptic V1 protocol, but also serves as a standalone liquidity manager open for use by any user or protocol.

## Links

- [Panoptic's Website](https://www.panoptic.xyz)
- [Twitter](https://twitter.com/Panoptic_xyz)
- [Discord](https://discord.gg/7fE8SN9pRT)
- [Blog](https://www.panoptic.xyz/blog)
- [YouTube](https://www.youtube.com/@Panopticxyz)


# Scope

| Contract | SLOC | Purpose | Libraries used |
| ----------- | ----------- | ----------- | ----------- |
| [contracts/SemiFungiblePositionManager.sol](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/SemiFungiblePositionManager.sol) | 757 | The 'engine' of Panoptic - manages all Uniswap V3 positions in the protocol as well as being a more advanced, gas-efficient alternative to NFPM for Uniswap LPs | |
| [contracts/tokens/ERC1155Minimal.sol](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/tokens/ERC1155Minimal.sol) | 129 | A minimalist implementation of the ERC1155 token standard without metadata | [`@openzeppelin/*`](https://openzeppelin.com/contracts/) |
| [contracts/types/LeftRight.sol](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/types/LeftRight.sol) | 91 | Implementation for a set of custom data types that can hold two 128-bit numbers | |
| [contracts/types/LiquidityChunk.sol](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/types/LiquidityChunk.sol) | 45 | Implementation for a custom data type that can represent a liquidity chunk of a given size in Uniswap - containing a tickLower, tickUpper, and liquidity | |
| [contracts/types/TokenId.sol](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/types/TokenId.sol) | 290 | Implementation for the custom data type used in the SFPM and Panoptic to encode position data in 256-bit ERC1155 tokenIds - holds a pool identifier and up to four full position legs | |
| [contracts/libraries/CallbackLib.sol](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/libraries/CallbackLib.sol) | 36 | Library for verifying and decoding Uniswap callbacks | |
| [contracts/libraries/Constants.sol](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/libraries/Constants.sol) | 13 | Library of Constants used in Panoptic | |
| [contracts/libraries/Errors.sol](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/libraries/Errors.sol) | 19 | Contains all custom errors used in Panoptic's core contracts | |
| [contracts/libraries/FeesCalc.sol](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/libraries/FeesCalc.sol) | 52 | Utility to calculate up-to-date swap fees for liquidity chunks | |
| [contracts/libraries/Math.sol](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/libraries/Math.sol) | 266 | Library of generic math functions like abs(), mulDiv, etc | |
| [contracts/libraries/PanopticMath.sol](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/libraries/PanopticMath.sol) | 82 | Library containing advanced Panoptic/Uniswap-specific functionality such as our TWAP, price conversions, and position sizing math | |
| [contracts/libraries/SafeTransferLib.sol](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/libraries/SafeTransferLib.sol) | 19 | Safe ERC20 transfer library that gracefully handles missing return values | |
| [contracts/multicall/Multicall.sol](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/multicall/Multicall.sol) | 18 | Adds a function to inheriting contracts that allows for multiple calls to be executed in a single transaction | |

```ml
contracts/
├── SemiFungiblePositionManager — "The 'engine' of Panoptic - manages all Uniswap V3 positions in the protocol as well as being a more advanced, gas-efficient alternative to NFPM for Uniswap LPs"
├── tokens
│   └── ERC1155Minimal — "A minimalist implementation of the ERC1155 token standard without metadata"
├── types
│   ├── LeftRight — "Implementation for a set of custom data types that can hold two 128-bit numbers"
│   ├── LiquidityChunk — "Implementation for a custom data type that can represent a liquidity chunk of a given size in Uniswap - containing a tickLower, tickUpper, and liquidity"
│   └── TokenId — "Implementation for the custom data type used in the SFPM and Panoptic to encode position data in 256-bit ERC1155 tokenIds - holds a pool identifier and up to four full position legs"
├── libraries
│   ├── CallbackLib — "Library for verifying and decoding Uniswap callbacks"
│   ├── Constants — "Library of Constants used in Panoptic"
│   ├── Errors — "Contains all custom errors used in Panoptic's core contracts"
│   ├── FeesCalc — "Utility to calculate up-to-date swap fees for liquidity chunks"
│   ├── Math — "Library of generic math functions like abs(), mulDiv, etc"
│   ├── PanopticMath — "Library containing advanced Panoptic/Uniswap-specific functionality such as our TWAP, price conversions, and position sizing math"
│   └── SafeTransferLib — "Safe ERC20 transfer library that gracefully handles missing return values"
└── multicall
   └── Multicall — "Adds a function to inheriting contracts that allows for multiple calls to be executed in a single transaction"
```
## Out of scope
All files in the `contracts` directory are in scope.

# Additional Context
- Any compliant ERC20 token that is part of a Uniswap V3 pool and is not a fee-on-transfer token is supported, including ERC-777 tokens.
- The SFPM may be deployed to Ethereum, Arbitrum, Polygon, Optimism, BSC, Base, and Avalanche, and other EVM chains with active Uniswap V3 deployments.
- EIP Compliance
  - `SemiFungiblePositionManager`: Should comply with `ERC1155`

## Main invariants
- Users of the SFPM can only remove liquidity (via isLong==1 or burning positions) that they have previously added under the same (tickLower, tickUpper, tokenType) key. They cannot remove liquidity owned by other users.
- Fees collected from Uniswap during any given operation should not exceed the amount of fees earned by the liquidity owned by the user performing the operation.
- Fees paid to a given user should not exceed the amount of fees earned by the liquidity owned by that user.
  
## Scoping Details 
```
- If you have a public code repo, please share it here: N/A
- How many contracts are in scope?: 13
- Total SLoC for these contracts?:  1817
- How many external imports are there?:  2
- How many separate interfaces and struct definitions are there for the contracts within scope?:  1
- Does most of your code generally use composition or inheritance?:  Composition
- How many external calls?: 5
- What is the overall line coverage percentage provided by your tests?: 100
- Is this an upgrade of an existing system?: No
- Check all that apply (e.g. timelock, NFT, AMM, ERC20, rollups, etc.): NFT, Non ERC-20 Token 
- Is there a need to understand a separate part of the codebase / get context in order to audit this part of the protocol?: No 
- Please describe required context:  N/A
- Does it use an oracle?:  No
- Describe any novel or unique curve logic or mathematical models your code uses: N/A
- Is this either a fork of or an alternate implementation of another project?:   No
- Does it use a side-chain?: 
- Describe any specific areas you would like addressed:
```

# Tests
Clone and initialize submodules:
```bash
git clone --recurse-submodules https://github.com/code-423n4/2023-11-panoptic.git
```

Build the contracts:
```bash
forge build
```

Test the contracts:
```bash
forge test
```

Gas report:
```bash
forge test --gas-report
```

Note that due to the complex and fuzzing-heavy nature of the tests, they may be slow to run on a public RPC. If you have a local mainnet node, you may want to run the tests against that instead. If you want to write your own tests, we recommend using the `--match-test testName` flag to ensure only the tests you want to run are executed.

## Slither
Running slither should produce 156 results. We have reviewed all of these results on our end, and have not found them to be issues. Much of the interesting issues are regarding reentrancy, and we have implemented a per-pool reentrancy guard in the SFPM. Please do not submit slither results as findings unless you have *confirmed* there is a specific exploitable issue resulting in negative consequences linked to the result. 
