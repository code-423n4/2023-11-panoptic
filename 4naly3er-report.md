# Report

## Gas Optimizations

| |Issue|Instances|
|-|:-|:-:|
| [GAS-1](#GAS-1) | Use assembly to check for `address(0)` | 2 |
| [GAS-2](#GAS-2) | Using bools for storage incurs overhead | 3 |
| [GAS-3](#GAS-3) | Cache array length outside of loop | 4 |
| [GAS-4](#GAS-4) | For Operations that will not overflow, you could use unchecked | 559 |
| [GAS-5](#GAS-5) | Don't initialize variables with default value | 7 |
| [GAS-6](#GAS-6) | Use shift Right/Left instead of division/multiplication if possible | 1 |
| [GAS-7](#GAS-7) | Use != 0 instead of > 0 for unsigned integer comparison | 12 |
| [GAS-8](#GAS-8) | `internal` functions not called by the contract should be removed | 57 |

### <a name="GAS-1"></a>[GAS-1] Use assembly to check for `address(0)`

*Saves 6 gas per instance*

*Instances (2)*:

```solidity
File: contracts/SemiFungiblePositionManager.sol

366:         // @dev in the unlikely case that there is a collision between the first 8 bytes of two different Uni v3 pools

385:         }

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/SemiFungiblePositionManager.sol)

### <a name="GAS-2"></a>[GAS-2] Using bools for storage incurs overhead

Use uint256(1) and uint256(2) for true/false to avoid a Gwarmaccess (100 gas), and to avoid Gsset (20000 gas) when changing from ‘false’ to ‘true’, after having been ‘true’ in the past. See [source](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/58f635312aa21f947cae5f8578638a85aa2519f5/contracts/security/ReentrancyGuard.sol#L23-L27).

*Instances (3)*:

```solidity
File: contracts/SemiFungiblePositionManager.sol

127:     bool internal constant MINT = false;

128:     bool internal constant BURN = true;

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/SemiFungiblePositionManager.sol)

```solidity
File: contracts/tokens/ERC1155Minimal.sol

67:     mapping(address owner => mapping(address operator => bool approvedForAll))

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/tokens/ERC1155Minimal.sol)

### <a name="GAS-3"></a>[GAS-3] Cache array length outside of loop

If not cached, the solidity compiler will always read the length of the array during each iteration. That is, if it is a storage array, this is an extra sload operation (100 additional extra gas for each iteration except for the first) and if it is a memory array, this is an extra mload operation (3 additional gas for each iteration except for the first).

*Instances (4)*:

```solidity
File: contracts/SemiFungiblePositionManager.sol

550:         for (uint256 i = 0; i < ids.length; ) {

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/SemiFungiblePositionManager.sol)

```solidity
File: contracts/multicall/Multicall.sol

14:         for (uint256 i = 0; i < data.length; ) {

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/multicall/Multicall.sol)

```solidity
File: contracts/tokens/ERC1155Minimal.sol

141:         for (uint256 i = 0; i < ids.length; ) {

187:             for (uint256 i = 0; i < owners.length; ++i) {

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/tokens/ERC1155Minimal.sol)

### <a name="GAS-4"></a>[GAS-4] For Operations that will not overflow, you could use unchecked

*Instances (559)*:

```solidity
File: contracts/SemiFungiblePositionManager.sol

5: import {IUniswapV3Factory} from "univ3-core/interfaces/IUniswapV3Factory.sol";

5: import {IUniswapV3Factory} from "univ3-core/interfaces/IUniswapV3Factory.sol";

5: import {IUniswapV3Factory} from "univ3-core/interfaces/IUniswapV3Factory.sol";

6: import {IUniswapV3Pool} from "univ3-core/interfaces/IUniswapV3Pool.sol";

6: import {IUniswapV3Pool} from "univ3-core/interfaces/IUniswapV3Pool.sol";

6: import {IUniswapV3Pool} from "univ3-core/interfaces/IUniswapV3Pool.sol";

8: import {ERC1155} from "@tokens/ERC1155Minimal.sol";

9: import {Multicall} from "@multicall/Multicall.sol";

11: import {CallbackLib} from "@libraries/CallbackLib.sol";

12: import {Constants} from "@libraries/Constants.sol";

13: import {Errors} from "@libraries/Errors.sol";

14: import {FeesCalc} from "@libraries/FeesCalc.sol";

15: import {Math} from "@libraries/Math.sol";

16: import {PanopticMath} from "@libraries/PanopticMath.sol";

17: import {SafeTransferLib} from "@libraries/SafeTransferLib.sol";

19: import {LeftRight} from "@types/LeftRight.sol";

20: import {LiquidityChunk} from "@types/LiquidityChunk.sol";

21: import {TokenId} from "@types/TokenId.sol";

111:     using TokenId for uint256; // an option position

111:     using TokenId for uint256; // an option position

112:     using LiquidityChunk for uint256; // a leg within an option position `tokenId`

112:     using LiquidityChunk for uint256; // a leg within an option position `tokenId`

161:           │  ┌────┐-T      due isLong=1   in the UniswapV3Pool 

163:           │  │    │                        ┌────┐-(T-R)  

163:           │  │    │                        ┌────┐-(T-R)  

164:           │  │    │         ┌────┐-R       │    │          

167:              total=T       removed=R      net=(T-R)

184:         keep track of the amount of fees that *would have been collected*, we call this the owed

184:         keep track of the amount of fees that *would have been collected*, we call this the owed

192:         same tick using a tokenId with a isLong=1 parameter. Because the netLiquidity is only (T-R),

195:               net_feesCollectedX128 = feeGrowthX128 * (T - R)

195:               net_feesCollectedX128 = feeGrowthX128 * (T - R)

196:                                     = feeGrowthX128 * N                                     

198:         where N = netLiquidity = T-R. Had that liquidity never been removed, we want the gross

201:               gross_feesCollectedX128 = feeGrowthX128 * T

209:               gross_feesCollectedX128 = net_feesCollectedX128 + owed_feesCollectedX128

213:               owed_feesCollectedX128 = feeGrowthX128 * R * (1 + spread)                      (Eqn 1)

213:               owed_feesCollectedX128 = feeGrowthX128 * R * (1 + spread)                      (Eqn 1)

213:               owed_feesCollectedX128 = feeGrowthX128 * R * (1 + spread)                      (Eqn 1)

217:               spread = ν*(liquidity removed from that strike)/(netLiquidity remaining at that strike)

217:               spread = ν*(liquidity removed from that strike)/(netLiquidity remaining at that strike)

218:                      = ν*R/N

218:                      = ν*R/N

222:               gross_feesCollectedX128 = feeGrowthX128 * N + feeGrowthX128*R*(1 + ν*R/N) 

222:               gross_feesCollectedX128 = feeGrowthX128 * N + feeGrowthX128*R*(1 + ν*R/N) 

222:               gross_feesCollectedX128 = feeGrowthX128 * N + feeGrowthX128*R*(1 + ν*R/N) 

222:               gross_feesCollectedX128 = feeGrowthX128 * N + feeGrowthX128*R*(1 + ν*R/N) 

222:               gross_feesCollectedX128 = feeGrowthX128 * N + feeGrowthX128*R*(1 + ν*R/N) 

222:               gross_feesCollectedX128 = feeGrowthX128 * N + feeGrowthX128*R*(1 + ν*R/N) 

222:               gross_feesCollectedX128 = feeGrowthX128 * N + feeGrowthX128*R*(1 + ν*R/N) 

223:                                       = feeGrowthX128 * T + feesGrowthX128*ν*R^2/N         

223:                                       = feeGrowthX128 * T + feesGrowthX128*ν*R^2/N         

223:                                       = feeGrowthX128 * T + feesGrowthX128*ν*R^2/N         

223:                                       = feeGrowthX128 * T + feesGrowthX128*ν*R^2/N         

223:                                       = feeGrowthX128 * T + feesGrowthX128*ν*R^2/N         

224:                                       = feeGrowthX128 * T * (1 + ν*R^2/(N*T))                (Eqn 2)

224:                                       = feeGrowthX128 * T * (1 + ν*R^2/(N*T))                (Eqn 2)

224:                                       = feeGrowthX128 * T * (1 + ν*R^2/(N*T))                (Eqn 2)

224:                                       = feeGrowthX128 * T * (1 + ν*R^2/(N*T))                (Eqn 2)

224:                                       = feeGrowthX128 * T * (1 + ν*R^2/(N*T))                (Eqn 2)

224:                                       = feeGrowthX128 * T * (1 + ν*R^2/(N*T))                (Eqn 2)

226:         The s_accountPremiumOwed accumulator tracks the feeGrowthX128 * R * (1 + spread) term

226:         The s_accountPremiumOwed accumulator tracks the feeGrowthX128 * R * (1 + spread) term

226:         The s_accountPremiumOwed accumulator tracks the feeGrowthX128 * R * (1 + spread) term

229:               s_accountPremiumOwed += feeGrowthX128 * R * (1 + ν*R/N) / R

229:               s_accountPremiumOwed += feeGrowthX128 * R * (1 + ν*R/N) / R

229:               s_accountPremiumOwed += feeGrowthX128 * R * (1 + ν*R/N) / R

229:               s_accountPremiumOwed += feeGrowthX128 * R * (1 + ν*R/N) / R

229:               s_accountPremiumOwed += feeGrowthX128 * R * (1 + ν*R/N) / R

229:               s_accountPremiumOwed += feeGrowthX128 * R * (1 + ν*R/N) / R

229:               s_accountPremiumOwed += feeGrowthX128 * R * (1 + ν*R/N) / R

230:                                    += feeGrowthX128 * (T - R + ν*R)/N

230:                                    += feeGrowthX128 * (T - R + ν*R)/N

230:                                    += feeGrowthX128 * (T - R + ν*R)/N

230:                                    += feeGrowthX128 * (T - R + ν*R)/N

230:                                    += feeGrowthX128 * (T - R + ν*R)/N

230:                                    += feeGrowthX128 * (T - R + ν*R)/N

231:                                    += feeGrowthX128 * T/N * (1 - R/T + ν*R/T)

231:                                    += feeGrowthX128 * T/N * (1 - R/T + ν*R/T)

231:                                    += feeGrowthX128 * T/N * (1 - R/T + ν*R/T)

231:                                    += feeGrowthX128 * T/N * (1 - R/T + ν*R/T)

231:                                    += feeGrowthX128 * T/N * (1 - R/T + ν*R/T)

231:                                    += feeGrowthX128 * T/N * (1 - R/T + ν*R/T)

231:                                    += feeGrowthX128 * T/N * (1 - R/T + ν*R/T)

231:                                    += feeGrowthX128 * T/N * (1 - R/T + ν*R/T)

231:                                    += feeGrowthX128 * T/N * (1 - R/T + ν*R/T)

237:              feesCollected = feesGrowthX128 * (T-R)

237:              feesCollected = feesGrowthX128 * (T-R)

241:              feesGrowthX128 = feesCollected/N

245:              s_accountPremiumOwed += feesCollected * T/N^2 * (1 - R/T + ν*R/T)          (Eqn 3)     

245:              s_accountPremiumOwed += feesCollected * T/N^2 * (1 - R/T + ν*R/T)          (Eqn 3)     

245:              s_accountPremiumOwed += feesCollected * T/N^2 * (1 - R/T + ν*R/T)          (Eqn 3)     

245:              s_accountPremiumOwed += feesCollected * T/N^2 * (1 - R/T + ν*R/T)          (Eqn 3)     

245:              s_accountPremiumOwed += feesCollected * T/N^2 * (1 - R/T + ν*R/T)          (Eqn 3)     

245:              s_accountPremiumOwed += feesCollected * T/N^2 * (1 - R/T + ν*R/T)          (Eqn 3)     

245:              s_accountPremiumOwed += feesCollected * T/N^2 * (1 - R/T + ν*R/T)          (Eqn 3)     

245:              s_accountPremiumOwed += feesCollected * T/N^2 * (1 - R/T + ν*R/T)          (Eqn 3)     

245:              s_accountPremiumOwed += feesCollected * T/N^2 * (1 - R/T + ν*R/T)          (Eqn 3)     

250:              owedPremia(t1, t2) = (s_accountPremiumOwed_t2-s_accountPremiumOwed_t1) * r

250:              owedPremia(t1, t2) = (s_accountPremiumOwed_t2-s_accountPremiumOwed_t1) * r

251:                                 = ∆feesGrowthX128 * r * T/N * (1 - R/T + ν*R/T)

251:                                 = ∆feesGrowthX128 * r * T/N * (1 - R/T + ν*R/T)

251:                                 = ∆feesGrowthX128 * r * T/N * (1 - R/T + ν*R/T)

251:                                 = ∆feesGrowthX128 * r * T/N * (1 - R/T + ν*R/T)

251:                                 = ∆feesGrowthX128 * r * T/N * (1 - R/T + ν*R/T)

251:                                 = ∆feesGrowthX128 * r * T/N * (1 - R/T + ν*R/T)

251:                                 = ∆feesGrowthX128 * r * T/N * (1 - R/T + ν*R/T)

251:                                 = ∆feesGrowthX128 * r * T/N * (1 - R/T + ν*R/T)

251:                                 = ∆feesGrowthX128 * r * T/N * (1 - R/T + ν*R/T)

252:                                 = ∆feesGrowthX128 * r * (T - R + ν*R)/N

252:                                 = ∆feesGrowthX128 * r * (T - R + ν*R)/N

252:                                 = ∆feesGrowthX128 * r * (T - R + ν*R)/N

252:                                 = ∆feesGrowthX128 * r * (T - R + ν*R)/N

252:                                 = ∆feesGrowthX128 * r * (T - R + ν*R)/N

252:                                 = ∆feesGrowthX128 * r * (T - R + ν*R)/N

253:                                 = ∆feesGrowthX128 * r * (N + ν*R)/N

253:                                 = ∆feesGrowthX128 * r * (N + ν*R)/N

253:                                 = ∆feesGrowthX128 * r * (N + ν*R)/N

253:                                 = ∆feesGrowthX128 * r * (N + ν*R)/N

253:                                 = ∆feesGrowthX128 * r * (N + ν*R)/N

254:                                 = ∆feesGrowthX128 * r * (1 + ν*R/N)             (same as Eqn 1)

254:                                 = ∆feesGrowthX128 * r * (1 + ν*R/N)             (same as Eqn 1)

254:                                 = ∆feesGrowthX128 * r * (1 + ν*R/N)             (same as Eqn 1)

254:                                 = ∆feesGrowthX128 * r * (1 + ν*R/N)             (same as Eqn 1)

254:                                 = ∆feesGrowthX128 * r * (1 + ν*R/N)             (same as Eqn 1)

261:         However, since we require that Eqn 2 holds up-- ie. the gross fees collected should be equal

261:         However, since we require that Eqn 2 holds up-- ie. the gross fees collected should be equal

265:             s_accountPremiumGross += feesCollected * T/N^2 * (1 - R/T + ν*R^2/T^2)       (Eqn 4) 

265:             s_accountPremiumGross += feesCollected * T/N^2 * (1 - R/T + ν*R^2/T^2)       (Eqn 4) 

265:             s_accountPremiumGross += feesCollected * T/N^2 * (1 - R/T + ν*R^2/T^2)       (Eqn 4) 

265:             s_accountPremiumGross += feesCollected * T/N^2 * (1 - R/T + ν*R^2/T^2)       (Eqn 4) 

265:             s_accountPremiumGross += feesCollected * T/N^2 * (1 - R/T + ν*R^2/T^2)       (Eqn 4) 

265:             s_accountPremiumGross += feesCollected * T/N^2 * (1 - R/T + ν*R^2/T^2)       (Eqn 4) 

265:             s_accountPremiumGross += feesCollected * T/N^2 * (1 - R/T + ν*R^2/T^2)       (Eqn 4) 

265:             s_accountPremiumGross += feesCollected * T/N^2 * (1 - R/T + ν*R^2/T^2)       (Eqn 4) 

265:             s_accountPremiumGross += feesCollected * T/N^2 * (1 - R/T + ν*R^2/T^2)       (Eqn 4) 

270:             grossPremia(t1, t2) = ∆(s_accountPremiumGross) * t

271:                                 = ∆feeGrowthX128 * t * T/N * (1 - R/T + ν*R^2/T^2) 

271:                                 = ∆feeGrowthX128 * t * T/N * (1 - R/T + ν*R^2/T^2) 

271:                                 = ∆feeGrowthX128 * t * T/N * (1 - R/T + ν*R^2/T^2) 

271:                                 = ∆feeGrowthX128 * t * T/N * (1 - R/T + ν*R^2/T^2) 

271:                                 = ∆feeGrowthX128 * t * T/N * (1 - R/T + ν*R^2/T^2) 

271:                                 = ∆feeGrowthX128 * t * T/N * (1 - R/T + ν*R^2/T^2) 

271:                                 = ∆feeGrowthX128 * t * T/N * (1 - R/T + ν*R^2/T^2) 

271:                                 = ∆feeGrowthX128 * t * T/N * (1 - R/T + ν*R^2/T^2) 

271:                                 = ∆feeGrowthX128 * t * T/N * (1 - R/T + ν*R^2/T^2) 

272:                                 = ∆feeGrowthX128 * t * (T - R + ν*R^2/T) / N 

272:                                 = ∆feeGrowthX128 * t * (T - R + ν*R^2/T) / N 

272:                                 = ∆feeGrowthX128 * t * (T - R + ν*R^2/T) / N 

272:                                 = ∆feeGrowthX128 * t * (T - R + ν*R^2/T) / N 

272:                                 = ∆feeGrowthX128 * t * (T - R + ν*R^2/T) / N 

272:                                 = ∆feeGrowthX128 * t * (T - R + ν*R^2/T) / N 

272:                                 = ∆feeGrowthX128 * t * (T - R + ν*R^2/T) / N 

273:                                 = ∆feeGrowthX128 * t * (N + ν*R^2/T) / N

273:                                 = ∆feeGrowthX128 * t * (N + ν*R^2/T) / N

273:                                 = ∆feeGrowthX128 * t * (N + ν*R^2/T) / N

273:                                 = ∆feeGrowthX128 * t * (N + ν*R^2/T) / N

273:                                 = ∆feeGrowthX128 * t * (N + ν*R^2/T) / N

273:                                 = ∆feeGrowthX128 * t * (N + ν*R^2/T) / N

274:                                 = ∆feeGrowthX128 * t * (1  + ν*R^2/(N*T))   (same as Eqn 2)

274:                                 = ∆feeGrowthX128 * t * (1  + ν*R^2/(N*T))   (same as Eqn 2)

274:                                 = ∆feeGrowthX128 * t * (1  + ν*R^2/(N*T))   (same as Eqn 2)

274:                                 = ∆feeGrowthX128 * t * (1  + ν*R^2/(N*T))   (same as Eqn 2)

274:                                 = ∆feeGrowthX128 * t * (1  + ν*R^2/(N*T))   (same as Eqn 2)

274:                                 = ∆feeGrowthX128 * t * (1  + ν*R^2/(N*T))   (same as Eqn 2)

279:         long+short liquidity to guarantee that liquidity deposited always receives the correct

384:             s_AddrToPoolIdData[univ3pool] = uint256(poolId) + 2 ** 255;

384:             s_AddrToPoolIdData[univ3pool] = uint256(poolId) + 2 ** 255;

384:             s_AddrToPoolIdData[univ3pool] = uint256(poolId) + 2 ** 255;

464:                        PUBLIC MINT/BURN FUNCTIONS

553:                 ++i;

553:                 ++i;

632:                 ++leg;

632:                 ++leg;

748:         bool zeroForOne; // The direction of the swap, true for token0 to token1, false for token1 to token0

748:         bool zeroForOne; // The direction of the swap, true for token0 to token1, false for token1 to token0

749:         int256 swapAmount; // The amount of token0 or token1 to swap

749:         int256 swapAmount; // The amount of token0 or token1 to swap

804:                 int256 net0 = itm0 - PanopticMath.convert1to0(itm1, sqrtPriceX96);

809:                 swapAmount = -net0;

812:                 swapAmount = -itm0;

815:                 swapAmount = -itm1;

829:                     ? Constants.MIN_V3POOL_SQRT_RATIO + 1

830:                     : Constants.MAX_V3POOL_SQRT_RATIO - 1,

877:                     _leg = _isBurn ? numLegs - leg - 1 : leg;

877:                     _leg = _isBurn ? numLegs - leg - 1 : leg;

899:                     amount0 += Math.getAmount0ForLiquidity(liquidityChunk);

901:                     amount1 += Math.getAmount1ForLiquidity(liquidityChunk);

910:                 ++leg;

910:                 ++leg;

959:         uint256 currentLiquidity = s_accountLiquidity[positionKey]; //cache

959:         uint256 currentLiquidity = s_accountLiquidity[positionKey]; //cache

974:                 updatedLiquidity = startingLiquidity + chunkLiquidity;

979:                     removedLiquidity -= chunkLiquidity;

993:                     updatedLiquidity = startingLiquidity - chunkLiquidity;

999:                     removedLiquidity += chunkLiquidity;

1033:                 : _burnLiquidity(_liquidityChunk, _univ3pool); // from msg.sender to Uniswap

1033:                 : _burnLiquidity(_liquidityChunk, _univ3pool); // from msg.sender to Uniswap

1135:             CallbackLib.CallbackData({ // compute by reading values from univ3pool every time

1135:             CallbackLib.CallbackData({ // compute by reading values from univ3pool every time

1186:             movedAmounts = int256(0).toRightSlot(-int128(int256(amount0))).toLeftSlot(

1187:                 -int128(int256(amount1))

1235:                     ? receivedAmount0 - uint128(-movedInLeg.rightSlot())

1235:                     ? receivedAmount0 - uint128(-movedInLeg.rightSlot())

1238:                     ? receivedAmount1 - uint128(-movedInLeg.leftSlot())

1238:                     ? receivedAmount1 - uint128(-movedInLeg.leftSlot())

1270:             uint256 totalLiquidity = netLiquidity + removedLiquidity;

1281:                     .mulDiv(collected0, totalLiquidity * 2 ** 64, netLiquidity ** 2)

1281:                     .mulDiv(collected0, totalLiquidity * 2 ** 64, netLiquidity ** 2)

1281:                     .mulDiv(collected0, totalLiquidity * 2 ** 64, netLiquidity ** 2)

1281:                     .mulDiv(collected0, totalLiquidity * 2 ** 64, netLiquidity ** 2)

1281:                     .mulDiv(collected0, totalLiquidity * 2 ** 64, netLiquidity ** 2)

1284:                     .mulDiv(collected1, totalLiquidity * 2 ** 64, netLiquidity ** 2)

1284:                     .mulDiv(collected1, totalLiquidity * 2 ** 64, netLiquidity ** 2)

1284:                     .mulDiv(collected1, totalLiquidity * 2 ** 64, netLiquidity ** 2)

1284:                     .mulDiv(collected1, totalLiquidity * 2 ** 64, netLiquidity ** 2)

1284:                     .mulDiv(collected1, totalLiquidity * 2 ** 64, netLiquidity ** 2)

1293:                     uint256 numerator = netLiquidity + (removedLiquidity / 2 ** VEGOID);

1293:                     uint256 numerator = netLiquidity + (removedLiquidity / 2 ** VEGOID);

1293:                     uint256 numerator = netLiquidity + (removedLiquidity / 2 ** VEGOID);

1293:                     uint256 numerator = netLiquidity + (removedLiquidity / 2 ** VEGOID);

1313:                     uint256 numerator = totalLiquidity ** 2 -

1313:                     uint256 numerator = totalLiquidity ** 2 -

1313:                     uint256 numerator = totalLiquidity ** 2 -

1314:                         totalLiquidity *

1315:                         removedLiquidity +

1316:                         ((removedLiquidity ** 2) / 2 ** (VEGOID));

1316:                         ((removedLiquidity ** 2) / 2 ** (VEGOID));

1316:                         ((removedLiquidity ** 2) / 2 ** (VEGOID));

1316:                         ((removedLiquidity ** 2) / 2 ** (VEGOID));

1316:                         ((removedLiquidity ** 2) / 2 ** (VEGOID));

1318:                         .mulDiv(premium0X64_base, numerator, totalLiquidity ** 2)

1318:                         .mulDiv(premium0X64_base, numerator, totalLiquidity ** 2)

1321:                         .mulDiv(premium1X64_base, numerator, totalLiquidity ** 2)

1321:                         .mulDiv(premium1X64_base, numerator, totalLiquidity ** 2)

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/SemiFungiblePositionManager.sol)

```solidity
File: contracts/libraries/CallbackLib.sol

5: import {Constants} from "@libraries/Constants.sol";

6: import {Errors} from "@libraries/Errors.sol";

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/libraries/CallbackLib.sol)

```solidity
File: contracts/libraries/Constants.sol

11:     int24 internal constant MIN_V3POOL_TICK = -887272;

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/libraries/Constants.sol)

```solidity
File: contracts/libraries/FeesCalc.sol

5: import {IUniswapV3Pool} from "univ3-core/interfaces/IUniswapV3Pool.sol";

5: import {IUniswapV3Pool} from "univ3-core/interfaces/IUniswapV3Pool.sol";

5: import {IUniswapV3Pool} from "univ3-core/interfaces/IUniswapV3Pool.sol";

7: import {Math} from "@libraries/Math.sol";

9: import {LeftRight} from "@types/LeftRight.sol";

10: import {LiquidityChunk} from "@types/LiquidityChunk.sol";

11: import {TokenId} from "@types/TokenId.sol";

125:                 feeGrowthInside0X128 = lowerOut0 - upperOut0; // fee growth inside the chunk

125:                 feeGrowthInside0X128 = lowerOut0 - upperOut0; // fee growth inside the chunk

125:                 feeGrowthInside0X128 = lowerOut0 - upperOut0; // fee growth inside the chunk

126:                 feeGrowthInside1X128 = lowerOut1 - upperOut1;

142:                 feeGrowthInside0X128 = upperOut0 - lowerOut0;

143:                 feeGrowthInside1X128 = upperOut1 - lowerOut1;

163:                 feeGrowthInside0X128 = univ3pool.feeGrowthGlobal0X128() - lowerOut0 - upperOut0;

163:                 feeGrowthInside0X128 = univ3pool.feeGrowthGlobal0X128() - lowerOut0 - upperOut0;

164:                 feeGrowthInside1X128 = univ3pool.feeGrowthGlobal1X128() - lowerOut1 - upperOut1;

164:                 feeGrowthInside1X128 = univ3pool.feeGrowthGlobal1X128() - lowerOut1 - upperOut1;

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/libraries/FeesCalc.sol)

```solidity
File: contracts/libraries/Math.sol

5: import {Errors} from "@libraries/Errors.sol";

6: import {Constants} from "@libraries/Constants.sol";

8: import {LiquidityChunk} from "@types/LiquidityChunk.sol";

13:     using LiquidityChunk for uint256; // a leg within an option position `tokenId`

13:     using LiquidityChunk for uint256; // a leg within an option position `tokenId`

25:             return x > 0 ? uint256(x) : uint256(-x);

40:             uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));

47:             if (absTick & 0x2 != 0) sqrtR = (sqrtR * 0xfff97272373d413259a46990580e213a) >> 128;

49:             if (absTick & 0x4 != 0) sqrtR = (sqrtR * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;

51:             if (absTick & 0x8 != 0) sqrtR = (sqrtR * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;

53:             if (absTick & 0x10 != 0) sqrtR = (sqrtR * 0xffcb9843d60f6159c9db58835c926644) >> 128;

55:             if (absTick & 0x20 != 0) sqrtR = (sqrtR * 0xff973b41fa98c081472e6896dfb254c0) >> 128;

57:             if (absTick & 0x40 != 0) sqrtR = (sqrtR * 0xff2ea16466c96a3843ec78b326b52861) >> 128;

59:             if (absTick & 0x80 != 0) sqrtR = (sqrtR * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;

61:             if (absTick & 0x100 != 0) sqrtR = (sqrtR * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;

63:             if (absTick & 0x200 != 0) sqrtR = (sqrtR * 0xf987a7253ac413176f2b074cf7815e54) >> 128;

65:             if (absTick & 0x400 != 0) sqrtR = (sqrtR * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;

67:             if (absTick & 0x800 != 0) sqrtR = (sqrtR * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;

69:             if (absTick & 0x1000 != 0) sqrtR = (sqrtR * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;

71:             if (absTick & 0x2000 != 0) sqrtR = (sqrtR * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;

73:             if (absTick & 0x4000 != 0) sqrtR = (sqrtR * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;

75:             if (absTick & 0x8000 != 0) sqrtR = (sqrtR * 0x31be135f97d08fd981231505542fcfa6) >> 128;

77:             if (absTick & 0x10000 != 0) sqrtR = (sqrtR * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;

79:             if (absTick & 0x20000 != 0) sqrtR = (sqrtR * 0x5d6af8dedb81196699c329225ee604) >> 128;

81:             if (absTick & 0x40000 != 0) sqrtR = (sqrtR * 0x2216e584f5fa1ea926041bedfe98) >> 128;

83:             if (absTick & 0x80000 != 0) sqrtR = (sqrtR * 0x48a170391f7dc42444e8fa2) >> 128;

86:             if (tick > 0) sqrtR = type(uint256).max / sqrtR;

89:             sqrtPriceX96 = uint160((sqrtR >> 32) + (sqrtR % (1 << 32) == 0 ? 0 : 1));

94:                     LIQUIDITY AMOUNTS (STRIKE+WIDTH)

110:                     highPriceX96 - lowPriceX96,

112:                 ) / lowPriceX96;

126:             return mulDiv96(liquidityChunk.liquidity(), highPriceX96 - lowPriceX96);

145:                     mulDiv(amount0, mulDiv96(highPriceX96, lowPriceX96), highPriceX96 - lowPriceX96)

161:             return toUint128(mulDiv(amount1, Constants.FP96, highPriceX96 - lowPriceX96));

197:             uint256 prod0; // Least significant 256 bits of the product

197:             uint256 prod0; // Least significant 256 bits of the product

198:             uint256 prod1; // Most significant 256 bits of the product

198:             uint256 prod1; // Most significant 256 bits of the product

199:             assembly ("memory-safe") {

208:                 assembly ("memory-safe") {

225:             assembly ("memory-safe") {

229:             assembly ("memory-safe") {

237:             uint256 twos = (0 - denominator) & denominator;

239:             assembly ("memory-safe") {

244:             assembly ("memory-safe") {

250:             assembly ("memory-safe") {

253:             prod0 |= prod1 * twos;

260:             uint256 inv = (3 * denominator) ^ 2;

264:             inv *= 2 - denominator * inv; // inverse mod 2**8

264:             inv *= 2 - denominator * inv; // inverse mod 2**8

264:             inv *= 2 - denominator * inv; // inverse mod 2**8

264:             inv *= 2 - denominator * inv; // inverse mod 2**8

264:             inv *= 2 - denominator * inv; // inverse mod 2**8

264:             inv *= 2 - denominator * inv; // inverse mod 2**8

264:             inv *= 2 - denominator * inv; // inverse mod 2**8

265:             inv *= 2 - denominator * inv; // inverse mod 2**16

265:             inv *= 2 - denominator * inv; // inverse mod 2**16

265:             inv *= 2 - denominator * inv; // inverse mod 2**16

265:             inv *= 2 - denominator * inv; // inverse mod 2**16

265:             inv *= 2 - denominator * inv; // inverse mod 2**16

265:             inv *= 2 - denominator * inv; // inverse mod 2**16

265:             inv *= 2 - denominator * inv; // inverse mod 2**16

266:             inv *= 2 - denominator * inv; // inverse mod 2**32

266:             inv *= 2 - denominator * inv; // inverse mod 2**32

266:             inv *= 2 - denominator * inv; // inverse mod 2**32

266:             inv *= 2 - denominator * inv; // inverse mod 2**32

266:             inv *= 2 - denominator * inv; // inverse mod 2**32

266:             inv *= 2 - denominator * inv; // inverse mod 2**32

266:             inv *= 2 - denominator * inv; // inverse mod 2**32

267:             inv *= 2 - denominator * inv; // inverse mod 2**64

267:             inv *= 2 - denominator * inv; // inverse mod 2**64

267:             inv *= 2 - denominator * inv; // inverse mod 2**64

267:             inv *= 2 - denominator * inv; // inverse mod 2**64

267:             inv *= 2 - denominator * inv; // inverse mod 2**64

267:             inv *= 2 - denominator * inv; // inverse mod 2**64

267:             inv *= 2 - denominator * inv; // inverse mod 2**64

268:             inv *= 2 - denominator * inv; // inverse mod 2**128

268:             inv *= 2 - denominator * inv; // inverse mod 2**128

268:             inv *= 2 - denominator * inv; // inverse mod 2**128

268:             inv *= 2 - denominator * inv; // inverse mod 2**128

268:             inv *= 2 - denominator * inv; // inverse mod 2**128

268:             inv *= 2 - denominator * inv; // inverse mod 2**128

268:             inv *= 2 - denominator * inv; // inverse mod 2**128

269:             inv *= 2 - denominator * inv; // inverse mod 2**256

269:             inv *= 2 - denominator * inv; // inverse mod 2**256

269:             inv *= 2 - denominator * inv; // inverse mod 2**256

269:             inv *= 2 - denominator * inv; // inverse mod 2**256

269:             inv *= 2 - denominator * inv; // inverse mod 2**256

269:             inv *= 2 - denominator * inv; // inverse mod 2**256

269:             inv *= 2 - denominator * inv; // inverse mod 2**256

277:             result = prod0 * inv;

293:             uint256 prod0; // Least significant 256 bits of the product

293:             uint256 prod0; // Least significant 256 bits of the product

294:             uint256 prod1; // Most significant 256 bits of the product

294:             uint256 prod1; // Most significant 256 bits of the product

295:             assembly ("memory-safe") {

303:                 assembly ("memory-safe") {

311:             require(2 ** 64 > prod1);

311:             require(2 ** 64 > prod1);

320:             assembly ("memory-safe") {

324:             assembly ("memory-safe") {

330:             assembly ("memory-safe") {

338:             prod0 |= prod1 * 2 ** 192;

338:             prod0 |= prod1 * 2 ** 192;

338:             prod0 |= prod1 * 2 ** 192;

355:             uint256 prod0; // Least significant 256 bits of the product

355:             uint256 prod0; // Least significant 256 bits of the product

356:             uint256 prod1; // Most significant 256 bits of the product

356:             uint256 prod1; // Most significant 256 bits of the product

357:             assembly ("memory-safe") {

365:                 assembly ("memory-safe") {

373:             require(2 ** 96 > prod1);

373:             require(2 ** 96 > prod1);

382:             assembly ("memory-safe") {

386:             assembly ("memory-safe") {

392:             assembly ("memory-safe") {

400:             prod0 |= prod1 * 2 ** 160;

400:             prod0 |= prod1 * 2 ** 160;

400:             prod0 |= prod1 * 2 ** 160;

417:             uint256 prod0; // Least significant 256 bits of the product

417:             uint256 prod0; // Least significant 256 bits of the product

418:             uint256 prod1; // Most significant 256 bits of the product

418:             uint256 prod1; // Most significant 256 bits of the product

419:             assembly ("memory-safe") {

427:                 assembly ("memory-safe") {

435:             require(2 ** 128 > prod1);

435:             require(2 ** 128 > prod1);

444:             assembly ("memory-safe") {

448:             assembly ("memory-safe") {

454:             assembly ("memory-safe") {

462:             prod0 |= prod1 * 2 ** 128;

462:             prod0 |= prod1 * 2 ** 128;

462:             prod0 |= prod1 * 2 ** 128;

479:             uint256 prod0; // Least significant 256 bits of the product

479:             uint256 prod0; // Least significant 256 bits of the product

480:             uint256 prod1; // Most significant 256 bits of the product

480:             uint256 prod1; // Most significant 256 bits of the product

481:             assembly ("memory-safe") {

489:                 assembly ("memory-safe") {

497:             require(2 ** 192 > prod1);

497:             require(2 ** 192 > prod1);

506:             assembly ("memory-safe") {

510:             assembly ("memory-safe") {

516:             assembly ("memory-safe") {

524:             prod0 |= prod1 * 2 ** 64;

524:             prod0 |= prod1 * 2 ** 64;

524:             prod0 |= prod1 * 2 ** 64;

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/libraries/Math.sol)

```solidity
File: contracts/libraries/PanopticMath.sol

5: import {Math} from "@libraries/Math.sol";

7: import {LeftRight} from "@types/LeftRight.sol";

8: import {LiquidityChunk} from "@types/LiquidityChunk.sol";

9: import {TokenId} from "@types/TokenId.sol";

56:                 basePoolId +

119:         uint256 amount = uint256(positionSize) * tokenId.optionRatio(legIndex);

151:                     .mulDiv192(Math.absUint(amount), uint256(sqrtPriceX96) ** 2)

151:                     .mulDiv192(Math.absUint(amount), uint256(sqrtPriceX96) ** 2)

153:                 return amount < 0 ? -absResult : absResult;

158:                 return amount < 0 ? -absResult : absResult;

174:                     .mulDiv(Math.absUint(amount), 2 ** 192, uint256(sqrtPriceX96) ** 2)

174:                     .mulDiv(Math.absUint(amount), 2 ** 192, uint256(sqrtPriceX96) ** 2)

174:                     .mulDiv(Math.absUint(amount), 2 ** 192, uint256(sqrtPriceX96) ** 2)

174:                     .mulDiv(Math.absUint(amount), 2 ** 192, uint256(sqrtPriceX96) ** 2)

176:                 return amount < 0 ? -absResult : absResult;

181:                         2 ** 128,

181:                         2 ** 128,

185:                 return amount < 0 ? -absResult : absResult;

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/libraries/PanopticMath.sol)

```solidity
File: contracts/libraries/SafeTransferLib.sol

5: import {Errors} from "@libraries/Errors.sol";

19:         assembly ("memory-safe") {

25:             mstore(add(4, p), from) // Append the "from" argument.

25:             mstore(add(4, p), from) // Append the "from" argument.

26:             mstore(add(36, p), to) // Append the "to" argument.

26:             mstore(add(36, p), to) // Append the "to" argument.

27:             mstore(add(68, p), amount) // Append the "amount" argument.

27:             mstore(add(68, p), amount) // Append the "amount" argument.

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/libraries/SafeTransferLib.sol)

```solidity
File: contracts/multicall/Multicall.sol

25:                 assembly ("memory-safe") {

33:                 ++i;

33:                 ++i;

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/multicall/Multicall.sol)

```solidity
File: contracts/tokens/ERC1155Minimal.sol

5: import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

5: import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

5: import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

5: import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

5: import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

99:         balanceOf[from][id] -= amount;

103:             balanceOf[to][id] += amount;

145:             balanceOf[from][id] -= amount;

149:                 balanceOf[to][id] += amount;

155:                 ++i;

155:                 ++i;

187:             for (uint256 i = 0; i < owners.length; ++i) {

187:             for (uint256 i = 0; i < owners.length; ++i) {

202:             interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165

202:             interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165

203:             interfaceId == 0xd9b67a26; // ERC165 Interface ID for ERC1155

203:             interfaceId == 0xd9b67a26; // ERC165 Interface ID for ERC1155

207:                         INTERNAL MINT/BURN LOGIC

217:             balanceOf[to][id] += amount;

237:         balanceOf[from][id] -= amount;

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/tokens/ERC1155Minimal.sol)

```solidity
File: contracts/types/LeftRight.sol

5: import {Errors} from "@libraries/Errors.sol";

46:             return self + uint256(right);

57:             return self + uint256(int256(right));

67:             return self + int256(uint256(right));

78:             return self + (int256(right) & RIGHT_HALF_BIT_MASK);

110:             return self + (uint256(left) << 128);

120:             return self + (int256(int128(left)) << 128);

130:             return self + (int256(left) << 128);

146:             z = x + y;

161:             int256 left256 = int256(x.leftSlot()) + y.leftSlot();

164:             int256 right256 = int256(x.rightSlot()) + y.rightSlot();

179:             int256 left256 = int256(x.leftSlot()) - y.leftSlot();

182:             int256 right256 = int256(x.rightSlot()) - y.rightSlot();

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/types/LeftRight.sol)

```solidity
File: contracts/types/LiquidityChunk.sol

5: import {TokenId} from "@types/TokenId.sol";

80:             return self + uint256(amount);

90:             return self + (uint256(uint24(_tickLower)) << 232);

101:             return self + ((uint256(uint24(_tickUpper))) << 208);

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/types/LiquidityChunk.sol)

```solidity
File: contracts/types/TokenId.sol

5: import {Constants} from "@libraries/Constants.sol";

6: import {Errors} from "@libraries/Errors.sol";

95:             return uint256((self >> (64 + legIndex * 48)) % 2);

95:             return uint256((self >> (64 + legIndex * 48)) % 2);

105:             return uint256((self >> (64 + legIndex * 48 + 1)) % 128);

105:             return uint256((self >> (64 + legIndex * 48 + 1)) % 128);

105:             return uint256((self >> (64 + legIndex * 48 + 1)) % 128);

115:             return uint256((self >> (64 + legIndex * 48 + 8)) % 2);

115:             return uint256((self >> (64 + legIndex * 48 + 8)) % 2);

115:             return uint256((self >> (64 + legIndex * 48 + 8)) % 2);

125:             return uint256((self >> (64 + legIndex * 48 + 9)) % 2);

125:             return uint256((self >> (64 + legIndex * 48 + 9)) % 2);

125:             return uint256((self >> (64 + legIndex * 48 + 9)) % 2);

141:             return uint256((self >> (64 + legIndex * 48 + 10)) % 4);

141:             return uint256((self >> (64 + legIndex * 48 + 10)) % 4);

141:             return uint256((self >> (64 + legIndex * 48 + 10)) % 4);

151:             return int24(int256(self >> (64 + legIndex * 48 + 12)));

151:             return int24(int256(self >> (64 + legIndex * 48 + 12)));

151:             return int24(int256(self >> (64 + legIndex * 48 + 12)));

162:             return int24(int256((self >> (64 + legIndex * 48 + 36)) % 4096));

162:             return int24(int256((self >> (64 + legIndex * 48 + 36)) % 4096));

162:             return int24(int256((self >> (64 + legIndex * 48 + 36)) % 4096));

163:         } // "% 4096" = take last (2 ** 12 = 4096) 12 bits

163:         } // "% 4096" = take last (2 ** 12 = 4096) 12 bits

163:         } // "% 4096" = take last (2 ** 12 = 4096) 12 bits

163:         } // "% 4096" = take last (2 ** 12 = 4096) 12 bits

