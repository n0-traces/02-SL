// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./CrossChainNFTAuction.sol";

/**
 * @title CrossChainMessageProcessor
 * @dev 处理跨链消息，验证并执行跨链操作
 */
contract CrossChainMessageProcessor is Ownable {
    // 可信的跨链中继器
    mapping(address => bool) public trustedRelayers;

    // 源链桥合约地址 => 链ID
    mapping(address => uint256) public bridgeContracts;

    // 拍卖合约地址
    address payable  public auctionContract;

    // 事件
    event MessageProcessed(bytes32 indexed messageId, address indexed relayer, uint256 indexed sourceChainId);
    event RelayerAdded(address indexed relayer);
    event RelayerRemoved(address indexed relayer);
    event BridgeContractAdded(address indexed bridge, uint256 chainId);
    event AuctionContractUpdated(address indexed newAuctionContract);

    modifier onlyTrustedRelayer() {
        require(trustedRelayers[msg.sender], "Not a trusted relayer");
        _;
    }
    // 原构造函数
    constructor(address initialOwner) Ownable(initialOwner) {}
    /**
     * @dev 添加可信中继器
     * @param relayer 中继器地址
     */
    function addTrustedRelayer(address relayer) external onlyOwner {
        require(relayer != address(0), "Invalid address");
        trustedRelayers[relayer] = true;
        emit RelayerAdded(relayer);
    }

    /**
     * @dev 移除可信中继器
     * @param relayer 中继器地址
     */
    function removeTrustedRelayer(address relayer) external onlyOwner {
        require(trustedRelayers[relayer], "Not a trusted relayer");
        trustedRelayers[relayer] = false;
        emit RelayerRemoved(relayer);
    }

    /**
     * @dev 添加桥合约地址
     * @param bridge 桥合约地址
     * @param chainId 链ID
     */
    function addBridgeContract(address bridge, uint256 chainId) external onlyOwner {
        require(bridge != address(0), "Invalid address");
        require(chainId != 0, "Invalid chain ID");
        bridgeContracts[bridge] = chainId;
        emit BridgeContractAdded(bridge, chainId);
    }

    /**
     * @dev 设置拍卖合约地址
     * @param _auctionContract 拍卖合约地址
     */
    function setAuctionContract(address payable  _auctionContract) external onlyOwner {
        require(_auctionContract != address(0), "Invalid address");
        auctionContract = _auctionContract;
        emit AuctionContractUpdated(_auctionContract);
    }

    /**
     * @dev 处理跨链拍卖创建消息
     */
    function processCreateAuctionMessage(
        bytes32 messageId,
        address sourceBridge,
        address nftOwner,
        address nftContract,
        uint256 tokenId,
        uint256 startTime,
        uint256 endTime,
        uint256 startingPrice,
        address paymentToken,
        bytes32 nftLockId
    ) external onlyTrustedRelayer {
        require(auctionContract != address(0), "Auction contract not set");

        uint256 sourceChainId = bridgeContracts[sourceBridge];
        require(sourceChainId != 0, "Unknown source bridge");

        // 调用拍卖合约创建跨链拍卖
        CrossChainNFTAuction(auctionContract).createCrossChainAuction(
            nftOwner,
            nftContract,
            tokenId,
            startTime,
            endTime,
            startingPrice,
            paymentToken,
            sourceChainId,
            nftLockId
        );

        emit MessageProcessed(messageId, msg.sender, sourceChainId);
    }

    /**
     * @dev 处理跨链竞价消息
     */
    function processBidMessage(
        bytes32 messageId,
        address sourceBridge,
        bytes32 auctionId,
        address bidder,
        uint256 bidAmount,
        uint256 bidChainId
    ) external onlyTrustedRelayer {
        require(auctionContract != address(0), "Auction contract not set");

        uint256 sourceChainId = bridgeContracts[sourceBridge];
        require(sourceChainId != 0, "Unknown source bridge");

        // 调用拍卖合约处理跨链竞价
        CrossChainNFTAuction(auctionContract).processCrossChainBid(
            auctionId,
            bidder,
            bidAmount,
            bidChainId
        );

        emit MessageProcessed(messageId, msg.sender, sourceChainId);
    }
}
