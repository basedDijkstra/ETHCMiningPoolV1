// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ETHCoinMiningPool} from "../src/ETHCMiningPool.sol";

contract CounterScript is Script {
    ETHCoinMiningPool public pool;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        pool = new ETHCoinMiningPool();

        vm.stopBroadcast();
    }
}