175:             return self + uint256(_poolId);

195:             return self + (uint256(_asset % 2) << (64 + legIndex * 48));

195:             return self + (uint256(_asset % 2) << (64 + legIndex * 48));

195:             return self + (uint256(_asset % 2) << (64 + legIndex * 48));

210:             return self + (uint256(_optionRatio % 128) << (64 + legIndex * 48 + 1));

210:             return self + (uint256(_optionRatio % 128) << (64 + legIndex * 48 + 1));

210:             return self + (uint256(_optionRatio % 128) << (64 + legIndex * 48 + 1));

210:             return self + (uint256(_optionRatio % 128) << (64 + legIndex * 48 + 1));

226:             return self + ((_isLong % 2) << (64 + legIndex * 48 + 8));

226:             return self + ((_isLong % 2) << (64 + legIndex * 48 + 8));

226:             return self + ((_isLong % 2) << (64 + legIndex * 48 + 8));

226:             return self + ((_isLong % 2) << (64 + legIndex * 48 + 8));

240:             return self + (uint256(_tokenType % 2) << (64 + legIndex * 48 + 9));

240:             return self + (uint256(_tokenType % 2) << (64 + legIndex * 48 + 9));

240:             return self + (uint256(_tokenType % 2) << (64 + legIndex * 48 + 9));

