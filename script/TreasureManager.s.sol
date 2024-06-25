// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../src/TreasureManager.sol";
import "../src/access/proxy/Proxy.sol";


contract TreasureManagerScript is Script {
    TreasureManager public treasureManager;
    Proxy public proxyTreasureManager;

    function run() public {
        vm.startBroadcast();
        address admin = msg.sender;

        treasureManager = new TreasureManager();
        proxyTreasureManager = new Proxy(address(treasureManager), address(admin), "");
        TreasureManager(address(proxyTreasureManager)).initialize(msg.sender, msg.sender);

        vm.stopBroadcast();
    }
}
