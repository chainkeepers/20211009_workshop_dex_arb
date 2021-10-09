/*
  SPDX-License-Identifier: BSD-3-Clause
*/

pragma solidity ^0.8.4;

// We need the artifacts hardhat compile generates.
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/ERC20.sol';

interface UniswapV2Router {
  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable returns (uint[] memory amounts);
}

// From https://docs.uniswap.org/protocol/guides/swaps/single-swaps
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';


/*
  Swapni z uni[23] -> uni[23] -> ... -> uni[23].
  Plati, ze amountIn je vzdycky amountOut.
  Potrebuju zvolit, jestli jde o swap na Uniswapu 2 a nebo Uniswapu 3.
  Navic, Uniswap 3 pooly maji jeste parametr fee.

  Takze eval(amount, tokens[], fees[]);
*/

contract ArbitrageUniswap {

  // See the uniswap v2 docs
  address private constant UNISWAP_V2_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  // Search uniswap v3 router address on google
  address private constant UNISWAP_V3_ROUTER_ADDRESS = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

  function eval(uint256 amountIn, address[] calldata tokens, uint256[] calldata fees) public {

    address[] memory path = new address[](2);
    uint256[] memory amounts;

    for(uint256 i = 0; i < tokens.length - 1; i++){

      /*
        1. swap amountIn -> tokenOut
        2. zjisti, kolik je tokenOut
        3. priprav pro dalsi swap
      */

      if(fees[i] == 0){

        // Swap on Uniswap V2

        IERC20(tokens[i]).approve(UNISWAP_V2_ROUTER_ADDRESS, amountIn);

        path[0] = tokens[i];
        path[1] = tokens[i + 1];

        amounts = UniswapV2Router(UNISWAP_V2_ROUTER_ADDRESS)
        .swapExactTokensForTokens(
            /* amountIn = */ amountIn,
            /* amountOutMin = */ 0,
            /* path = */ path,
            /* to = */ address(this),
            /* deadline = */ block.timestamp
        );

        amountIn = amounts[1];

      }

      if(fees[i] > 0){

        // Swap on Uniswap V3

        IERC20(tokens[i]).approve(UNISWAP_V3_ROUTER_ADDRESS, amountIn);

        amountIn = ISwapRouter(UNISWAP_V3_ROUTER_ADDRESS)
        .exactInputSingle(ISwapRouter.ExactInputSingleParams({
          tokenIn: tokens[i],
          tokenOut: tokens[i + 1],
          fee: uint24(fees[i]),
          recipient: address(this),
          deadline: block.timestamp,
          amountIn: amountIn,
          amountOutMinimum: 0,
          sqrtPriceLimitX96: 0
        }));

      }

    }

  }

}