240:             return self + (uint256(_tokenType % 2) << (64 + legIndex * 48 + 9));

254:             return self + (uint256(_riskPartner % 4) << (64 + legIndex * 48 + 10));

254:             return self + (uint256(_riskPartner % 4) << (64 + legIndex * 48 + 10));

254:             return self + (uint256(_riskPartner % 4) << (64 + legIndex * 48 + 10));

254:             return self + (uint256(_riskPartner % 4) << (64 + legIndex * 48 + 10));

268:             return self + uint256((int256(_strike) & BITMASK_INT24) << (64 + legIndex * 48 + 12));

268:             return self + uint256((int256(_strike) & BITMASK_INT24) << (64 + legIndex * 48 + 12));

268:             return self + uint256((int256(_strike) & BITMASK_INT24) << (64 + legIndex * 48 + 12));

268:             return self + uint256((int256(_strike) & BITMASK_INT24) << (64 + legIndex * 48 + 12));

283:             return self + (uint256(uint24(_width) % 4096) << (64 + legIndex * 48 + 36));

283:             return self + (uint256(uint24(_width) % 4096) << (64 + legIndex * 48 + 36));

283:             return self + (uint256(uint24(_width) % 4096) << (64 + legIndex * 48 + 36));

283:             return self + (uint256(uint24(_width) % 4096) << (64 + legIndex * 48 + 36));

