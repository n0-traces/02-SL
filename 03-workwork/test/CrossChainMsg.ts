import { expect } from "chai";
import { ethers, upgrades } from "hardhat";

import { CrossChainMessageProcessor, CrossChainNFTBridge } from "../typechain-types";

describe("CrossChainMessageProcessor", function () {
    let owner: any
    let nonOwner: any

    let processor: CrossChainMessageProcessor;
    owner =ethers.getSigners()
    nonOwner =owner
    // 辅助函数：部署 CrossChainMessageProcessor 合约
    async function deployCrossChainMessageProcessor(
        initialOwner: string
    ): Promise<CrossChainMessageProcessor> {
        const CrossChainMessageProcessorFactory = await ethers.getContractFactory(
            "CrossChainMessageProcessor"
        );
        const contract = await CrossChainMessageProcessorFactory.deploy(initialOwner);
        await contract.waitForDeployment();
        return contract as CrossChainMessageProcessor;
    }

    // 辅助函数：部署 CrossChainNFTBridge 合约
    async function deployCrossChainNFTBridge(
        messageProcessorAddr: string,
        initialOwner: string
    ): Promise<CrossChainNFTBridge> {
        const CrossChainNFTBridgeFactory = await ethers.getContractFactory(
            "CrossChainNFTBridge"
        );
        const contract = await CrossChainNFTBridgeFactory.deploy(
            messageProcessorAddr,
            initialOwner
        );
        await contract.waitForDeployment();
        return contract as CrossChainNFTBridge;
    }

    beforeEach(async function () {
        [owner, nonOwner] = await ethers.getSigners();
        processor = await deployCrossChainMessageProcessor(owner.address);
    });

    it("应正确初始化合约所有者", async function () {
        expect(await processor.owner()).to.equal(owner.address);
    });

    it("应拒绝非所有者设置拍卖合约", async function () {
        await expect(
            processor.connect(nonOwner).setAuctionContract(ethers.ZeroAddress)
        ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("应正确添加跨链桥配置", async function () {
        const testChainId = 123;
        await processor.waitForDeployment()
        // 异步获取地址并打印
        const processorAddress = await processor.getAddress();
        const testBridge = await deployCrossChainNFTBridge(
            processorAddress,
            owner.address
        );

        await expect(processor.addBridgeContract(testBridge.target, testChainId))
            .to.emit(processor, "BridgeAdded")
            .withArgs(testChainId, testBridge.target);
    });
});