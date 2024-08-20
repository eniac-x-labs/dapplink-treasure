// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {Script, console } from "forge-std/Script.sol";
import "../src/TreasureManager.sol";

contract TreasureManagerScript is Script {
    ProxyAdmin public dappLinkProxyAdmin;
    TreasureManager public treasureManagerContract;

    function run() public {
        // env
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address usdtTokenAddress =  vm.envAddress("USDT_ADDRESS");
        address withdrawManager =  vm.envAddress("WITHDRAW_MANAGER");
        address treasureManager =  vm.envAddress("TREASURE_MANAGER");

        // deployerAddress
        address deployerAddress = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        dappLinkProxyAdmin = new ProxyAdmin(deployerAddress);
        console.log("deploy dappLinkProxyAdmin:", address(dappLinkProxyAdmin));

        treasureManagerContract = new TreasureManager();

        TransparentUpgradeableProxy proxyTreasureManager = new TransparentUpgradeableProxy(
            address(treasureManagerContract),
            address(dappLinkProxyAdmin),
            abi.encodeWithSelector(TreasureManager.initialize.selector, treasureManager, withdrawManager)
        );
        console.log("deploy proxyTreasureManager:", address(proxyTreasureManager));

        // setup
        ITreasureManager(address(proxyTreasureManager)).setTokenWhiteList(usdtTokenAddress);

        vm.stopBroadcast();
    }
}