337:             if (optionRatios < 2 ** 64) {

337:             if (optionRatios < 2 ** 64) {

339:             } else if (optionRatios < 2 ** 112) {

339:             } else if (optionRatios < 2 ** 112) {

341:             } else if (optionRatios < 2 ** 160) {

341:             } else if (optionRatios < 2 ** 160) {

343:             } else if (optionRatios < 2 ** 208) {

343:             } else if (optionRatios < 2 ** 208) {

353:             return self ^ ((LONG_MASK >> (48 * (4 - optionRatios))) & CLEAR_POOLID_MASK);

353:             return self ^ ((LONG_MASK >> (48 * (4 - optionRatios))) & CLEAR_POOLID_MASK);

363:             return self.isLong(0) + self.isLong(1) + self.isLong(2) + self.isLong(3);

363:             return self.isLong(0) + self.isLong(1) + self.isLong(2) + self.isLong(3);

363:             return self.isLong(0) + self.isLong(1) + self.isLong(2) + self.isLong(3);

385:             int24 minTick = (Constants.MIN_V3POOL_TICK / tickSpacing) * tickSpacing;

385:             int24 minTick = (Constants.MIN_V3POOL_TICK / tickSpacing) * tickSpacing;

386:             int24 maxTick = (Constants.MAX_V3POOL_TICK / tickSpacing) * tickSpacing;

386:             int24 maxTick = (Constants.MAX_V3POOL_TICK / tickSpacing) * tickSpacing;

389:             int24 oneSidedRange = (selfWidth * tickSpacing) / 2;

389:             int24 oneSidedRange = (selfWidth * tickSpacing) / 2;

391:             (legLowerTick, legUpperTick) = (selfStrike - oneSidedRange, selfStrike + oneSidedRange);

391:             (legLowerTick, legUpperTick) = (selfStrike - oneSidedRange, selfStrike + oneSidedRange);

417:         if (optionRatios < 2 ** 64) {

417:         if (optionRatios < 2 ** 64) {

419:         } else if (optionRatios < 2 ** 112) {

419:         } else if (optionRatios < 2 ** 112) {

421:         } else if (optionRatios < 2 ** 160) {

421:         } else if (optionRatios < 2 ** 160) {

423:         } else if (optionRatios < 2 ** 208) {

423:         } else if (optionRatios < 2 ** 208) {

468:             for (uint256 i = 0; i < 4; ++i) {

468:             for (uint256 i = 0; i < 4; ++i) {

473:                     if ((self >> (64 + 48 * i)) != 0) revert Errors.InvalidTokenIdParameter(1);

473:                     if ((self >> (64 + 48 * i)) != 0) revert Errors.InvalidTokenIdParameter(1);

475:                     break; // we are done iterating over potential legs

475:                     break; // we are done iterating over potential legs

520:             } // end for loop over legs

520:             } // end for loop over legs

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/types/TokenId.sol)

### <a name="GAS-5"></a>[GAS-5] Don't initialize variables with default value

*Instances (7)*:

```solidity
File: contracts/SemiFungiblePositionManager.sol

550:         for (uint256 i = 0; i < ids.length; ) {

583:         for (uint256 leg = 0; leg < numLegs; ) {

860:         for (uint256 leg = 0; leg < numLegs; ) {

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/SemiFungiblePositionManager.sol)

```solidity
File: contracts/multicall/Multicall.sol

14:         for (uint256 i = 0; i < data.length; ) {

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/multicall/Multicall.sol)

```solidity
File: contracts/tokens/ERC1155Minimal.sol

141:         for (uint256 i = 0; i < ids.length; ) {

187:             for (uint256 i = 0; i < owners.length; ++i) {

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/tokens/ERC1155Minimal.sol)

```solidity
File: contracts/types/TokenId.sol

468:             for (uint256 i = 0; i < 4; ++i) {

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/types/TokenId.sol)

### <a name="GAS-6"></a>[GAS-6] Use shift Right/Left instead of division/multiplication if possible

*Instances (1)*:

```solidity
File: contracts/SemiFungiblePositionManager.sol

1316:                         ((removedLiquidity ** 2) / 2 ** (VEGOID));

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/SemiFungiblePositionManager.sol)

### <a name="GAS-7"></a>[GAS-7] Use != 0 instead of > 0 for unsigned integer comparison

*Instances (12)*:

```solidity
File: contracts/SemiFungiblePositionManager.sol

220:         For an arbitrary parameter 0 <= ν <= 1. This way, the gross_feesCollectedX128 will be given by: 

417:         if (amount0Owed > 0)

424:         if (amount1Owed > 0)

452:         address token = amount0Delta > 0

457:         uint256 amountToPay = amount0Delta > 0 ? uint256(amount0Delta) : uint256(amount1Delta);

806:                 zeroForOne = net0 < 0;

811:                 zeroForOne = itm0 < 0;

814:                 zeroForOne = itm1 > 0;

1050:         if (currentLiquidity.rightSlot() > 0) {

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/SemiFungiblePositionManager.sol)

```solidity
File: contracts/libraries/Math.sol

25:             return x > 0 ? uint256(x) : uint256(-x);

86:             if (tick > 0) sqrtR = type(uint256).max / sqrtR;

207:                 require(denominator > 0);

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/libraries/Math.sol)

### <a name="GAS-8"></a>[GAS-8] `internal` functions not called by the contract should be removed

If the functions are required by an interface, the contract should inherit from that interface and use the `override` keyword

*Instances (57)*:

```solidity
File: contracts/libraries/CallbackLib.sol

28:     function validateCallback(

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/libraries/CallbackLib.sol)

```solidity
File: contracts/libraries/Math.sol

23:     function absUint(int256 x) internal pure returns (uint256) {

101:     function getAmount0ForLiquidity(

119:     function getAmount1ForLiquidity(

135:     function getLiquidityForAmount0(

154:     function getLiquidityForAmount1(

286:     function mulDiv64(uint256 a, uint256 b) internal pure returns (uint256 result) {

410:     function mulDiv128(uint256 a, uint256 b) internal pure returns (uint256 result) {

472:     function mulDiv192(uint256 a, uint256 b) internal pure returns (uint256 result) {

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/libraries/Math.sol)

```solidity
File: contracts/libraries/PanopticMath.sol

38:     function getPoolId(address univ3pool) internal pure returns (uint64) {

48:     function getFinalPoolId(

85:         uint128 positionSize,

145:     function convert0to1(int256 amount, uint160 sqrtPriceX96) internal pure returns (int256) {

168:     function convert1to0(int256 amount, uint160 sqrtPriceX96) internal pure returns (int256) {

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/libraries/PanopticMath.sol)

```solidity
File: contracts/libraries/SafeTransferLib.sol

16:     function safeTransferFrom(address token, address from, address to, uint256 amount) internal {

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/libraries/SafeTransferLib.sol)

```solidity
File: contracts/tokens/ERC1155Minimal.sol

214:     function _mint(address to, uint256 id, uint256 amount) internal {

236:     function _burn(address from, uint256 id, uint256 amount) internal {

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/tokens/ERC1155Minimal.sol)

```solidity
File: contracts/types/LeftRight.sol

25:     function rightSlot(uint256 self) internal pure returns (uint128) {

32:     function rightSlot(int256 self) internal pure returns (int128) {

44:     function toRightSlot(uint256 self, uint128 right) internal pure returns (uint256) {

54:     function toRightSlot(uint256 self, int128 right) internal pure returns (uint256) {

65:     function toRightSlot(int256 self, uint128 right) internal pure returns (int256) {

75:     function toRightSlot(int256 self, int128 right) internal pure returns (int256) {

89:     function leftSlot(uint256 self) internal pure returns (uint128) {

96:     function leftSlot(int256 self) internal pure returns (int128) {

108:     function toLeftSlot(uint256 self, uint128 left) internal pure returns (uint256) {

118:     function toLeftSlot(int256 self, uint128 left) internal pure returns (int256) {

128:     function toLeftSlot(int256 self, int128 left) internal pure returns (int256) {

142:     function add(uint256 x, uint256 y) internal pure returns (uint256 z) {

159:     function add(int256 x, int256 y) internal pure returns (int256 z) {

177:     function sub(int256 x, int256 y) internal pure returns (int256 z) {

198:     function toInt128(int256 self) internal pure returns (int128 selfAsInt128) {

205:     function toUint128(uint256 self) internal pure returns (uint128 selfAsUint128) {

212:     function toInt256(uint256 self) internal pure returns (int256) {

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/types/LeftRight.sol)

```solidity
File: contracts/types/LiquidityChunk.sol

68:     ) internal pure returns (uint256) {

80:             return self + uint256(amount);

90:             return self + (uint256(uint24(_tickLower)) << 232);

100:             // convert tick upper to uint24 as explicit conversion from int24 to uint256 is not allowed

116:     }

125:     }

136: 

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/types/LiquidityChunk.sol)

```solidity
File: contracts/types/TokenId.sol

80:     function univ3pool(uint256 self) internal pure returns (uint64) {

93:     function asset(uint256 self, uint256 legIndex) internal pure returns (uint256) {

103:     function optionRatio(uint256 self, uint256 legIndex) internal pure returns (uint256) {

113:     function isLong(uint256 self, uint256 legIndex) internal pure returns (uint256) {

123:     function tokenType(uint256 self, uint256 legIndex) internal pure returns (uint256) {

139:     function riskPartner(uint256 self, uint256 legIndex) internal pure returns (uint256) {

149:     function strike(uint256 self, uint256 legIndex) internal pure returns (int24) {

160:     function width(uint256 self, uint256 legIndex) internal pure returns (int24) {

173:     function addUniv3pool(uint256 self, uint64 _poolId) internal pure returns (uint256) {

298:     function addLeg(

327:     function flipToBurnToken(uint256 self) internal pure returns (uint256) {

361:     function countLongs(uint256 self) internal pure returns (uint256) {

374:     function asTicks(

410:     function countLegs(uint256 self) internal pure returns (uint256) {

442:     function clearLeg(uint256 self, uint256 i) internal pure returns (uint256) {

463:     function validate(uint256 self) internal pure returns (uint64) {

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/types/TokenId.sol)

## Non Critical Issues

| |Issue|Instances|
|-|:-|:-:|
| [NC-1](#NC-1) |  `require()` / `revert()` statements should have descriptive reason strings | 35 |
| [NC-2](#NC-2) | Event is missing `indexed` fields | 3 |
| [NC-3](#NC-3) | Constants should be defined rather than using magic numbers | 24 |
| [NC-4](#NC-4) | Functions not used internally could be marked external | 6 |

### <a name="NC-1"></a>[NC-1]  `require()` / `revert()` statements should have descriptive reason strings

*Instances (35)*:

```solidity
File: contracts/SemiFungiblePositionManager.sol

342:     constructor(IUniswapV3Factory _factory) {

367:         // @dev increase the poolId by a pseudo-random number

638:               AMM INTERACTION AND POSITION UPDATE HELPERS

642:     /// @notice This helper function checks:

702:             );

713:         if ((newTick >= tickLimitHigh) || (newTick <= tickLimitLow)) revert Errors.PriceBoundFail();

738:     ///   to be correctly in the money at that strike.

942:     ) internal returns (int256 _moved, int256 _itmAmounts, int256 _totalCollected) {

1016:                 ▲     ┌▼┐ liquidityChunk                 │

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/SemiFungiblePositionManager.sol)

```solidity
File: contracts/libraries/CallbackLib.sol

50:         ) revert Errors.InvalidUniswapCallback();

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/libraries/CallbackLib.sol)

```solidity
File: contracts/libraries/Math.sol

41:             if (absTick > uint256(int256(Constants.MAX_V3POOL_TICK))) revert Errors.InvalidTick();

173:         if ((downcastedInt = uint128(toDowncast)) != toDowncast) revert Errors.CastingError();

207:                 require(denominator > 0);

216:             require(denominator > prod1);

311:             require(2 ** 64 > prod1);

373:             require(2 ** 96 > prod1);

435:             require(2 ** 128 > prod1);

497:             require(2 ** 192 > prod1);

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/libraries/Math.sol)

```solidity
File: contracts/libraries/SafeTransferLib.sol

40:         if (!success) revert Errors.TransferFailed();

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/libraries/SafeTransferLib.sol)

```solidity
File: contracts/types/LeftRight.sol

55:         if (right < 0) revert Errors.LeftRightInputError();

151:             if (z < x || (uint128(z) < uint128(x))) revert Errors.UnderOverFlow();

167:             if (left128 != left256 || right128 != right256) revert Errors.UnderOverFlow();

185:             if (left128 != left256 || right128 != right256) revert Errors.UnderOverFlow();

199:         if (!((selfAsInt128 = int128(self)) == self)) revert Errors.CastingError();

206:         if (!((selfAsUint128 = uint128(self)) == self)) revert Errors.CastingError();

213:         if (self > uint256(type(int256).max)) revert Errors.CastingError();

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/types/LeftRight.sol)

```solidity
File: contracts/types/TokenId.sol

401:             ) revert Errors.TicksNotInitializable();

464:         if (self.optionRatio(0) == 0) revert Errors.InvalidTokenIdParameter(1);

473:                     if ((self >> (64 + 48 * i)) != 0) revert Errors.InvalidTokenIdParameter(1);

480:                 if ((self.width(i) == 0)) revert Errors.InvalidTokenIdParameter(5);

485:                 ) revert Errors.InvalidTokenIdParameter(4);

494:                         revert Errors.InvalidTokenIdParameter(3);

500:                     ) revert Errors.InvalidTokenIdParameter(3);

513:                         revert Errors.InvalidTokenIdParameter(4);

518:                         revert Errors.InvalidTokenIdParameter(5);

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/types/TokenId.sol)

### <a name="NC-2"></a>[NC-2] Event is missing `indexed` fields

Index event fields make the field more quickly accessible to off-chain tools that parse events. However, note that each index field costs extra gas during emission, so it's not necessarily best to index the maximum allowed per event (three fields). Each event should use three indexed fields if there are three or more fields, and gas usage is not particularly of concern for the events in question. If there are fewer than three fields, all of the fields should be indexed.

*Instances (3)*:

```solidity
File: contracts/SemiFungiblePositionManager.sol

97:     event TokenizedPositionMinted(

112:     using LiquidityChunk for uint256; // a leg within an option position `tokenId`

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/SemiFungiblePositionManager.sol)

```solidity
File: contracts/tokens/ERC1155Minimal.sol

44:     event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/tokens/ERC1155Minimal.sol)

### <a name="NC-3"></a>[NC-3] Constants should be defined rather than using magic numbers

*Instances (24)*:

```solidity
File: contracts/libraries/Math.sol

305:                     result := shr(64, prod0)

332:                 prod0 := shr(64, prod0)

367:                     result := shr(96, prod0)

394:                 prod0 := shr(96, prod0)

491:                     result := shr(192, prod0)

518:                 prod0 := shr(192, prod0)

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/libraries/Math.sol)

