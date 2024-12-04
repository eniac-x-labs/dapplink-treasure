// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ITreasureManager.sol";

contract TreasureManager is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable, ITreasureManager {
    using SafeERC20 for IERC20;

    address public constant ethAddress = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    address public treasureManager;
    address public withdrawManager;

    address[] public tokenWhiteList;


    mapping(address => uint256) public tokenBalances;
    mapping(address => mapping(address => uint256)) public userRewardAmounts;

    error IsZeroAddress();

    event DepositToken(
        address indexed tokenAddress,
        address indexed sender,
        uint256 amount
    );

    event WithdrawToken(
        address indexed tokenAddress,
        address sender,
        address withdrawAddress,
        uint256 amount
    );

    event GrantRewardTokenAmount(
        address indexed tokenAddress,
        address granter,
        uint256 amount
    );

    event WithdrawManagerUpdate(
        address indexed withdrawManager
    );

    modifier onlyTreasureManager() {
        require(msg.sender == address(treasureManager), "TreasureManager.onlyTreasureManager");
        _;
    }

    modifier onlyWithdrawManager() {
        require(msg.sender == address(withdrawManager), "TreasureManager.onlyWithdrawer");
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner, address _treasureManager, address _withdrawManager) public initializer {
        __Ownable_init(initialOwner);
        treasureManager = _treasureManager;
        withdrawManager = _withdrawManager;
    }

    receive() external payable {
        depositETH();
    }

    function depositETH() public payable nonReentrant returns (bool) {
        tokenBalances[ethAddress] += msg.value;
        emit DepositToken(
            ethAddress,
            msg.sender,
            msg.value
        );
        return true;
    }

    function depositERC20(IERC20 tokenAddress, uint256 amount) external returns (bool) {
        tokenAddress.safeTransferFrom(msg.sender, address(this), amount);
        tokenBalances[address(tokenAddress)] += amount;
        emit DepositToken(
            address(tokenAddress),
            msg.sender,
            amount
        );
        return true;
    }

    function grantRewards(address tokenAddress, address granter, uint256 amount) external onlyTreasureManager {
        require(address(tokenAddress) != address(0) && granter != address(0), "TreasureManager grantRewards: invalid address");
        userRewardAmounts[granter][address(tokenAddress)] += amount;
        emit GrantRewardTokenAmount(address(tokenAddress), granter, amount);
    }

    function claimAllTokens() external  {
        for (uint256 i = 0; i < tokenWhiteList.length; i++) {
            address tokenAddress = tokenWhiteList[i];
            uint256 rewardAmount = userRewardAmounts[msg.sender][tokenAddress];
            if (rewardAmount > 0) {
                userRewardAmounts[msg.sender][tokenAddress] = 0;
                tokenBalances[tokenAddress] -= rewardAmount;
                if (tokenAddress == ethAddress) {
                    (bool success, ) = msg.sender.call{value: rewardAmount}("");
                    require(success, "ETH transfer failed");
                } else {
                    IERC20(tokenAddress).safeTransfer(msg.sender, rewardAmount);
                }
            }
        }
    }

    function claimToken(address tokenAddress) external {
        require(tokenAddress != address(0), "TreasureManager claimToken: invalid token address");
        uint256 rewardAmount = userRewardAmounts[msg.sender][tokenAddress];
        require(rewardAmount > 0, "TreasureManager claimToken: no reward available");
        userRewardAmounts[msg.sender][tokenAddress] = 0;
        tokenBalances[tokenAddress] -= rewardAmount;
        if (tokenAddress == ethAddress) {
            (bool success, ) = msg.sender.call{value: rewardAmount}("");
            require(success, "TreasureManager claimToken: ETH transfer failed");
        } else {
            IERC20(tokenAddress).safeTransfer(msg.sender, rewardAmount);
        }
    }

    function withdrawETH(address payable withdrawAddress, uint256 amount) external payable onlyWithdrawManager returns (bool) {
        require(address(this).balance >= amount, "TreasureManager withdrawETH: insufficient ETH balance in contract");
        tokenBalances[ethAddress] -= amount;
        (bool success, ) = withdrawAddress.call{value: amount}("");
        if (!success) {
            return false;
        }
        emit WithdrawToken(
            ethAddress,
            msg.sender,
            withdrawAddress,
            amount
        );
        return true;
    }

    function withdrawERC20(IERC20 tokenAddress, address withdrawAddress, uint256 amount) external onlyWithdrawManager returns (bool) {
        require(tokenBalances[address(tokenAddress)] >= amount, "TreasureManager withdrawERC20: Insufficient token balance in contract");
        tokenBalances[address(tokenAddress)] -= amount;
        tokenAddress.safeTransfer(withdrawAddress, amount);
        emit WithdrawToken(
            address(tokenAddress),
            msg.sender,
            withdrawAddress,
            amount
        );
        return true;
    }

    function setTokenWhiteList(address tokenAddress) external onlyTreasureManager {
        if(tokenAddress == address(0)) {
            revert IsZeroAddress();
        }
        tokenWhiteList.push(tokenAddress);
    }

    function getTokenWhiteList() external view returns (address[] memory) {
        return tokenWhiteList;
    }

    function setWithdrawManager(address _withdrawManager) external onlyOwner {
        withdrawManager = _withdrawManager;
        emit WithdrawManagerUpdate(
            withdrawManager
        );
    }

    function queryReward(address _tokenAddress) public view returns (uint256) {
        return userRewardAmounts[msg.sender][_tokenAddress];
    }
}
