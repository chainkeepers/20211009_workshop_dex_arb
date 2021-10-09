const { expect } = require('chai');
const { ethers } = require('hardhat');
const parseEther = ethers.utils.parseEther;

const { pinBlock, sendTokens, getERC20 } = require('../utils.js');


const CONTRACT = 'ArbitrageUniswap';

// Search etherscan for query WETH, DAI, USDC
const WETH = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2';
const DAI = '0x6B175474E89094C44Da98b954EedeAC495271d0F';
const USDC = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48';
const USDT = '0xdAC17F958D2ee523a2206206994597C13D831ec7';
const UNI = '0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984';


describe(`Test ${CONTRACT}`, function() {

  it('works', async function() {

    await pinBlock(13249151);

    console.log('pinned');

    const factory = await ethers.getContractFactory(CONTRACT);
    const contract = await factory.deploy();

    console.log('deployed');

    await sendTokens(contract.address, parseEther('1'), WETH);

    console.log('sent');

    const token = await getERC20(WETH);

    const balanceBefore = await token.balanceOf(contract.address);

    /* Feel free to play with the arbitrage here... */

    const tx = await contract.eval(
      /* amount = */ parseEther('1'),
      /* tokens = */ [
        WETH,
        DAI,
        USDC,
        WETH,
      ],
      /* fees = */ [0, 500, 3000],
    );

    const balanceAfter = await token.balanceOf(contract.address);

    console.log({
      balanceBefore: balanceBefore / 1e18,
      balanceAfter: balanceAfter / 1e18,
      profitInEth: (balanceAfter - balanceBefore) / 1e18,
    });

  });

});
