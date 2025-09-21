// SPDX-License-Identifier: MIT
// contracts/Market.sol - Market contract
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "./CCIPReceiverUpgradeable.sol";
import {Client} from "@chainlink/contracts-ccip/contracts/libraries/Client.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";
// 一个NFT拍卖市场
contract NFT is ERC721URIStorageUpgradeable, CCIPReceiverUpgradeable, UUPSUpgradeable {

    // 跨链消息来源链的链 ID（如 Solana 为 101，需参考 CCIP 文档）
    uint64 public sourceChainId;

    uint256 public _nextTokenId;
    address public _owner;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers(); // 防止构造函数被误调用
    }
    // 添加消息 ID 缓存
    mapping(bytes32 => bool) public processedMessages;
    mapping(uint64 => bool) public supportedChainIds;  // 支持的链ID
    function initialize(address _ccipRouter, uint64 _sourceChainId) public initializer {
        // 调用父合约的初始化函数
        __ERC721_init("MyNFT", "MNT");
        __ERC721URIStorage_init();
        __UUPSUpgradeable_init();
        __CCIPReceiver_init(_ccipRouter);  // 初始化 CCIPReceiver
        _owner = msg.sender;
        sourceChainId = _sourceChainId;
        _nextTokenId = 1; // 在初始化函数中设置初始值
    }

    event SendNFT(address recipient, string tokenURI, uint256 tokenId);
    // 事件日志
    event CrossChainMessageReceived(
        bytes32 indexed messageId,
        uint64 indexed sourceChainId,
        uint256 indexed tokenId,
        address recipient
    );

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        virtual 
        onlyOwner
    {}

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call this function");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function supportsInterface(bytes4 interfaceId) 
        public 
        pure 
        override(ERC721URIStorageUpgradeable, CCIPReceiverUpgradeable) 
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }

    // 发放一个NFT
    // 1. 生成一个新的tokenId
    // 2. 给recipient mint一个token
    // 3. 设置token的URI
    function sendNFT(
        address recipient,
        string memory tokenURI
    ) public onlyOwner returns (uint256) {
        require(recipient != address(0), "Recipient address cannot be zero");

        uint256 _tokenId = _nextTokenId++;
        _mint(recipient, _tokenId);
        _setTokenURI(_tokenId, tokenURI);

        emit SendNFT(recipient, tokenURI, _tokenId);

        return _tokenId;
    }

    // 转移一个NFT
    function transferNFT(address to, uint256 tokenId) public {
        require(to != address(0), "Recipient address cannot be zero");
        // 函数会自动检查调用者是否为代币所有者、被授权者或运营商
        safeTransferFrom(msg.sender, to, tokenId);
    }

    // 获取下一个Token ID
    function getNextTokenId() public view returns (uint256) {
        return _nextTokenId;
    }

    /// handle a received message
    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    ) internal override {
         // 校验消息来源链（防止非预期链的消息）
        require(msg.sender == ccipRouter, "Only CCIP router can send messages");
        require(any2EvmMessage.sourceChainSelector == sourceChainId, "Invalid source chain");
        // 同个跨链消息只处理一次
        require(!processedMessages[any2EvmMessage.messageId], "Message already processed");
        processedMessages[any2EvmMessage.messageId] = true;

        // 解析消息内容（示例格式：bytes = abi.encode(tokenId, senderAddress, uri)）
        (uint256 tokenId, address nftOwner, string memory tokenURI) = abi
            .decode(any2EvmMessage.data, (uint256, address, string));

        // 铸造 NFT（ERC-721 单例铸造）
        _safeMint(nftOwner, tokenId);
        _setTokenURI(tokenId, tokenURI);

        emit CrossChainMessageReceived(
            any2EvmMessage.messageId,
            any2EvmMessage.sourceChainSelector,
            tokenId,
            nftOwner
        );
    }

}
