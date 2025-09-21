// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAutionFactory {
    function autionEnd(address autionAddress) external;
    function formatLinkToUsdtPrice(uint256 amount) external returns(uint256);
    function formatEthToUsdtPrice(uint256 amount) external returns(uint256);
}
