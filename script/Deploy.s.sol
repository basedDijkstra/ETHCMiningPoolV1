// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {ETHCoinMiningPoolV1} from "../src/ETHCMiningPoolV1.sol";

contract DeployETHCMiningPool is Script {
    ETHCoinMiningPoolV1 public pool;
    address public WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public ETHCAddress = address(0xE957ea0b072910f508dD2009F4acB7238C308E29);

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        pool = new ETHCoinMiningPoolV1(ETHCAddress, WETH);
        vm.stopBroadcast();
    }
}
