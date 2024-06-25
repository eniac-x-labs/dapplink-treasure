// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ITreasureManager.sol";

contract  TreasureManager is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, ITreasureManager {
    using SafeERC20 for IERC20;

    address public constant ethAddress = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    address public treasureManager;
    address public withdrawManager;


    address[] public tokenWhiteList;


    mapping(address => uint256) public tokenBalances;
    mapping(address => address) public granterRewardTokens;
    mapping(address => uint256) public granterRewardAmount;

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


    modifier onlyTreasureManager() {
        require(msg.sender == address(treasureManager), "TreasureManager.onlyTreasureManager");
        _;
    }

    modifier onlyWithdrawManager() {
        require(msg.sender == address(withdrawManager), "TreasureManager.onlyWithdrawer");
        _;
    }


    function initialize(address _treasureManager, address _withdrawManager) public initializer {
        treasureManager = _treasureManager;
        withdrawManager = _withdrawManager;
    }

    function depositETH() external payable nonReentrant returns (bool) {
        (bool sent, ) = payable(address(this)).call{value: msg.value}("");
        if (!sent) {
            return false;
        }
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

    function grantRewards(IERC20 tokenAddress, address granter, uint256 amount) external onlyTreasureManager {
        if (address(tokenAddress) == address(0) || granter == address(0) )   {
            revert IsZeroAddress();
        }
        granterRewardTokens[address(tokenAddress)] = granter;
        granterRewardAmount[granter] = amount;
        emit GrantRewardTokenAmount(
            address(tokenAddress),
            granter,
            amount
        );
    }

    function claimTokens() external {
        for ( uint256 i = 0; i < tokenWhiteList.length; i++ ) {
            address granterAddress = granterRewardTokens[tokenWhiteList[i]];
            if (granterRewardAmount[granterAddress] > 0) {
                IERC20(tokenWhiteList[i]).safeTransferFrom(address(this), granterAddress, granterRewardAmount[granterAddress]);
            }
        }
    }

    function claimToken(IERC20 tokenAddress) external {
        if(address(tokenAddress) == address(0)) {
            revert IsZeroAddress();
        }
        address granterAddress = granterRewardTokens[address(tokenAddress)];
        if (granterRewardAmount[granterAddress] > 0) {
            tokenAddress.safeTransferFrom(address(this), granterAddress, granterRewardAmount[granterAddress]);
        }
    }

    function withdrawETH(address payable withdrawAddress, uint256 amount) external payable onlyWithdrawManager returns (bool) {
        (bool success, ) = withdrawAddress.call{value: amount}("");
        if (!success) {
            return false;
        }
        tokenBalances[ethAddress] -= amount;
        emit WithdrawToken(
            ethAddress,
            msg.sender,
            withdrawAddress,
            amount
        );
        return true;
    }

    function withdrawERC20(IERC20 tokenAddress, address withdrawAddress, uint256 amount) external onlyWithdrawManager returns (bool) {
        tokenAddress.safeTransferFrom(address(this), msg.sender, amount);
        tokenBalances[address(tokenAddress)] -= amount;
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
}
