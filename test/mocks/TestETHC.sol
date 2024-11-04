// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "forge-std/console.sol";

interface IETHC {
    struct Block {
        address selectedMiner;
        uint256 miningReward;
    }

    function mine(uint256 mineCount) external payable;
    function futureMine(uint256 mineCount, uint256 blockCounts) external payable;

    function nextHalvingBlock() external view returns (uint256);
    function halvingInterval() external view returns (uint256);
    function miningReward() external view returns (uint256);
    function minersOfBlockCount(uint256 _blockNumber) external view returns (uint256);
    function blockNumber() external view returns (uint256);
    function mineCost() external view returns (uint256);
    function blocks(uint256 blockNumber) external view returns (Block memory);
}

contract TestToken is ERC20, IETHC {
    uint256 _nextHalvingBlock;

    function _setNextHalvingBlock(uint256 nextHalvingBlock_) external {
        _nextHalvingBlock = nextHalvingBlock_;
    }

    uint256 _halvingInterval;

    function _setHalvingInterval(uint256 halvingInterval_) external {
        _halvingInterval = halvingInterval_;
    }

    // Mock Variables
    uint256 _mineCost;

    function _setMineCost(uint256 mineCost_) external {
        _mineCost = mineCost_;
    }

    uint256 _miningReward;

    function _setMiningReward(uint256 miningReward_) external {
        _miningReward = miningReward_;
    }

    mapping(uint256 => IETHC.Block) _blocks;

    function _setBlock(uint256 blockNumber_, address selectedMiner, uint256 miningReward_) external {
        _blocks[blockNumber_].miningReward = miningReward_;
        _blocks[blockNumber_].selectedMiner = selectedMiner;
    }

    uint256 _blockNumber;

    function _setBlockNumber(uint256 blockNumber_) external {
        _blockNumber = blockNumber_;
    }

    mapping(uint256 => uint256) _minersOfBlockCount;

    function _setMinersOfBlockCount(uint256 blockNumber_, uint256 count) external {
        _minersOfBlockCount[blockNumber_] = count;
    }

    constructor() ERC20("TestToken", "TEST") {}

    function halvingInterval() external view returns (uint256) {
        return _halvingInterval;
    }

    function nextHalvingBlock() external view returns (uint256) {
        return _nextHalvingBlock;
    }

    function mint(address recipient, uint256 amount) public {
        _mint(recipient, amount);
    }

    function mine(uint256 mineCount) external payable {
        // Add requires for mineCount, mineCost and msg.value
    }

    function futureMine(uint256 mineCount, uint256 blockCounts) external payable {
        // Add requires for mineCount, blockCounts, mineCost and msg.value
    }

    function miningReward() external view returns (uint256) {
        return _miningReward;
    }

    function minersOfBlockCount(uint256 blockNumber_) external view returns (uint256) {
        return _minersOfBlockCount[blockNumber_];
    }

    function blockNumber() external view returns (uint256) {
        return _blockNumber;
    }

    function mineCost() external view returns (uint256) {
        return _mineCost;
    }

    function blocks(uint256 blockNumber_) external view returns (IETHC.Block memory) {
        IETHC.Block memory block_ = _blocks[blockNumber_];
        console.log(block_.selectedMiner);
        console.log(block_.miningReward);
        return block_;
    }
}
