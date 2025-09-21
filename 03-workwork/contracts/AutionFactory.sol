// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Aution.sol";
import "./interfaces/IAutionFactory.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import 'hardhat/console.sol';

//拍卖市场
// 1. 拍卖市场可以创建拍卖
contract AutionFactory is IAutionFactory {
    //所有的拍卖
    address[] public autions;
    // 拍卖场所有者
    address private marketOwner;
    // 下一个拍卖Id
    uint256 private _nextAutionId = 1;
    // 拍卖Id => 拍卖合约地址
    mapping(uint256 autionId => address autionContract) private _autionData;
    // 链上价格
    mapping(address => AggregatorV3Interface) private _priceFeeds;

    address linkAddress = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
    address ethAddress = 0x0000000000000000000000000000000000000000;

    event AutionCreated(address indexed autionAddress);

    bool private _isHardHat = false;
    //linkAddress 如果使用本地地址（如 Hardhat 本地网络部署的 MockLINK 合约地址），
//会导致 价格喂价（AggregatorV3Interface）调用失败，因为你绑定的
//0xc59E3633BAAC79493d908e63626716e204A45EdF
//和 0x694AA1769357215DE4FAC081bf1f309aDC325306
//大概率是 Sepolia 测试网的 Chainlink 价格喂价地址，在本地网络中这些地址是无效的（没有部署对应的合约）
    constructor(bool isHardHat, address _linkAddress) {

        marketOwner = msg.sender;
        if (_linkAddress != address(0)) {
            linkAddress = _linkAddress;
        }
        console.log("linkAddress=====", linkAddress);
        _priceFeeds[linkAddress] = AggregatorV3Interface(0xc59E3633BAAC79493d908e63626716e204A45EdF);
        _priceFeeds[ethAddress] = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        _isHardHat = isHardHat;
    }

    //创建拍卖
    function createAution(
        address _nftContract,
        uint256 _nftTokenId,
        uint256 _startingPrice,
        uint256 _duraion
    ) public returns (uint256) {
        Aution aution = new Aution();

        uint256 _startingPriceUsdt = formatEthToUsdtPrice(_startingPrice);

        aution.initialize(
            msg.sender,
            _nftContract,
            _nftTokenId,
            _startingPriceUsdt,
            block.timestamp,
            _duraion
        );

        //将NFT转让给拍卖合约
        IERC721 nftContrac = IERC721(_nftContract);
        nftContrac.transferFrom(msg.sender, address(aution), _nftTokenId);

        address autionAddress = address(aution);

        autions.push(autionAddress);

        uint256 autionId = _nextAutionId++;
        _autionData[autionId] = autionAddress;

        emit AutionCreated(autionAddress);

        return autionId;
    }

    // 正在拍卖的NFT数量
    function getAutionCount() public view returns (uint256) {
        return autions.length;
    }

    /**获取拍卖Id对应的合约地址 */
    function getAutionContract(uint256 _autionId) public view returns (address) {
        return _autionData[_autionId];
    }

    // 某个拍卖结束
    function autionEnd(address autionAddress) external override {
        for (uint256 i = 0; i < autions.length; i++) {
            if (autions[i] == autionAddress) {
                autions[i] = autions[autions.length - 1];
                autions.pop();
                break;
            }
        }
    }

    //获取link/usdt价格
    function formatLinkToUsdtPrice(uint256 amount) public view override returns(uint256) {
        if (_isHardHat) {
            return amount * uint256(276869763895);
        }

        AggregatorV3Interface priceFeed = _priceFeeds[linkAddress];
        (,int256 price,,,) = priceFeed.latestRoundData();
        return amount * uint256(price);
    }

    //获取eth/usdt价格
    function formatEthToUsdtPrice(uint256 amount) public view override returns(uint256) {
        if (_isHardHat) {
            return amount * uint256(1452876000);
        }

        AggregatorV3Interface priceFeed = _priceFeeds[ethAddress];
        (,int256 price,,,) = priceFeed.latestRoundData();
        return amount * uint256(price);
    }
}
