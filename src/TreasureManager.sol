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


    uint32 public periodTime;

    IERC20 public tokenAddress;
    address  public treasureManager;
    address  public withdrawManager;


    mapping(address => uint256) public tokenBalances;
    mapping(address => mapping(address => uint256)) public granterRewards;


    event DepositToken(
        address indexed tokenAddress,
        address indexed sender,
        uint256 amount
    );

    event WithdrawToken(
        address indexed tokenAddress,
        address indexed sender,
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

    function depositETH(uint256 amount) external payable nonReentrant returns (bool) {
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
        tokenBalances[tokenAddress] += amount;
        emit DepositToken(
            tokenAddress,
            msg.sender,
            msg.value
        );
        return true;
    }

    function grantRewards(IERC20 tokenAddress, address granter, uint256 amount) external onlyTreasureManager {

    }

    function claimTokens() external {

    }

    function claimToken() external {

    }

    function getRewardAmountByToken(IERC20 tokenAddress) external {

    }

    function getAllRewardAmount() external {

    }

    function withdrawETH(address payable withdrawAddress, uint256 amount) external payable onlyWithdrawManager returns (bool) {
        (bool success, ) = withdrawAddress.call{value: amount}("");
        if (!sent) {
            return false;
        }
        tokenBalances[ethAddress] -= amount;
        emit DepositToken(
            ethAddress,
            msg.sender,
            msg.value
        );
        return true;
    }

    function withdrawERC20(IERC20 tokenAddress, address withdrawAddress, uint256 amount) external onlyWithdrawManager returns (bool) {
        tokenAddress.safeTransferFrom(address(this), msg.sender, amount);
        tokenBalances[tokenAddress] -= amount;
        emit WithdrawToken(
            tokenAddress,
            msg.sender,
            msg.value
        );
        return true;
    }
}
