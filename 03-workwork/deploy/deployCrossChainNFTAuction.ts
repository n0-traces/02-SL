import { ethers, network } from "hardhat";

async function main() {
    console.log(`开始部署CrossChainNFTAuction合约到 ${network.name} 网络...`);

    // 获取部署者账户
    const [deployer] = await ethers.getSigners();
    console.log(`部署者地址: ${deployer.address}`);
    // console.log(`部署者账户余额: ${ethers.utils.formatEther(await deployer.getBalance())} ETH`);

    // 部署消息处理器合约
    console.log("部署CrossChainMessageProcessor合约...");
    const MessageProcessorFactory = await ethers.getContractFactory("CrossChainMessageProcessor");
    // 传递部署者地址作为 initialOwner
    const messageProcessor = await MessageProcessorFactory.deploy(deployer.address);
    await messageProcessor.waitForDeployment()
    // 异步获取地址并打印
    const processorAddress = await messageProcessor.getAddress();
    console.log("CrossChainMessageProcessor 部署地址: " + processorAddress);


    // 部署拍卖合约
    console.log("部署CrossChainNFTAuction合约...");
    const AuctionFactory = await ethers.getContractFactory("CrossChainNFTAuction");
    const auctionContract = await AuctionFactory.deploy(
        processorAddress,
        ethers.ZeroAddress ,// 暂时设置为零地址，稍后更新
        deployer.address
    );
    await auctionContract.waitForDeployment()
    const auctionAddress = await auctionContract.getAddress();
    console.log(`CrossChainNFTAuction部署地址: ${auctionAddress}`);

    // 部署桥合约
    console.log("部署CrossChainNFTBridge合约...");
    const BridgeFactory = await ethers.getContractFactory("CrossChainNFTBridge");
    const bridgeContract = await BridgeFactory.deploy(processorAddress, deployer.address);
    await bridgeContract.waitForDeployment()
    const bridgeAddress = await bridgeContract.getAddress();
    console.log(`CrossChainNFTBridge部署地址: ${bridgeAddress}`);

    //配置消息处理器
    console.log("配置消息处理器...");
    await messageProcessor.setAuctionContract(auctionAddress);
    console.log("已设置拍卖合约地址");

    // 添加桥合约和链ID
    const chainId = network.config.chainId || 31337;
    await messageProcessor.addBridgeContract(bridgeAddress, chainId);
    console.log(`已添加桥合约，链ID: ${chainId}`);

    // 更新拍卖合约的桥地址
    await auctionContract.updateBridgeContract(bridgeAddress);
    console.log("已更新拍卖合约的桥地址");

    // 添加可信中继器（部署者作为初始中继器）
    await messageProcessor.addTrustedRelayer(deployer.address);
    console.log("已添加部署者作为可信中继器");

    console.log("部署和配置完成!");

    // 输出验证合约所需的信息
    console.log("\n合约验证信息:");
    console.log(`npx hardhat verify --network ${network.name} ${processorAddress}`);
    console.log(`npx hardhat verify --network ${network.name} ${bridgeAddress} ${processorAddress}`);
    console.log(`npx hardhat verify --network ${network.name} ${auctionAddress} ${processorAddress} ${bridgeAddress}`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("部署过程中发生错误:", error);
        process.exit(1);
    });
