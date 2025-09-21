import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import {deployContract} from "@nomicfoundation/hardhat-ethers/types";
import {CrossChainMessageProcessor,CrossChainNFTAuction,CrossChainNFTBridge} from "../typechain-types";
describe("CrossChainNFTAuction", function () {
    let owner : any;
    let buyer: any;let bidder: any;
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
    // 辅助函数：部署 CrossChainNFTAuction 合约
    async function deployCrossChainNFTAuction(
        messageProcessorAddr: string,
        bridgeAddr: string,
        initialOwner: string
    ): Promise<CrossChainNFTAuction> {
        const CrossChainNFTAuctionFactory = await ethers.getContractFactory(
            "CrossChainNFTAuction"
        );
        const contract = await CrossChainNFTAuctionFactory.deploy(
            messageProcessorAddr,
            bridgeAddr,
            initialOwner
        );
        await contract.waitForDeployment();
        return contract as CrossChainNFTAuction;
    }
    before(async function () {
        [owner, buyer, bidder] = await ethers.getSigners();

        this.processor = await deployCrossChainMessageProcessor(owner.address);
        this.auction = await deployCrossChainNFTAuction(
            this.processor.address,
            ethers.ZeroAddress,
            owner.address
        );
    });

    it("应正确创建拍卖", async function () {
        const MockERC721Factory = await ethers.getContractFactory("MockERC721")
        console.log("contract deploying")
        // deploy contract from factory
        // const myERC20 = await MyERC20Factory.deploy(10)
        const ERC721 =await  MockERC721Factory.connect(owner).deploy("MockERC721", "MCK", owner.address)
        await ERC721.waitForDeployment()
        console.log(`contract has been deployed successfully, contract address is ${ERC721.target}`);
        await ERC721.safeMint(buyer.address, 1);
        const address = await ERC721.getAddress();

        await expect(this.auction.connect(buyer).createAuction(address, 1, 100))
            .to.emit(this.auction, "AuctionCreated");
    });

    it("应阻止无效出价", async function () {
        await expect(this.auction.connect(bidder).placeBid(0, { value: 50 }))
            .to.be.revertedWith("Bid too low");
    });
});
