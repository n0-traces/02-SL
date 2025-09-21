// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IAutionFactory.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import 'hardhat/console.sol';
import "@openzeppelin/contracts/utils/Strings.sol";
// 拍卖合约
// 支持货币 ETH 和 ERC20代币
contract Aution is ReentrancyGuard {
    // 拍卖市场地址
    address public factory;
    // NFT拍卖发起人地址
    address public seller;
    // NFT合约地址
    address public nftContract;
    // NFT TokenId
    uint256 public nftTokenId;
    // 开始时间
    uint256 public startTime;
    // 结束时间
    uint256 public endTime;
    // 起拍价
    uint256 public startPrice;
    // 当前最高出价
    uint256 public highestBid;
    // 当前最高出价者
    address public highestBidder;
    // 货币类型 0x00: ETH 其他: LINK
    address public tokenAddress;
    // 货币的真实数量
    uint256 public tokenValue = 0;
    // 拍卖是否结束
    bool public isEnd;

    //出价记录
    mapping(address => uint256) public bidsData;

    modifier onlyFactory() {
        require(msg.sender == factory, "Only factory can call this function");
        _;
    }

    modifier onlySeller() {
        require(msg.sender == seller, "Only seller can call this function");
        _;
    }

    modifier timeToBid() {
        require(
            block.timestamp >= startTime && block.timestamp <= endTime,
            "Aution not start or end"
        );
        _;
    }

    fallback() external payable {}

    receive() external payable {}

    constructor() {
        factory = msg.sender;
    }

    // 初始化拍卖
    function initialize(
        address _seller,
        address _nftContract,
        uint256 _nftTokenId,
        uint256 _startPrice,
        uint256 _startTime,
        uint256 _duration
    ) external onlyFactory {
        seller = _seller;
        nftContract = _nftContract;
        nftTokenId = _nftTokenId;
        startPrice = _startPrice;
        startTime = _startTime;
        endTime = _startTime + _duration;
    }

    // 拍卖出价
    function placeBidWithETH() external payable nonReentrant  {
        require(!isEnd, "Aution has end");
        require(
            block.timestamp >= startTime && block.timestamp <= endTime,
            "Aution not start or end"
        );
        uint256 amount = IAutionFactory(factory).formatEthToUsdtPrice(msg.value);
        //判断出价是否大于当前最高出价
        require(
            amount > highestBid && amount >= startPrice,
            "Bid not high enough"
        );
        
        returnToken();

        // 更新最高出价者和最高出价
        highestBidder = msg.sender;
        highestBid = amount;
        tokenAddress = address(0);
        tokenValue = msg.value;

        // 更新出价记录
        bidsData[msg.sender] = amount;
    }
    // 定义调试事件（测试时可通过日志查看）

    // 支持link币的拍卖  禁止自定义 nonReentrant（如锁变量未初始化 bool private _locked; 会导致异常）
    function placeBidWithERC20(address bidTokenAddress, uint256 value) external nonReentrant timeToBid {
        console.log("placeBidWithERC20 enter");
        require(!isEnd, "Aution has end");

        require(factory != address(0), "Invalid factory address");
        uint256 amount = IAutionFactory(factory).formatLinkToUsdtPrice(value);
        require(amount > 0, "Invalid amount from factory");
//        log("当前出价的amount====:", amount);
        //判断出价是否大于当前最高出价
        require(
            amount > highestBid && amount >= startPrice,
            "Bid not high enough"
        );
        console.log("amount=============",amount);
//        // 3. 修复日志拼接（用 Strings 库转换地址）
//        string memory logMsg = string.concat(
//            "代币转移到拍卖合约=============",
//            bidTokenAddress.toHexString() // 地址转十六进制字符串
//        );
        console.log("transferFrom to Aution=============",string(abi.encodePacked(bidTokenAddress)));
        console.log("transferFrom to Aution=============",msg.sender);
        console.log("transferFrom to Aution=============",address(this));
        console.log("transferFrom to Aution=============",value);
        // 代币转移到拍卖合约
        //Solidity 中，若函数调用（如 transferFrom）触发 revert，整个交易会回滚，revert 之后的代码（包括日志）不会执行
        bool transferSuccess = IERC20(bidTokenAddress).transferFrom(msg.sender, address(this), value);
        require(transferSuccess, "ERC20: transferFrom failed (possible reasons: insufficient allowance, low balance, invalid address)");

        console.log("transferFrom to Aution=============");
        returnToken();

        // 更新最高出价者和最高出价
        highestBidder = msg.sender;
        highestBid = amount;
        tokenAddress = bidTokenAddress;
        tokenValue = value;

        // 更新出价记录
        bidsData[msg.sender] = amount;    
    }

    /**回退拍卖的币 */
    function returnToken() private {
        emit DebugLog("returnToken enter", highestBidder, tokenAddress, tokenValue);
        // 如果有最高出价者，将最高出价退
        if (highestBidder != address(0)) {
            if (tokenAddress == address(0)) {
                emit DebugLog("Start ETH transfer", highestBidder, tokenValue);
                // 使用 safeTransferETH 替代 call，避免底层解析异常
                // 手动实现 safeTransferETH 逻辑：严格校验 call 返回值
                (bool success, bytes memory data) = payable(highestBidder).call{value: tokenValue}("");
                // 校验条件：1. call 执行成功；2. 无返回数据（或返回数据为空，避免解析异常）
                require(success && (data.length == 0), "ETH transfer failed");
                emit DebugLog("ETH transfer success", highestBidder);
            } else {
                // 退还代币
                require(
                    IERC20(tokenAddress).transfer(highestBidder, tokenValue),
                    "Token transfer failed"
                );
            }
        }
    }
    event DebugLog(string step, address indexed addr1, address addr2, uint256 value);
    event DebugLog(string step, address indexed addr, uint256 value);
    event DebugLog(string step, address indexed addr);
    // 取消拍卖
    function cancelAution() external onlySeller  {
        console.log("cancelAution enter");
        isEnd = true;
        // 将 NFT 转让给发起人
        IERC721(nftContract).transferFrom(address(this), seller, nftTokenId);

        returnToken();

        IAutionFactory(factory).autionEnd(address(this));
    }

    // 结束拍卖  这里不要加timeToBid ， endAution 函数用了 timeToBid 修饰器，但 timeToBid 的逻辑是 “拍卖进行中”，
    //而 endAution 需要的是 “拍卖已结束”（block.timestamp > endTime）—— 修饰器逻辑完全用反了
    function endAution() external onlySeller {
        console.log("endAution enter");
        // 1. 校验：拍卖未结束
        require(!isEnd, "Aution has end");
        // 2. 新增：校验时间已超过 endTime（拍卖已结束）
        require(block.timestamp > endTime, "Aution not ended yet");

        // 如果有最高出价者，将 NFT 转让给最高出价者
        if (highestBidder != address(0)) {
            IERC721(nftContract).transferFrom(
                address(this),
                highestBidder,
                nftTokenId
            );
            // 根据代币类型转移正确的金额
            if (tokenAddress == address(0)) {
                console.log("ETH transfer");
                (bool success, ) = payable(seller).call{value: tokenValue}("");
                require(success, "ETH transfer failed");
            } else {
                console.log("IERC20 transfer");
                require(
                    IERC20(tokenAddress).transfer(seller, tokenValue),
                    "Token transfer failed"
                );
            }
        } else {
            // 如果没有最高出价者，将 NFT 转让给发起人
            IERC721(nftContract).transferFrom(
                address(this),
                seller,
                nftTokenId
            );
        }
        isEnd = true;
        console.log("endAution end");
        // 触发拍卖结束事件 移出数组
        IAutionFactory(factory).autionEnd(address(this));
    }

    // 如果没有实现这个方法，使用 safeTransferFrom 将NFT转移到拍卖合约时会失败，导致拍卖无法创建。
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