```solidity
File: contracts/libraries/SafeTransferLib.sol

26:             mstore(add(36, p), to) // Append the "to" argument.

27:             mstore(add(68, p), amount) // Append the "amount" argument.

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/libraries/SafeTransferLib.sol)

```solidity
File: contracts/types/TokenId.sol

95:             return uint256((self >> (64 + legIndex * 48)) % 2);

105:             return uint256((self >> (64 + legIndex * 48 + 1)) % 128);

115:             return uint256((self >> (64 + legIndex * 48 + 8)) % 2);

125:             return uint256((self >> (64 + legIndex * 48 + 9)) % 2);

141:             return uint256((self >> (64 + legIndex * 48 + 10)) % 4);

151:             return int24(int256(self >> (64 + legIndex * 48 + 12)));

162:             return int24(int256((self >> (64 + legIndex * 48 + 36)) % 4096));

195:             return self + (uint256(_asset % 2) << (64 + legIndex * 48));

210:             return self + (uint256(_optionRatio % 128) << (64 + legIndex * 48 + 1));

226:             return self + ((_isLong % 2) << (64 + legIndex * 48 + 8));

240:             return self + (uint256(_tokenType % 2) << (64 + legIndex * 48 + 9));

254:             return self + (uint256(_riskPartner % 4) << (64 + legIndex * 48 + 10));

