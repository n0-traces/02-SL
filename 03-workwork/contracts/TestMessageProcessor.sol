// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./CrossChainNFTBridge.sol";

/**
 * @title TestMessageProcessor
 * @dev 用于测试的消息处理器实现
 */
contract TestMessageProcessor {
    /**
     * @dev 测试用的解锁NFT函数
     */
    function unlockNFT(
        address bridgeContract,
        bytes32 lockId,
        address receiver
    ) external {
        CrossChainNFTBridge(bridgeContract).unlockNFT(lockId, receiver);
    }
}
