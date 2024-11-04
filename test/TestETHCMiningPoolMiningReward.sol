// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {ETHCoinMiningPoolV1, IETHC} from "../src/ETHCMiningPoolV1.sol";
import {TestToken} from "./mocks/TestETHC.sol";

import "forge-std/console.sol";

contract TestETHCMiningPoolMiningReward is Test {
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
        ETHC._setNextHalvingBlock(BLOCKNUMBER + 5);
        ETHC._setHalvingInterval(5);
    }

    function testMiningRewardCurrentBlock() public {
        vm.startPrank(user);
        assertEq(pool.miningReward(BLOCKNUMBER), MINING_REWARD);
        vm.stopPrank();
    }

    function testMiningRewardNextHalvingBlock() public {
        vm.startPrank(user);
        assertEq(pool.miningReward(BLOCKNUMBER + 5), MINING_REWARD / 2);
        vm.stopPrank();
    }

    function testMiningRewardNextHalvingBlockPlusOne() public {
        vm.startPrank(user);
        assertEq(pool.miningReward(BLOCKNUMBER + 6), MINING_REWARD / 2);
        vm.stopPrank();
    }

    function testMiningRewardCurrentBlockBeforeNextNextHalvingBlock() public {
        vm.startPrank(user);
        assertEq(pool.miningReward(BLOCKNUMBER + 14), MINING_REWARD / 2);
        vm.stopPrank();
    }

    function testMiningRewardCurrentBlockNextNextHalvingBlock() public {
        vm.startPrank(user);
        assertEq(pool.miningReward(BLOCKNUMBER + 15), MINING_REWARD / 2 / 2);
        vm.stopPrank();
    }

    function testMiningRewardCurrentBlockNextNextHalvingBlockPlusOne() public {
        vm.startPrank(user);
        assertEq(pool.miningReward(BLOCKNUMBER + 16), MINING_REWARD / 2 / 2);
        vm.stopPrank();
    }
}
