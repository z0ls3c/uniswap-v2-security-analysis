// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {IUniswapV2Router02, IERC20, IUniswapV2Factory} from "./interfaces/IUniswapV2.sol";

/**
 * @title CoreMechanics
 * @notice Foundry tests demonstrating Uniswap V2 core mechanics on mainnet fork
 * @dev Tests basic swap, liquidity provision, and liquidity removal flows
 */
contract CoreMechanics is Test {
    // Mainnet addresses
    IUniswapV2Router02 constant ROUTER = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Factory constant FACTORY = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IERC20 constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    address user;

    function setUp() public {
        // Create a user address
        user = address(this);

        // Give user some ETH to work with
        vm.deal(user, 100 ether);

        console.log("Setup complete");
        console.log("User ETH balance:", user.balance / 1e18, "ETH");
    }

    function test_SwapETHForUSDC() public {
        console.log("\n=== TEST: Swap ETH for USDC ===");

        // Check balances before
        uint256 ethBefore = user.balance;
        uint256 usdcBefore = USDC.balanceOf(user);

        console.log("Before swap:");
        console.log("  ETH balance:", ethBefore / 1e18, "ETH");
        console.log("  USDC balance:", usdcBefore / 1e6, "USDC");

        // Prepare swap path: ETH -> WETH -> USDC
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(USDC);

        // Get expected output amount
        uint256[] memory amountsOut = ROUTER.getAmountsOut(0.1 ether, path);
        console.log("Expected USDC output:", amountsOut[1] / 1e6, "USDC");

        // Execute swap: 0.1 ETH for USDC
        ROUTER.swapExactETHForTokens{value: 0.1 ether}(
            0, // accept any amount (in production, set slippage protection)
            path,
            user,
            block.timestamp + 300
        );

        // Check balances after
        uint256 ethAfter = user.balance;
        uint256 usdcAfter = USDC.balanceOf(user);

        console.log("\nAfter swap:");
        console.log("  ETH balance:", ethAfter / 1e18, "ETH");
        console.log("  USDC balance:", usdcAfter / 1e6, "USDC");

        uint256 ethSpent = ethBefore - ethAfter;
        uint256 usdcReceived = usdcAfter - usdcBefore;

        console.log("  ETH spent:", ethSpent / 1e18, "ETH");
        console.log("  USDC received:", usdcReceived / 1e6, "USDC");

        // Calculate exchange rate
        uint256 exchangeRate = (usdcReceived * 1e18) / ethSpent; // USDC per ETH (scaled)
        console.log("\nExchange rate:", exchangeRate / 1e6, "USDC per ETH");

        // Verify swap worked
        assertGt(usdcAfter, usdcBefore, "Should have received USDC");
        assertEq(ethSpent, 0.1 ether, "Should have spent 0.1 ETH");
    }

    function test_AddLiquidity() public {
        console.log("\n=== TEST: Add Liquidity ETH/USDC ===");

        // Step 1: Get some USDC first (by swapping)
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(USDC);

        ROUTER.swapExactETHForTokens{value: 1 ether}(0, path, user, block.timestamp + 300);

        uint256 usdcBalance = USDC.balanceOf(user);
        console.log("USDC acquired:", usdcBalance / 1e6);

        // Step 2: Approve router to spend USDC
        USDC.approve(address(ROUTER), type(uint256).max);

        // Step 3: Get the pair address to check LP tokens later
        address pair = FACTORY.getPair(WETH, address(USDC));
        console.log("Pair address:", pair);

        IERC20 lpToken = IERC20(pair);
        uint256 lpBefore = lpToken.balanceOf(user);

        // Step 4: Add liquidity (you need to calculate proper amounts)
        ROUTER.addLiquidityETH{value: 0.5 ether}(
            address(USDC),
            usdcBalance, // amount of USDC to add (for simplicity, use all)
            0, // min USDC (in production, set slippage protection)
            0, // min ETH (in production, set slippage protection)
            user,
            block.timestamp + 300
        );

        // Step 5: Check LP token balance after
        uint256 lpAfter = lpToken.balanceOf(user);
        console.log("LP tokens received:", lpAfter - lpBefore);

        // Step 6: Assert you received LP tokens
        assertGt(lpAfter, lpBefore, "Should have received LP tokens");
    }

    function test_RemoveLiquidity() public {
        console.log("\n=== TEST: Remove Liquidity ===");

        // STEP 1: First, add liquidity (do the full flow)

        // Get some USDC by swapping
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(USDC);

        ROUTER.swapExactETHForTokens{value: 1 ether}(0, path, user, block.timestamp + 300);

        uint256 usdcBalance = USDC.balanceOf(user);
        console.log("USDC acquired:", usdcBalance / 1e6);

        // Approve router to spend USDC
        USDC.approve(address(ROUTER), type(uint256).max);

        // Add liquidity
        ROUTER.addLiquidityETH{value: 0.5 ether}(address(USDC), usdcBalance, 0, 0, user, block.timestamp + 300);

        // STEP 2: Now we have LP tokens, let's remove liquidity

        address pair = FACTORY.getPair(WETH, address(USDC));
        IERC20 lpToken = IERC20(pair);

        uint256 lpBalance = lpToken.balanceOf(user);
        console.log("\nLP tokens before removal:", lpBalance);

        // Approve router to spend LP tokens
        lpToken.approve(address(ROUTER), type(uint256).max);

        uint256 ethBefore = user.balance;
        uint256 usdcBefore = USDC.balanceOf(user);

        console.log("\nBalances before removal:");
        console.log("  ETH:", ethBefore, "wei");
        console.log("  USDC:", usdcBefore / 1e6, "USDC");

        // Remove all liquidity
        ROUTER.removeLiquidityETH(
            address(USDC),
            lpBalance, // remove all LP tokens
            0, // min USDC
            0, // min ETH
            user,
            block.timestamp + 300
        );

        uint256 ethAfter = user.balance;
        uint256 usdcAfter = USDC.balanceOf(user);

        console.log("\nBalances after removal:");
        console.log("  ETH:", ethAfter / 1e18, "ETH");
        console.log("  USDC:", usdcAfter / 1e6, "USDC");

        console.log("\nTokens received from removing liquidity:");
        console.log("  ETH:", (ethAfter - ethBefore) / 1e18, "ETH");
        console.log("  USDC:", (usdcAfter - usdcBefore) / 1e6, "USDC");
        console.log("  LP tokens remaining:", lpToken.balanceOf(user));

        // Verify LP tokens were burned
        assertEq(lpToken.balanceOf(user), 0, "All LP tokens should be burned");
    }
    
    // CRITICAL: Allow contract to receive ETH
    receive() external payable {}
}