// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITreasureManager {
    function depositETH() external payable returns (bool);
    function depositERC20(IERC20 tokenAddress, uint256 amount) external returns (bool);
    function grantRewards(IERC20 tokenAddress, address granter, uint256 amount) external;
    function claimAllTokens() external;
    function claimToken(IERC20 tokenAddress) external;
    function withdrawETH(address payable withdrawAddress, uint256 amount) external payable returns (bool);
    function withdrawERC20(IERC20 tokenAddress, address withdrawAddress, uint256 amount) external returns (bool);
    function setTokenWhiteList(address tokenAddress) external;
    function setWithdrawManager(address _withdrawManager) external;
    function queryReward(address _tokenAddress) external view returns (uint256);
}
