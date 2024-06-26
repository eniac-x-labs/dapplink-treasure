// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "../src/TreasureManager.sol";
import "../src/access/proxy/Proxy.sol";

contract TreasureManagerScript is Script {
    TreasureManager public treasureManager;
    Proxy public proxyTreasureManager;

    function run() public {
        vm.startBroadcast();
        address admin = msg.sender;

        treasureManager = new TreasureManager();
        proxyTreasureManager = new Proxy(address(treasureManager), admin, "");
        treasureManager.initialize(admin, admin);

        vm.stopBroadcast();
    }
}
