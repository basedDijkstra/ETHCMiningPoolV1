// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test, console2} from "forge-std/Test.sol";
import {ETHCoinMiningPoolV1} from "../src/ETHCMiningPoolV1.sol";
import {TestToken} from "./mocks/TestETHC.sol";

import "forge-std/console.sol";

contract TestETHCMiningPoolRedeem is Test {
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

    event FlashFeeCollected(uint256 fee);
    event FeeCollected(address miner, uint256 amount);
    event MiningStatusChanged(bool isPaused);
    event FlashLoanStatusChanged(bool isPaused);
    event FlashLoanFeesUpdated(uint256 oldFeeNum, uint256 newFeeNum);
    event OperatorFeeUpdated(uint256 oldFeeNum, uint256 newFeeNum);
    event OperatorAddressUpdated(address oldOperatorAddress, address newOperatorAddress);
    event BlockWeightsUpdated(
        uint256 oldLastBlockWeight,
        uint256 newLastBlockWeight,
        uint256 oldCurrentBlockWeight,
        uint256 newCurrentBlockWeight
    );

    function setUp() public {
        owner = makeAddr("owner");
        operator = makeAddr("operator");
        user = makeAddr("user");

        vm.startPrank(owner);
        ETHC = new TestToken();
        pool = new ETHCoinMiningPoolV1(address(ETHC), WETH);

        pool.setOperator(operator);

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
        vm.stopPrank();
    }

    function testOrdinaryRedeem() public {
        vm.startPrank(user);
        deal(user, 100 ether);
        uint256 mineCount = 1;

        console.log("user before balance");
        console.log(pool.balanceOf(user));

        // Calculate expected shares based on contract logic
        (uint256 expectedShares, uint256 expectedFee) = pool.calculateSharesAndFee(mineCount, 1);

        pool.mine{value: MINE_COST * mineCount}(mineCount);

        // Verify user received correct shares
        assertEq(pool.balanceOf(user), expectedShares);
        assertEq(pool.balanceOf(operator), expectedFee);
        assertEq(pool.totalSupply(), expectedShares + expectedFee);

        // exact amount
        ETHC.mint(address(pool.vault()), pool.totalSupply());

        pool.redeem(expectedShares);
        assertEq(ETHC.balanceOf(user), expectedShares);
        vm.stopPrank();

        vm.startPrank(operator);
        pool.redeem(expectedFee);
        assertEq(ETHC.balanceOf(operator), expectedFee);
        vm.stopPrank();
    }

    function testPartialRedeem() public {
        vm.startPrank(user);
        deal(user, 100 ether);
        uint256 mineCount = 1;

        console.log("user before balance");
        console.log(pool.balanceOf(user));

        // Calculate expected shares based on contract logic
        (uint256 expectedShares, uint256 expectedFee) = pool.calculateSharesAndFee(mineCount, 1);

        pool.mine{value: MINE_COST * mineCount}(mineCount);

        // Verify user received correct shares
        assertEq(pool.balanceOf(user), expectedShares);
        assertEq(pool.balanceOf(operator), expectedFee);
        assertEq(pool.totalSupply(), expectedShares + expectedFee);

        // exact amount
        ETHC.mint(address(pool.vault()), pool.totalSupply());

        pool.redeem(expectedShares / 2);
        assertEq(ETHC.balanceOf(user), expectedShares / 2);
        assertEq(ETHC.balanceOf(address(pool.vault())), pool.totalSupply());
        vm.stopPrank();

        vm.startPrank(operator);
        pool.redeem(expectedFee);
        assertEq(ETHC.balanceOf(operator), expectedFee);
        vm.stopPrank();
    }
}
//    ETHCoinMiningPoolV1 public pool;
//    TestToken public ethc;
//    address public constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
//
//    address public owner;
//    address public operator;
//    address public user;
//
//    event FlashFeeCollected(uint256 fee);
//    event FeeCollected(address miner, uint256 amount);
//    event MiningStatusChanged(bool isPaused);
//    event FlashLoanStatusChanged(bool isPaused);
//    event FlashLoanFeesUpdated(uint256 oldFeeNum, uint256 newFeeNum);
//    event OperatorFeeUpdated(uint256 oldFeeNum, uint256 newFeeNum);
//    event OperatorAddressUpdated(address oldOperatorAddress, address newOperatorAddress);
//    event BlockWeightsUpdated(
//        uint256 oldLastBlockWeight,
//        uint256 newLastBlockWeight,
//        uint256 oldCurrentBlockWeight,
//        uint256 newCurrentBlockWeight
//    );
//
//    function setUp() public {
//        owner = makeAddr("owner");
//        operator = makeAddr("operator");
//        user = makeAddr("user");
//
//        vm.startPrank(owner);
//        ethc = new TestToken();
//        pool = new ETHCoinMiningPoolV1(
//            address(ethc),
//            WETH
//        );
//        vm.stopPrank();
//    }
//
//    function testSetFlashFee() public {
//        vm.startPrank(owner);
//
//        uint256 oldFee = pool.ETHCFlashLoanFeeNum();
//        uint256 newFee = 30; // 0.3%
//
//        vm.expectEmit(true, true, true, true);
//        emit FlashLoanFeesUpdated(oldFee, newFee);
//
//        pool.setFlashFee(newFee);
//        assertEq(pool.ETHCFlashLoanFeeNum(), newFee);
//
//        vm.stopPrank();
//    }
//
//    function testSetFlashFeeNotOwner() public {
//        vm.startPrank(user);
//        vm.expectRevert("Ownable: caller is not the owner");
//        pool.setFlashFee(30);
//        vm.stopPrank();
//    }
//
//    function testPauseFlash() public {
//        vm.startPrank(owner);
//
//        assertFalse(pool.flashPaused());
//
//        vm.expectEmit(true, true, true, true);
//        emit FlashLoanStatusChanged(true);
//
//        pool.pauseFlash();
//        assertTrue(pool.flashPaused());
//
//        vm.stopPrank();
//    }
//
//    function testPauseFlashAlreadyPaused() public {
//        vm.startPrank(owner);
//        pool.pauseFlash();
//        vm.expectRevert("Flash loans already paused");
//        pool.pauseFlash();
//        vm.stopPrank();
//    }
//
//    function testUnpauseFlash() public {
//        vm.startPrank(owner);
//
//        pool.pauseFlash();
//        assertTrue(pool.flashPaused());
//
//        vm.expectEmit(true, true, true, true);
//        emit FlashLoanStatusChanged(false);
//
//        pool.unPauseFlash();
//        assertFalse(pool.flashPaused());
//
//        vm.stopPrank();
//    }
//
//    function testUnpauseFlashNotPaused() public {
//        vm.startPrank(owner);
//        vm.expectRevert("Flash loans not paused");
//        pool.unPauseFlash();
//        vm.stopPrank();
//    }
//
//    function testPauseMining() public {
//        vm.startPrank(owner);
//
//        assertFalse(pool.miningPaused());
//
//        vm.expectEmit(true, true, true, true);
//        emit MiningStatusChanged(true);
//
//        pool.pauseMining();
//        assertTrue(pool.miningPaused());
//
//        vm.stopPrank();
//    }
//
//    function testPauseMiningAlreadyPaused() public {
//        vm.startPrank(owner);
//        pool.pauseMining();
//        vm.expectRevert("Mining already paused");
//        pool.pauseMining();
//        vm.stopPrank();
//    }
//
//    function testSetOperator() public {
//        vm.startPrank(owner);
//
//        address newOperator = makeAddr("newOperator");
//        address oldOperator = pool.operatorAddress();
//
//        vm.expectEmit(true, true, true, true);
//        emit OperatorAddressUpdated(oldOperator, newOperator);
//
//        pool.setOperator(newOperator);
//        assertEq(pool.operatorAddress(), newOperator);
//
//        vm.stopPrank();
//    }
//
//    function testSetOperatorZeroAddress() public {
//        vm.startPrank(owner);
//        vm.expectRevert("Invalid operator Address");
//        pool.setOperator(address(0));
//        vm.stopPrank();
//    }
//
//    function testSetOperatorSameAddress() public {
//        vm.startPrank(owner);
//        pool.setOperator(operator);
//        vm.expectRevert("Cannot setOperator to the same address");
//        pool.setOperator(operator);
//        vm.stopPrank();
//    }
//
//    function testSetOperatorFee() public {
//        vm.startPrank(owner);
//
//        uint256 oldFee = pool.operatorFeeNum();
//        uint256 newFee = 300; // 3%
//
//        vm.expectEmit(true, true, true, true);
//        emit OperatorFeeUpdated(oldFee, newFee);
//
//        pool.setOperatorFee(newFee);
//        assertEq(pool.operatorFeeNum(), newFee);
//
//        vm.stopPrank();
//    }
//
//    function testSetOperatorFeeExceedsMax() public {
//        vm.startPrank(owner);
//        vm.expectRevert("Fee exceeds maximum");
//        pool.setOperatorFee(1001); // Max is 1000 (10%)
//        vm.stopPrank();
//    }
//
//    function testSetBlockWeights() public {
//        vm.startPrank(owner);
//
//        uint256 oldLastWeight = pool.lastBlockWeight();
//        uint256 oldCurrentWeight = pool.currentBlockWeight();
//        uint256 newLastWeight = 8;
//        uint256 newCurrentWeight = 2;
//
//        vm.expectEmit(true, true, true, true);
//        emit BlockWeightsUpdated(oldLastWeight, newLastWeight, oldCurrentWeight, newCurrentWeight);
//
//        pool.setBlockWeights(newLastWeight, newCurrentWeight);
//        assertEq(pool.lastBlockWeight(), newLastWeight);
//        assertEq(pool.currentBlockWeight(), newCurrentWeight);
//
//        vm.stopPrank();
//    }
//
//    function testSetBlockWeightsZeroWeight() public {
//        vm.startPrank(owner);
//        vm.expectRevert("Weights must be positive");
//        pool.setBlockWeights(0, 1);
//        vm.expectRevert("Weights must be positive");
//        pool.setBlockWeights(1, 0);
//        vm.stopPrank();
//    }
//}
