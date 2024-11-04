// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test, console2} from "forge-std/Test.sol";
import {ETHCoinMiningPoolV1, IETHC} from "../src/ETHCMiningPoolV1.sol";
import {TestToken} from "./mocks/TestETHC.sol";

import "forge-std/console.sol";

contract TestETHCMiningPoolMineFuture is Test {
    ETHCoinMiningPoolV1 public pool;
    TestToken public ETHC;
    address public constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    address public owner;
    address public operator;
    address public user;
    uint256 public constant MINE_COST = 0.01 ether;
    uint256 public constant MINING_REWARD = 100 ether; // 100 ETHC tokens per block
    uint256 public constant LAST_BLOCK_MINER_COUNT = 500;
    uint256 public constant NEXT_BLOCK_MINER_COUNT = 300;
    uint256 public constant BLOCKNUMBER = 10045;

    event MiningExecuted(
        address indexed miner,
        uint256 indexed blockNumber,
        uint256 mineCount,
        uint256 blockReward,
        uint256 shares,
        uint256 feeAmount
    );

    event FutureMiningExecuted(
        address indexed miner,
        uint256 indexed blockNumber,
        uint256 mineCount,
        uint256 blockCounts,
        uint256 blockReward,
        uint256 totalShares,
        uint256 totalFeeAmount
    );

    function setUp() public {
        owner = makeAddr("owner");
        operator = makeAddr("operator");
        user = makeAddr("user");

        vm.startPrank(owner);
        ETHC = new TestToken();
        pool = new ETHCoinMiningPoolV1(address(ETHC), WETH);

        // Set operator for fee collection
        pool.setOperator(operator);
        vm.stopPrank();

        // Set up TestToken initial state
        ETHC._setMineCost(MINE_COST);
        ETHC._setMiningReward(MINING_REWARD);
        ETHC._setMinersOfBlockCount(BLOCKNUMBER, LAST_BLOCK_MINER_COUNT);
        ETHC._setMinersOfBlockCount(BLOCKNUMBER + 1, NEXT_BLOCK_MINER_COUNT);
        ETHC._setBlock(BLOCKNUMBER, address(0), MINING_REWARD);
        ETHC._setBlock(BLOCKNUMBER + 1, address(0), MINING_REWARD);
        ETHC._setBlockNumber(BLOCKNUMBER);
        ETHC._setNextHalvingBlock(BLOCKNUMBER + 5000);
        ETHC._setHalvingInterval(5000);
    }

    function testBasicFutureMining() public {
        vm.startPrank(user);
        deal(user, 100 ether);
        uint256 mineCount = 1;
        uint256 blockCount = 2;

        // Calculate expected shares based on contract logic
        (uint256 expectedShares, uint256 expectedFee) = pool.calculateSharesAndFee(mineCount, blockCount);

        vm.expectEmit(true, true, true, true);
        emit FutureMiningExecuted(
            user, BLOCKNUMBER + 1, mineCount, blockCount, MINING_REWARD, expectedShares, expectedFee
        );

        pool.futureMine{value: MINE_COST * mineCount * blockCount}(mineCount, blockCount);

        // Verify user received correct shares
        assertEq(pool.balanceOf(user), expectedShares);
        assertEq(pool.balanceOf(operator), expectedFee);

        vm.stopPrank();
    }

    function testFutureMiningWithMultipleMineCounts() public {
        vm.startPrank(user);
        deal(user, 100 ether);
        uint256 mineCount = 5;
        uint256 blockCount = 2;

        (uint256 expectedShares, uint256 expectedFee) = pool.calculateSharesAndFee(mineCount, blockCount);

        vm.expectEmit(true, true, true, true);
        emit FutureMiningExecuted(
            user, BLOCKNUMBER + 1, mineCount, blockCount, MINING_REWARD, expectedShares, expectedFee
        );

        pool.futureMine{value: MINE_COST * mineCount * blockCount}(mineCount, blockCount);

        // Verify user received correct shares
        assertEq(pool.balanceOf(user), expectedShares);
        assertEq(pool.balanceOf(operator), expectedFee);

        vm.stopPrank();
    }

    function testFutureMiningWhenPaused() public {
        vm.prank(owner);
        pool.pauseMining();

        vm.startPrank(user);
        deal(user, 100 ether);
        vm.expectRevert("Mining is paused");
        pool.futureMine{value: MINE_COST}(1, 1);
        vm.stopPrank();
    }

    function testFutureMiningWithInsufficientPayment() public {
        vm.startPrank(user);
        uint256 mineCount = 2;
        uint256 blockCount = 2;
        uint256 insufficientPayment = MINE_COST * mineCount * blockCount - 1;

        vm.expectRevert(); // expect revert due to insufficient payment
        pool.futureMine{value: insufficientPayment}(mineCount, blockCount);
        vm.stopPrank();
    }

    function testFutureMiningWithExcessPayment() public {
        vm.startPrank(user);
        deal(user, 100 ether);
        uint256 mineCount = 1;
        uint256 blockCount = 3;
        uint256 excessPayment = MINE_COST * mineCount * blockCount + (10 ** 18);

        (uint256 expectedShares,) = pool.calculateSharesAndFee(mineCount, blockCount);

        uint256 balanceBefore = user.balance;
        pool.futureMine{value: excessPayment}(mineCount, blockCount);
        uint256 balanceAfter = user.balance;

        // Verify correct ETH refund
        assertEq(balanceAfter, balanceBefore - (MINE_COST * mineCount * blockCount));

        // Verify correct shares minted
        assertEq(pool.balanceOf(user), expectedShares);
        vm.stopPrank();
    }

    // Fuzzing tests
    function testFuzz_Future_Mining(uint96 mineCount, uint96 blockCount) public {
        vm.assume(mineCount > 0 && mineCount <= 150); // Reasonable bounds
        vm.assume(blockCount > 0 && blockCount <= 100); // Reasonable bounds

        vm.startPrank(user);
        uint256 cost = MINE_COST * mineCount * blockCount;
        vm.deal(user, cost); // Ensure user has enough ETH

        (uint256 expectedShares, uint256 expectedFee) = pool.calculateSharesAndFee(mineCount, blockCount);

        console.log(expectedShares);
        console.log(expectedFee);

        assertTrue(expectedFee > 0);
        assertTrue(expectedShares > 0);

        pool.futureMine{value: cost}(mineCount, blockCount);

        // Verify basic invariants
        assertTrue(pool.balanceOf(user) > 0);
        assertTrue(pool.balanceOf(operator) > 0);
        vm.stopPrank();
    }
}
