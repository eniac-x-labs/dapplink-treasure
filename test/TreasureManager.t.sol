// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "forge-std/Test.sol";
import "../src/TreasureManager.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "forge-std/console.sol";

contract TestERC20 is ERC20 {
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }
}

contract TreasureManagerTest is Test {
    using SafeERC20 for IERC20;
    TransparentUpgradeableProxy proxyTreasureManager;
    TestERC20 testToken;
    address treasureManagerAddr = address(0x123);
    address withdrawManagerAddr = address(0x456);

    receive() external payable {}

    function setUp() public {
        TreasureManager treasureManager = new TreasureManager();
        proxyTreasureManager = new TransparentUpgradeableProxy(
            address(treasureManager),
            msg.sender,
            abi.encodeWithSelector(TreasureManager.initialize.selector, treasureManagerAddr, withdrawManagerAddr)
        );
        testToken = new TestERC20("TestToken", "TTK", 10000 * 1e18);
    }

    function testDepositETH() public {
        vm.deal(address(this), 1 ether);
        assertTrue(address(this).balance == 1 ether);
        ITreasureManager(address(proxyTreasureManager)).depositETH{value: 0.5 ether}();
        assertTrue(address(this).balance == 0.5 ether);
        assertTrue(TreasureManager(payable(address(proxyTreasureManager))).tokenBalances(address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) == 0.5 ether);
    }

    function testDepositERC20() public {
        uint256 depositAmount = 500;
        IERC20 tokenInterface = IERC20(address(testToken));
        testToken.approve(address(proxyTreasureManager), depositAmount);
        bool success = ITreasureManager(address(proxyTreasureManager)).depositERC20(tokenInterface, depositAmount);
        assertTrue(success, "ERC20 deposit to TreasureManager failed");
        assertEq(TreasureManager(payable(address(proxyTreasureManager))).tokenBalances(address(testToken)), depositAmount, "Incorrect token balance after ERC20 deposit");
    }

    function testGrantRewards() public {
        vm.prank(treasureManagerAddr);
        uint256 amount = 500;
        ITreasureManager(address(proxyTreasureManager)).grantRewards(address(testToken), address(this), amount);
        assertTrue(TreasureManager(payable(address(proxyTreasureManager))).userRewardAmounts(address(this), address(testToken)) == amount);
    }

    function testClaimAllTokens() public {
        testDepositETH();
        testDepositERC20();
        vm.prank(treasureManagerAddr);
        ITreasureManager(address(proxyTreasureManager)).grantRewards(address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE), withdrawManagerAddr, 0.001 ether);
        uint256 amount = 500;
        vm.prank(treasureManagerAddr);
        ITreasureManager(address(proxyTreasureManager)).grantRewards(address(testToken), withdrawManagerAddr, amount);
        vm.prank(treasureManagerAddr);
        ITreasureManager(address(proxyTreasureManager)).setTokenWhiteList(address(testToken));
        vm.prank(treasureManagerAddr);
        ITreasureManager(address(proxyTreasureManager)).setTokenWhiteList(address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE));
        console.log('proxyTreasureManager.tokenBalances:', TreasureManager(payable(address(proxyTreasureManager))).userRewardAmounts(withdrawManagerAddr, address(testToken)));
        console.log('proxyTreasureManager.tokenBalances:', TreasureManager(payable(address(proxyTreasureManager))).userRewardAmounts(withdrawManagerAddr, address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)));
        vm.prank(withdrawManagerAddr);
        ITreasureManager(address(proxyTreasureManager)).claimAllTokens();
        console.log('proxyTreasureManager.tokenBalances:', TreasureManager(payable(address(proxyTreasureManager))).userRewardAmounts( withdrawManagerAddr, address(testToken)));
        console.log('proxyTreasureManager.tokenBalances:', TreasureManager(payable(address(proxyTreasureManager))).userRewardAmounts( withdrawManagerAddr, address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)));
        assertTrue(TreasureManager(payable(address(proxyTreasureManager))).userRewardAmounts(withdrawManagerAddr, address(testToken)) == 0);
        assertTrue(TreasureManager(payable(address(proxyTreasureManager))).userRewardAmounts(withdrawManagerAddr, address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) == 0);
    }

    function testClaimToken() public {
        testDepositERC20();
        uint256 amount = 500;
        vm.prank(treasureManagerAddr);
        ITreasureManager(address(proxyTreasureManager)).grantRewards(address(testToken), address(this), amount);
        ITreasureManager(address(proxyTreasureManager)).claimToken(address(testToken));
        assertTrue(TreasureManager(payable(address(proxyTreasureManager))).userRewardAmounts(address(this), address(testToken)) == 0);
        assertTrue(TreasureManager(payable(address(proxyTreasureManager))).tokenBalances(address(testToken)) == 0);
        // assertTrue(testToken.balanceOf(address(this)) == amount);
    }

    function testWithdrawETH() public {
        vm.deal(address(this), 1 ether);
        ITreasureManager(address(proxyTreasureManager)).depositETH{value: 0.5 ether}();
        console.log('address(this).balance:', address(proxyTreasureManager).balance);
        assertTrue(address(proxyTreasureManager).balance == 0.5 ether);
        assertTrue(TreasureManager(payable(address(proxyTreasureManager))).tokenBalances(address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) == 0.5 ether);
        vm.prank(withdrawManagerAddr);
        ITreasureManager(address(proxyTreasureManager)).withdrawETH(payable(address(this)), 0.5 ether);
        console.log('address(this).balance:', address(proxyTreasureManager).balance);
        assertTrue(address(proxyTreasureManager).balance == 0 ether);
        assertTrue(TreasureManager(payable(address(proxyTreasureManager))).tokenBalances(address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) == 0 ether);
    }

    function testWithdrawERC20() public {
        uint256 amount = 500;
        testDepositERC20();
        testToken.approve(address(proxyTreasureManager), amount);

        uint256 initialWithdrawManagerBalance = testToken.balanceOf(withdrawManagerAddr);
        assertTrue(TreasureManager(payable(address(proxyTreasureManager))).tokenBalances(address(testToken)) == 500);
        vm.prank(withdrawManagerAddr);
        ITreasureManager(address(proxyTreasureManager)).withdrawERC20(testToken, address(withdrawManagerAddr), 500);
        console.log('testToken.balanceOf', testToken.balanceOf(withdrawManagerAddr));
        assertTrue(TreasureManager(payable(address(proxyTreasureManager))).tokenBalances(address(testToken)) == 0);
        assertEq(testToken.balanceOf(withdrawManagerAddr), initialWithdrawManagerBalance + 500);
    }

    function testQueryReward() public {
        uint256 amount = 500;
        testDepositERC20();
        vm.prank(treasureManagerAddr);
        ITreasureManager(address(proxyTreasureManager)).grantRewards(address(testToken), address(this), amount);
        assertEq(ITreasureManager(address(proxyTreasureManager)).queryReward(address(testToken)), amount);
    }

    function testSetWithdrawManager() public {
        // Set the message sender to the contract owner
        vm.prank(TreasureManager(payable(address(proxyTreasureManager))).owner());
        ITreasureManager(address(proxyTreasureManager)).setWithdrawManager(address(0x123));
        assertEq(TreasureManager(payable(address(proxyTreasureManager))).withdrawManager(), address(0x123));
    }
}