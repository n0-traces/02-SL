// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CrossChainNFTBridge
 * @dev 负责NFT的跨链锁定与解锁
 */
contract CrossChainNFTBridge is ReentrancyGuard, Ownable {
    // 记录锁定的NFT
    struct LockedNFT {
        address originalOwner;
        address nftContract;
        uint256 tokenId;
        uint256 chainId; // 原始链ID
        bool isLocked;
    }

    // 锁定NFT的唯一标识 => 锁定信息
    mapping(bytes32 => LockedNFT) public lockedNFTs;

    // 跨链消息处理器地址
    address public messageProcessor;

    // 事件
    event NFTLocked(bytes32 indexed lockId, address indexed owner, address indexed nftContract, uint256 tokenId, uint256 targetChainId);
    event NFTUnlocked(bytes32 indexed lockId, address indexed receiver, address indexed nftContract, uint256 tokenId);

    // 权限控制：仅消息处理器可调用
    modifier onlyMessageProcessor() {
        require(msg.sender == messageProcessor, "Only message processor can call");
        _;
    }

    // 原构造函数
    constructor(address _messageProcessor, address initialOwner) Ownable(initialOwner) {
        messageProcessor = _messageProcessor;
    }

    /**
     * @dev 锁定NFT以准备跨链转移
     * @param nftContract NFT合约地址
     * @param tokenId NFT ID
     * @param targetChainId 目标链ID
     * @return lockId 锁定的唯一标识
     */
    function lockNFT(address nftContract, uint256 tokenId, uint256 targetChainId) external nonReentrant returns (bytes32) {
        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");

        // 转移NFT到桥合约
        nft.transferFrom(msg.sender, address(this), tokenId);

        // 生成唯一锁定ID
        bytes32 lockId = keccak256(abi.encodePacked(block.chainid, nftContract, tokenId, block.timestamp, msg.sender));

        // 记录锁定信息
        lockedNFTs[lockId] = LockedNFT({
            originalOwner: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            chainId: block.chainid,
            isLocked: true
        });

        emit NFTLocked(lockId, msg.sender, nftContract, tokenId, targetChainId);

        return lockId;
    }

    /**
     * @dev 解锁NFT（跨链转移回来时）
     * @param lockId 锁定的唯一标识
     * @param receiver 接收者地址
     */
    function unlockNFT(bytes32 lockId, address receiver) external nonReentrant onlyMessageProcessor {
        LockedNFT storage lockedNFT = lockedNFTs[lockId];
        require(lockedNFT.isLocked, "NFT not locked");

        // 标记为已解锁
        lockedNFT.isLocked = false;

        // 转移NFT给接收者
        IERC721(lockedNFT.nftContract).transferFrom(address(this), receiver, lockedNFT.tokenId);

        emit NFTUnlocked(lockId, receiver, lockedNFT.nftContract, lockedNFT.tokenId);
    }

    /**
     * @dev 更新消息处理器地址
     * @param _newProcessor 新的消息处理器地址
     */
    function updateMessageProcessor(address _newProcessor) external onlyOwner {
        require(_newProcessor != address(0), "Invalid address");
        messageProcessor = _newProcessor;
    }
}
