// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/TreasureManager.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TestERC20 is ERC20 {
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }
}

contract TreasureManagerTest is Test {
    using SafeERC20 for IERC20;

    TreasureManager treasureManager;
    TestERC20 testToken;
    address treasureManagerAddr = address(0x123);
    address withdrawManagerAddr = address(0x456);
    receive() external payable {} 
    function setUp() public {
        treasureManager = new TreasureManager();
        treasureManager.initialize(treasureManagerAddr, withdrawManagerAddr);
        testToken = new TestERC20("TestToken", "TTK", 10000 * 1e18);
    }

    function testDepositETH() public {
        vm.deal(address(this), 100);
        (bool success, ) = address(treasureManager).call{value: 100}("");
        require(success, "ETH deposit to TreasureManager failed");
        assertEq(address(treasureManager).balance, 100);
        assertEq(address(this).balance, 0);
    }

    function testDepositERC20() public {
        uint256 depositAmount = 1000 * 1e18;
        IERC20 tokenInterface = IERC20(address(testToken));
        testToken.approve(address(treasureManager), depositAmount);
        bool success = treasureManager.depositERC20(tokenInterface, depositAmount);
        assertTrue(success, "ERC20 deposit to TreasureManager failed");
        assertEq(treasureManager.tokenBalances(address(testToken)), depositAmount, "Incorrect token balance after ERC20 deposit");
    }

    function testGrantRewards() public {
        uint256 rewardAmount = 10000 * 1e18;
        vm.startPrank(treasureManagerAddr);
        treasureManager.grantRewards(testToken, address(this), rewardAmount);
        vm.stopPrank();
        assertEq(treasureManager.granterRewardAmount(address(this)), rewardAmount, "Incorrect grant reward amount");
    }   
}