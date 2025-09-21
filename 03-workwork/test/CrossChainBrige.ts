import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import {deployContract} from "@nomicfoundation/hardhat-ethers/types";
import {CrossChainMessageProcessor,CrossChainNFTBridge} from "../typechain-types";
describe("CrossChainNFTBridge", function () {
    let owner: any
    let user: any
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
        [owner, user] = await ethers.getSigners();
        this.processor = await deployCrossChainMessageProcessor(owner.address);
        this.bridge = deployCrossChainNFTBridge(this.processor.address, owner.address);
    });

    it("应正确处理NFT锁定", async function () {
        // create factory
        const MockERC721Factory = await ethers.getContractFactory("MockERC721")
        console.log("contract deploying")
        // deploy contract from factory
        // const myERC20 = await MyERC20Factory.deploy(10)
        const ERC721 =await  MockERC721Factory.connect(owner).deploy("MockERC721", "MCK", owner.address)
        await ERC721.waitForDeployment()
        console.log(`contract has been deployed successfully, contract address is ${ERC721.target}`);
        await ERC721.safeMint(user.address, 1);
        const address = await ERC721.getAddress();
        await expect(this.bridge.connect(user).lockNFT(address, 1, 2)) // 目标链ID=2
            .to.emit(this.bridge, "NFTLocked");
    });

    it("应验证跨链消息签名", async function () {
        const fakeMessage = ethers.decodeBytes32String("invalid");
        await expect(
            this.bridge.processCrossChainMessage(fakeMessage, 123, "0x")
        ).to.be.revertedWith("Invalid message");
    });
});
