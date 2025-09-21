// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFT.sol";

contract NFTV2 is NFT {
    // 添加一个事件来记录升级
    event ContractUpgraded(address indexed newImplementation);

    // 重写 _authorizeUpgrade 函数
    function _authorizeUpgrade(address newImplementation) internal override {
        require(msg.sender == _owner, "Only owner can upgrade");
        emit ContractUpgraded(newImplementation);
    }
}