import { expect } from "chai";

import { ethers, upgrades } from "hardhat";

const tokenURI = "https://blush-perfect-jaguar-352.mypinata.cloud/ipfs/bafkreidmlalqb4edwiinfb6s4uvzpe7lpo2evpwvqdngkye2lj54tpwvfm";
const tokenId = 1;

describe('Market', () => {
    console.log("开始测试")

    let nftContract: any;
    let account: any;
    let addr1: any;
    let addr2: any;
    //before each 是每个测试用例执行前的 “前置准备步骤”（比如部署合约、铸造 NFT、授权等）
    beforeEach(async () => {
        console.log("开始部署合约")
        const accounts = await ethers.getSigners();
        account = accounts[0];
        addr1 = accounts[1];
        addr2 = accounts[2];
        console.log("addr2====", addr2.address);
        console.log("addr1====", addr1.address);
        // 使用 UUPS 代理模式部署合约
        const Factory = await ethers.getContractFactory('NFT');
        nftContract = await upgrades.deployProxy(Factory, 
            ["0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59", 101],
            { initializer: 'initialize' }
        );
        await nftContract.waitForDeployment();
        console.log("部署合约成功", nftContract.target);
    });

    it("deploy success", async () => {
        expect(nftContract).to.be.ok;
    })

    describe("sendNFT", () => {
        it("发送NFT成功", async () => {
            const tx = await nftContract.connect(account).sendNFT(addr1.address, tokenURI);
            const receipt = await tx.wait(); // 显式等待交易上链，确保收据非空
            // 2. 断言事件（从收据中提取事件，替代 to.emit）
            const sendNFTEvent = receipt.logs.find((log: any) =>
                log.fragment?.name === "SendNFT"
            );
            console.log("找到的 SendNFT 事件:", sendNFTEvent); // 若打印 undefined，说明事件未触发
            expect(sendNFTEvent).to.not.be.undefined; // 断言事件存在
            expect(sendNFTEvent.args.recipient).to.equal(addr1.address); // 断言参数
            expect(sendNFTEvent.args.tokenURI).to.equal(tokenURI);
            expect(sendNFTEvent.args.tokenId).to.equal(tokenId);
            expect(await nftContract.ownerOf(tokenId)).to.equal(addr1.address);
            // 断言tokenId为1的NFT的URI为tokenURI  
            expect(await nftContract.tokenURI(tokenId)).to.equal(tokenURI);
        })

        it("只有合约拥有者可以发送NFT", async () => {
            await expect(nftContract.connect(addr1).sendNFT(addr2.address, tokenURI))
                .to.be.revertedWith("Only owner can call this function");
        });
    })

    describe("transferNFT", () => {
        beforeEach(async () => {
            const mintTx = await nftContract.connect(account).sendNFT(addr1.address, tokenURI);
            const mintReceipt = await mintTx.wait();
            const mintEvent = mintReceipt.logs.find((log: any) => log.fragment?.name === "SendNFT");
            const actualTokenId = mintEvent.args.tokenId; // 动态获取，而非硬编码 1
            console.log("实际铸造的 tokenId:", actualTokenId.toString());

            // 2. 验证该 tokenId 确实属于 addr1（确保铸造成功）
            const owner = await nftContract.ownerOf(actualTokenId);
            console.log("NFT 当前所有者:", owner);
            console.log("预期所有者（addr1）:", addr1.address);
            expect(await nftContract.ownerOf(actualTokenId)).to.equal(addr1.address,
                "sendNFT 未正确将 NFT 转移给 addr1，导致 transfer 失败");
        })

        it("转移NFT成功", async () => { try{
            console.log("转移目标地址（预期）:", addr2.address);
            console.log("转移目标地址（实际传入）:", addr2.address); // 确保传入的是 addr2
            //测试网络比较慢，增加等待时间，最好上链确认后再测试
            const tx = await nftContract.connect(addr1).transferNFT(addr2.address, tokenId)
            const receipt = await tx.wait();

            // 查找 ERC721 标准的 Transfer 事件（所有 NFT 转移都会触发）
            const transferEvent = receipt.logs.find((log: any) =>
                log.fragment?.name === "Transfer"
            );
            expect(transferEvent).to.not.be.undefined;

            // 验证 Transfer 事件的参数（from, to, tokenId）
            expect(transferEvent.args.from).to.equal(addr1.address); // 原所有者
            expect(transferEvent.args.to).to.equal(addr2.address);   // 新所有者（关键！）
            expect(transferEvent.args.tokenId).to.equal(tokenId);

            // 再次断言 ownerOf 结果
            expect(await nftContract.ownerOf(tokenId)).to.equal(addr2.address);
            // 打印转移后的实际所有者
            const newOwner = await nftContract.ownerOf(tokenId);
            console.log("转移后实际所有者:", newOwner);
            console.log("预期所有者:", addr2.address);

            expect(newOwner).to.equal(addr2.address);
        }catch (error: any) {
            // 打印完整错误信息（包含回滚原因）
            console.error("transferNFT 回滚详情:", error.message);
            throw error; // 继续抛出错误，不影响测试结果显示
        }
            expect(await nftContract.ownerOf(tokenId)).to.equal(addr2.address);
        })
    })
})