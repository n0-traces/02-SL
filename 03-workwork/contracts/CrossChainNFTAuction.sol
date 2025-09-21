// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CrossChainNFTBridge.sol";

/**
 * @title CrossChainNFTAuction
 * @dev 跨链NFT拍卖主合约
 */
contract CrossChainNFTAuction is ReentrancyGuard, Ownable {
    // 拍卖状态
    enum AuctionStatus {
        PENDING,
        ACTIVE,
        ENDED,
        CANCELLED
    }

    // 拍卖信息
    struct Auction {
        bytes32 id; // 拍卖唯一ID
        address nftOwner; // NFT所有者
        address nftContract; // NFT合约地址
        uint256 tokenId; // NFT ID
        uint256 startTime; // 开始时间
        uint256 endTime; // 结束时间
        uint256 startingPrice; // 起拍价
        address paymentToken; // 支付代币
        uint256 currentBid; // 当前出价
        address currentWinner; // 当前赢家
        AuctionStatus status; // 拍卖状态
        uint256 sourceChainId; // 源链ID
        bytes32 nftLockId; // NFT锁定ID
        mapping(address => uint256) bids; // 记录所有出价
    }

    // 拍卖ID => 拍卖信息
    mapping(bytes32 => Auction) public auctions;

    // 所有拍卖ID
    bytes32[] public allAuctionIds;

    // 跨链消息处理器
    address public messageProcessor;

    // 跨链桥合约
    address public bridgeContract;

    // 事件
    event AuctionCreated(bytes32 indexed auctionId, address indexed owner, address indexed nftContract, uint256 tokenId);
    event BidPlaced(bytes32 indexed auctionId, address indexed bidder, uint256 amount);
    event AuctionEnded(bytes32 indexed auctionId, address indexed winner, uint256 finalPrice);
    event AuctionCancelled(bytes32 indexed auctionId);
    event MessageProcessorUpdated(address indexed newProcessor);
    event BridgeContractUpdated(address indexed newBridge);

    modifier onlyMessageProcessor() {
        require(msg.sender == messageProcessor, "Only message processor can call");
        _;
    }

    // 原构造函数
    constructor(address _messageProcessor, address _bridgeContract, address initialOwner) Ownable(initialOwner) {
        require(_messageProcessor != address(0), "Invalid message processor");
        messageProcessor = _messageProcessor;
        bridgeContract = _bridgeContract;
    }

    /**
     * @dev 更新消息处理器地址
     * @param _newProcessor 新的消息处理器地址
     */
    function updateMessageProcessor(address _newProcessor) external onlyOwner {
        require(_newProcessor != address(0), "Invalid address");
        messageProcessor = _newProcessor;
        emit MessageProcessorUpdated(_newProcessor);
    }

    /**
     * @dev 更新桥合约地址
     * @param _newBridge 新的桥合约地址
     */
    function updateBridgeContract(address _newBridge) external onlyOwner {
        bridgeContract = _newBridge;
        emit BridgeContractUpdated(_newBridge);
    }

    /**
     * @dev 创建本地NFT拍卖
     */
    function createAuction(
        address nftContract,
        uint256 tokenId,
        uint256 startTime,
        uint256 endTime,
        uint256 startingPrice,
        address paymentToken
    ) external nonReentrant returns (bytes32) {
        require(startTime >= block.timestamp, "Start time in the past");
        require(endTime > startTime, "End time must be after start time");
        require(startingPrice > 0, "Starting price must be positive");

        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");
        require(nft.isApprovedForAll(msg.sender, address(this)) || nft.getApproved(tokenId) == address(this), "Contract not approved");

        // 生成拍卖ID
        bytes32 auctionId = keccak256(abi.encodePacked(block.chainid, nftContract, tokenId, block.timestamp, msg.sender));

        // 创建拍卖
        Auction storage auction = auctions[auctionId];
        auction.id = auctionId;
        auction.nftOwner = msg.sender;
        auction.nftContract = nftContract;
        auction.tokenId = tokenId;
        auction.startTime = startTime;
        auction.endTime = endTime;
        auction.startingPrice = startingPrice;
        auction.paymentToken = paymentToken;
        auction.status = AuctionStatus.PENDING;
        auction.sourceChainId = block.chainid;

        // 将NFT转移到合约
        nft.transferFrom(msg.sender, address(this), tokenId);

        allAuctionIds.push(auctionId);

        emit AuctionCreated(auctionId, msg.sender, nftContract, tokenId);

        return auctionId;
    }

    /**
     * @dev 创建跨链NFT拍卖（由消息处理器调用）
     */
    function createCrossChainAuction(
        address nftOwner,
        address nftContract,
        uint256 tokenId,
        uint256 startTime,
        uint256 endTime,
        uint256 startingPrice,
        address paymentToken,
        uint256 sourceChainId,
        bytes32 nftLockId
    ) external onlyMessageProcessor returns (bytes32) {
        require(startTime >= block.timestamp, "Start time in the past");
        require(endTime > startTime, "End time must be after start time");
        require(startingPrice > 0, "Starting price must be positive");
        require(sourceChainId != 0, "Invalid source chain ID");

        // 生成拍卖ID
        bytes32 auctionId = keccak256(abi.encodePacked(sourceChainId, nftContract, tokenId, block.timestamp, nftOwner));

        // 创建拍卖
        Auction storage auction = auctions[auctionId];
        auction.id = auctionId;
        auction.nftOwner = nftOwner;
        auction.nftContract = nftContract;
        auction.tokenId = tokenId;
        auction.startTime = startTime;
        auction.endTime = endTime;
        auction.startingPrice = startingPrice;
        auction.paymentToken = paymentToken;
        auction.status = AuctionStatus.PENDING;
        auction.sourceChainId = sourceChainId;
        auction.nftLockId = nftLockId;

        allAuctionIds.push(auctionId);

        emit AuctionCreated(auctionId, nftOwner, nftContract, tokenId);

        return auctionId;
    }

    /**
     * @dev 本地竞价
     */
    function placeBid(bytes32 auctionId) external payable nonReentrant {
        Auction storage auction = auctions[auctionId];
        require(auction.status == AuctionStatus.ACTIVE, "Auction not active");
        require(block.timestamp < auction.endTime, "Auction ended");

        uint256 bidAmount;
        if (auction.paymentToken == address(0)) {
            // 以太币支付
            bidAmount = msg.value;
            require(bidAmount > auction.currentBid, "Bid too low");
            require(bidAmount >= auction.startingPrice, "Bid below starting price");
        } else {
            // ERC20代币支付
            revert("ERC20 bidding not implemented");
        }

        // 记录旧赢家，用于退款
        address oldWinner = auction.currentWinner;
        uint256 oldBid = auction.currentBid;

        // 更新拍卖信息
        auction.currentBid = bidAmount;
        auction.currentWinner = msg.sender;
        auction.bids[msg.sender] += bidAmount;

        // 向旧赢家退款
        if (oldWinner != address(0) && oldBid > 0) {
            (bool success, ) = oldWinner.call{value: oldBid}("");
            require(success, "Refund failed");
        }

        emit BidPlaced(auctionId, msg.sender, bidAmount);
    }

    /**
     * @dev 处理跨链竞价（由消息处理器调用）
     */
    function processCrossChainBid(
        bytes32 auctionId,
        address bidder,
        uint256 bidAmount,
        uint256 bidChainId
    ) external onlyMessageProcessor {
        Auction storage auction = auctions[auctionId];
        require(auction.status == AuctionStatus.ACTIVE, "Auction not active");
        require(block.timestamp < auction.endTime, "Auction ended");
        require(bidAmount > auction.currentBid, "Bid too low");
        require(bidAmount >= auction.startingPrice, "Bid below starting price");

        // 记录旧赢家信息
        address oldWinner = auction.currentWinner;
        uint256 oldBid = auction.currentBid;

        // 更新拍卖信息
        auction.currentBid = bidAmount;
        auction.currentWinner = bidder;
        auction.bids[bidder] += bidAmount;

        // 跨链退款逻辑将通过消息处理器发送到源链

        emit BidPlaced(auctionId, bidder, bidAmount);
    }

    /**
     * @dev 开始拍卖
     */
    function startAuction(bytes32 auctionId) external nonReentrant {
        Auction storage auction = auctions[auctionId];
        require(auction.nftOwner == msg.sender, "Not the owner");
        require(auction.status == AuctionStatus.PENDING, "Auction not pending");
        require(block.timestamp >= auction.startTime, "Auction not started yet");

        auction.status = AuctionStatus.ACTIVE;
    }

    /**
     * @dev 结束拍卖并结算
     */
    function endAuction(bytes32 auctionId) external nonReentrant {
        Auction storage auction = auctions[auctionId];
        require(auction.status == AuctionStatus.ACTIVE, "Auction not active");
        require(block.timestamp > auction.endTime, "Auction not ended yet");

        auction.status = AuctionStatus.ENDED;

        // 如果有赢家
        if (auction.currentWinner != address(0) && auction.currentBid > 0) {
            // 1. 向NFT所有者转账
            if (auction.paymentToken == address(0)) {
                // 以太币支付
                (bool success, ) = auction.nftOwner.call{value: auction.currentBid}("");
                require(success, "Payment failed");
            } else {
                // ERC20代币支付
                revert("ERC20 payment not implemented");
            }

            // 2. 转移NFT给赢家
            if (auction.sourceChainId == block.chainid) {
                // 本地NFT，直接转移
                IERC721(auction.nftContract).transferFrom(address(this), auction.currentWinner, auction.tokenId);
            } else {
                // 跨链NFT，通过桥解锁并转移
                require(bridgeContract != address(0), "Bridge contract not set");
                CrossChainNFTBridge(bridgeContract).unlockNFT(auction.nftLockId, auction.currentWinner);
            }
        } else {
            // 没有赢家，将NFT返还给原所有者
            if (auction.sourceChainId == block.chainid) {
                IERC721(auction.nftContract).transferFrom(address(this), auction.nftOwner, auction.tokenId);
            } else {
                require(bridgeContract != address(0), "Bridge contract not set");
                CrossChainNFTBridge(bridgeContract).unlockNFT(auction.nftLockId, auction.nftOwner);
            }
        }

        emit AuctionEnded(auctionId, auction.currentWinner, auction.currentBid);
    }

    /**
     * @dev 取消拍卖
     */
    function cancelAuction(bytes32 auctionId) external nonReentrant {
        Auction storage auction = auctions[auctionId];
        require(auction.nftOwner == msg.sender, "Not the owner");
        require(auction.status == AuctionStatus.PENDING || auction.status == AuctionStatus.ACTIVE, "Cannot cancel this auction");

        auction.status = AuctionStatus.CANCELLED;

        // 返还NFT
        if (auction.sourceChainId == block.chainid) {
            IERC721(auction.nftContract).transferFrom(address(this), auction.nftOwner, auction.tokenId);
        } else {
            require(bridgeContract != address(0), "Bridge contract not set");
            CrossChainNFTBridge(bridgeContract).unlockNFT(auction.nftLockId, auction.nftOwner);
        }

        // 退还所有出价
        // 简化版，实际实现中需要处理所有出价的退款

        emit AuctionCancelled(auctionId);
    }

    /**
     * @dev 获取拍卖数量
     */
    function getAuctionCount() external view returns (uint256) {
        return allAuctionIds.length;
    }

    /**
     * @dev 获取拍卖详情
     */
    function getAuctionDetails(bytes32 auctionId) external view returns (
        address nftOwner,
        address nftContract,
        uint256 tokenId,
        uint256 startTime,
        uint256 endTime,
        uint256 currentBid,
        address currentWinner,
        AuctionStatus status,
        uint256 sourceChainId
    ) {
        Auction storage auction = auctions[auctionId];
        return (
            auction.nftOwner,
            auction.nftContract,
            auction.tokenId,
            auction.startTime,
            auction.endTime,
            auction.currentBid,
            auction.currentWinner,
            auction.status,
            auction.sourceChainId
        );
    }

    // 接收以太币
    receive() external payable {}
}