268:             return self + uint256((int256(_strike) & BITMASK_INT24) << (64 + legIndex * 48 + 12));

283:             return self + (uint256(uint24(_width) % 4096) << (64 + legIndex * 48 + 36));

353:             return self ^ ((LONG_MASK >> (48 * (4 - optionRatios))) & CLEAR_POOLID_MASK);

473:                     if ((self >> (64 + 48 * i)) != 0) revert Errors.InvalidTokenIdParameter(1);

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/types/TokenId.sol)

### <a name="NC-4"></a>[NC-4] Functions not used internally could be marked external

*Instances (6)*:

```solidity
File: contracts/libraries/FeesCalc.sol

59:     ) public view returns (int256 feesEachToken) {

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/libraries/FeesCalc.sol)

```solidity
File: contracts/multicall/Multicall.sol

12:     function multicall(bytes[] calldata data) public payable returns (bytes[] memory results) {

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/multicall/Multicall.sol)

```solidity
File: contracts/tokens/ERC1155Minimal.sol

77:     function setApprovalForAll(address operator, bool approved) public {

90:     function safeTransferFrom(

178:     function balanceOfBatch(

200:     function supportsInterface(bytes4 interfaceId) public pure returns (bool) {

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/tokens/ERC1155Minimal.sol)

## Low Issues

| |Issue|Instances|
|-|:-|:-:|
| [L-1](#L-1) |  `abi.encodePacked()` should not be used with dynamic types when passing the result to a hash function such as `keccak256()` | 3 |

### <a name="L-1"></a>[L-1]  `abi.encodePacked()` should not be used with dynamic types when passing the result to a hash function such as `keccak256()`

Use `abi.encode()` instead which will pad items to 32 bytes, which will [prevent hash collisions](https://docs.soliditylang.org/en/v0.8.13/abi-spec.html#non-standard-packed-mode) (e.g. `abi.encodePacked(0x123,0x456)` => `0x123456` => `abi.encodePacked(0x1,0x23456)`, but `abi.encode(0x123,0x456)` => `0x0...1230...456`). "Unless there is a compelling reason, `abi.encode` should be preferred". If there is only one argument to `abi.encodePacked()` it can often be cast to `bytes()` or `bytes32()` [instead](https://ethereum.stackexchange.com/questions/30912/how-to-compare-strings-in-solidity#answer-82739).
If all arguments are strings and or bytes, `bytes.concat()` should be used instead

*Instances (3)*:

```solidity
File: contracts/SemiFungiblePositionManager.sol

1353:             keccak256(abi.encodePacked(univ3pool, owner, tokenType, tickLower, tickUpper))

1446:             keccak256(abi.encodePacked(univ3pool, owner, tokenType, tickLower, tickUpper))

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/SemiFungiblePositionManager.sol)

```solidity
File: contracts/libraries/PanopticMath.sol

57:                 (uint64(uint256(keccak256(abi.encodePacked(token0, token1, fee)))) >> 32);

```

[Link to code](https://github.com/code-423n4/2023-11-panoptic/blob/main/contracts/libraries/PanopticMath.sol)
