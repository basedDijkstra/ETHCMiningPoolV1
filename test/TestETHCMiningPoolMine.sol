// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test, console2} from "forge-std/Test.sol";
import {ETHCoinMiningPoolV1, IETHC} from "../src/ETHCMiningPoolV1.sol";
import {TestToken} from "./mocks/TestETHC.sol";

import "forge-std/console.sol";

contract TestETHCMiningPoolMine is Test {
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

    function testBasicMining() public {
        vm.startPrank(user);
        deal(user, 100 ether);
        uint256 mineCount = 1;

        // Calculate expected shares based on contract logic
        (uint256 expectedShares, uint256 expectedFee) = pool.calculateSharesAndFee(mineCount, 1);

        vm.expectEmit(true, true, true, true);
        emit MiningExecuted(user, BLOCKNUMBER + 1, mineCount, MINING_REWARD, expectedShares, expectedFee);

        pool.mine{value: MINE_COST * mineCount}(mineCount);

        // Verify user received correct shares
        assertEq(pool.balanceOf(user), expectedShares);
        assertEq(pool.balanceOf(operator), expectedFee);

        vm.stopPrank();
    }

    function testMiningWithMultipleMineCounts() public {
        vm.startPrank(user);
        deal(user, 100 ether);
        uint256 mineCount = 5;

        (uint256 expectedShares, uint256 expectedFee) = pool.calculateSharesAndFee(mineCount, 1);

        vm.expectEmit(true, true, true, true);
        emit MiningExecuted(user, BLOCKNUMBER + 1, mineCount, MINING_REWARD, expectedShares, expectedFee);

        pool.mine{value: MINE_COST * mineCount}(mineCount);

        // Verify user received correct shares
        assertEq(pool.balanceOf(user), expectedShares);
        assertEq(pool.balanceOf(operator), expectedFee);

        vm.stopPrank();
    }

    function testMiningWhenPaused() public {
        vm.prank(owner);
        pool.pauseMining();

        vm.startPrank(user);
        deal(user, 100 ether);
        vm.expectRevert("Mining is paused");
        pool.mine{value: MINE_COST}(1);
        vm.stopPrank();
    }

    function testMiningWithInsufficientPayment() public {
        vm.startPrank(user);
        uint256 mineCount = 2;
        uint256 insufficientPayment = MINE_COST * mineCount - 1;

        vm.expectRevert(); // expect revert due to insufficient payment
        pool.mine{value: insufficientPayment}(mineCount);
        vm.stopPrank();
    }

    function testMiningWithExcessPayment() public {
        vm.startPrank(user);
        deal(user, 100 ether);
        uint256 mineCount = 1;
        uint256 excessPayment = MINE_COST * 2;

        (uint256 expectedShares,) = pool.calculateSharesAndFee(mineCount, 1);

        uint256 balanceBefore = user.balance;
        pool.mine{value: excessPayment}(mineCount);
        uint256 balanceAfter = user.balance;

        // Verify correct ETH refund
        assertEq(balanceAfter, balanceBefore - (MINE_COST * mineCount));

        // Verify correct shares minted
        assertEq(pool.balanceOf(user), expectedShares);
        vm.stopPrank();
    }

    function testMiningBlockWeights() public {
        // Set custom block weights
        vm.prank(owner);
        pool.setBlockWeights(0, 1); // 80/20 weight distribution

        vm.startPrank(user);
        deal(user, 100 ether);
        uint256 mineCount = 1;

        (uint256 expectedShares,) = pool.calculateSharesAndFee(mineCount, 1);

        pool.mine{value: MINE_COST * mineCount}(mineCount);

        assertEq(pool.balanceOf(user), expectedShares);
        vm.stopPrank();
    }

    // Helper functions for calculations
    function calculateExpectedShares(uint256 mineCount) internal view returns (uint256) {
        uint256 blockNumber = ETHC.blockNumber();
        uint256 lastBlockMiners = ETHC.minersOfBlockCount(blockNumber) * pool.lastBlockWeight();
        uint256 nextBlockMiners = ETHC.minersOfBlockCount(blockNumber + 1) * pool.currentBlockWeight();
        uint256 miningReward = ETHC.blocks(blockNumber + 1).miningReward;

        uint256 blockReward = miningReward == 0 ? ETHC.miningReward() : miningReward;

        // Calculate weighted average miners and resulting shares
        uint256 weightedAvgMiners =
            (lastBlockMiners + nextBlockMiners) / (pool.lastBlockWeight() + pool.currentBlockWeight());
        uint256 shares = blockReward * mineCount / weightedAvgMiners;

        return shares;
    }

    function calculateOperatorFee(uint256 shares) internal view returns (uint256) {
        return shares * pool.operatorFeeNum() / pool.operatorFeeDenom();
    }

    // Fuzzing tests
    function testFuzz_Mining(uint96 mineCount) public {
        vm.assume(mineCount > 0 && mineCount <= 150); // Reasonable bounds

        vm.startPrank(user);
        uint256 cost = MINE_COST * mineCount;
        vm.deal(user, cost); // Ensure user has enough ETH

        (uint256 expectedShares, uint256 expectedFee) = pool.calculateSharesAndFee(mineCount, 1);

        console.log(expectedShares);
        console.log(expectedFee);

        assertTrue(expectedFee > 0);
        assertTrue(expectedShares > 0);

        pool.mine{value: cost}(mineCount);

        // Verify basic invariants
        assertTrue(pool.balanceOf(user) > 0);
        assertTrue(pool.balanceOf(operator) > 0);
        vm.stopPrank();
    }
}
