import { expect } from "chai";
import {
    ethers,
    network,
    upgrades
} from "hardhat";
import { waitUntilAfterEndTime } from "../utils/DelayTime";


describe("Aution System", function () {
    let owner: any
    let seller: any
    let bidder1: any
    let bidder2: any

    let nftContract: any
    let factoryContract: any
    let auctionContract: any
    let linkToken : any

    const tokenURI = "https://blush-perfect-jaguar-352.mypinata.cloud/ipfs/bafkreidmlalqb4edwiinfb6s4uvzpe7lpo2evpwvqdngkye2lj54tpwvfm";
    const tokenId = 1;
    const startingPrice = ethers.parseEther("0.000001");
    let LINK_ADDRESS = "0x779877A7B0D9E8603169DdbD7836e478b4624789";
    //before each 是每个测试用例执行前的 “前置准备步骤”（比如部署合约、铸造 NFT、授权等）
    this.beforeEach(async () => {
        console.log("=== 外层 before each 开始 ===");
        [owner, seller, bidder1, bidder2] = await ethers.getSigners()

        // 部署NFT合约
        const Factory = await ethers.getContractFactory('NFT');
        console.log("2. 加载 NFT 合约工厂完成");
        //0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59 官方路由地址
        nftContract = await upgrades.deployProxy(Factory, 
            ["0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59", 101],
            { initializer: 'initialize' }
        );
        await nftContract.waitForDeployment();
        console.log("3. NFT 合约部署完成（地址：", nftContract.target, "）");
        console.log("NFT合约地址", nftContract.target)

        // 铸币
        await nftContract.connect(owner).sendNFT(seller.address, tokenURI)
        console.log("seller.address:===="+seller.address);
        // 部署模拟的LINK代币
        // const LinkToken = await ethers.getContractFactory("ERC20Mock") // 假设有一个ERC20Mock合约
        // linkToken = await LinkToken.deploy("ChainLink Token", "LINK")
        // await linkToken.waitForDeployment()
        // LINK_ADDRESS = linkToken.target;
        const isLocalNetwork = network.name === "hardhat" || network.name === "localhost";
        console.log("isLocalNetwork", isLocalNetwork);
        if (isLocalNetwork) {
            // 本地测试：部署 ERC20Mock 作为 LINK
            console.log("isLocalNetwork start====");
            const LinkTokenFactory = await ethers.getContractFactory("ERC20Mock");
            linkToken = await LinkTokenFactory.deploy("LINK", "LINK");
            await linkToken.waitForDeployment();
            // 给测试账户铸造一些LINK代币
            await linkToken.mint(bidder1.address, ethers.parseEther("100"))
            await linkToken.mint(bidder2.address, ethers.parseEther("100"))
            console.log("isLocalNetwork end====");
        } else {
            // 测试网（Sepolia）：使用真实 LINK 合约地址
            const LINK_ADDRESS = "0x779877A7B0D9E8603169DdbD7836e478b4624789";
            linkToken = await ethers.getContractAt("ERC20Mock", LINK_ADDRESS);
            // 确保 bidder1 有足够 LINK（提前通过水龙头领取）
        }

        // 验证 linkToken 是否初始化成功（关键日志）
        console.log("LINK 合约实例是否存在:", linkToken ? "是" : "否");
        if (linkToken) {
            console.log("LINK 合约地址:", await linkToken.getAddress());
        }
        // const linkToken = await ethers.getContractAt("IERC20", LINK_ADDRESS);


        const bidder1Balance = await linkToken.balanceOf(bidder1.address);
        const bidder2Balance = await linkToken.balanceOf(bidder2.address);
        // 部署工厂合约
        const factoryFactory = await ethers.getContractFactory("AutionFactory")
        factoryContract = await factoryFactory.deploy(true, LINK_ADDRESS)
        await factoryContract.waitForDeployment()
        console.log("=== 外层 before each end ===");

        
    })

    describe("Aution Action", () => {
        this.beforeEach(async () => {
            // 添加这一行：授权工厂合约操作NFT
            await nftContract.connect(seller).approve(factoryContract.target, tokenId)
            // 开始拍卖
            console.log("NFT 所有者:", await nftContract.ownerOf(tokenId)); // 应等于 seller.address
            console.log("工厂合约是否被授权:", await nftContract.getApproved(tokenId)); // 应等于 factoryContract.target
            console.log("起拍价:", startingPrice.toString()); // 应大于 0
            console.log("拍卖时长:", 20); // 应大于 0
            const owner = await nftContract.ownerOf(tokenId);
            if (owner!== seller.address) {
                throw new Error(`NFT 所有者不是 seller，当前所有者: ${owner}`);
            }
            console.log("tokenId", tokenId, "的所有者:", owner);

            // 验证授权是否成功   // 添加这一行：授权工厂合约操作NFT
            // 发送授权交易
            console.log("发送 approve 交易...");
            const approveTx = await nftContract.connect(seller).approve(
                factoryContract.target,
                tokenId,
                { gasLimit: 300000 }
            );
            console.log("approve 交易哈希：", approveTx.hash); // 若未打印，说明交易未发送
            // const approveTx = await nftContract.connect(seller).approve(factoryContract.target, tokenId);
            // console.log("approveTx ========");
            await approveTx.wait(); // 关键：等待授权交易上链确认
            console.log("approveTx success=====");
            const approvedAddress = await nftContract.getApproved(tokenId);
            if (approvedAddress !== factoryContract.target) {
                throw new Error(`授权失败，当前授权地址: ${approvedAddress}，预期: ${factoryContract.target}`);
            }
            // 部署拍卖合约 拍卖时长  20 秒 若出现问题，可以适当增加时长
            const tx = await factoryContract.connect(seller).createAution(nftContract.target, tokenId, startingPrice, 40)

            const receipt = await tx.wait();
            const event = receipt.logs.find((log: any) =>
                log.fragment && log.fragment.name === 'AutionCreated'
            );
            const auctionAddress = event.args[0];
            // const args1 = event.args[1];
            // console.log("args1=====", args1)
            console.log("event.args.length=====", event.args.length)
            console.log("拍卖地址", auctionAddress)
            const aution = await ethers.getContractFactory("Aution")

            auctionContract = aution.attach(auctionAddress)
            console.log("beforeEach end====")
        })

        it("应该正确创建拍卖", async () => {
            expect(await auctionContract.seller()).to.equal(seller.address);
            expect(await auctionContract.nftContract()).to.equal(nftContract.target);
            expect(await auctionContract.nftTokenId()).to.equal(tokenId);
            expect(await nftContract.ownerOf(tokenId)).to.equal(auctionContract.target)
        })

        it("应该正确记录拍卖数量", async () => {
            expect(await factoryContract.getAutionCount()).to.equal(1);
        })

        it("应该正确记录拍卖ID", async () => {
            const autionId = 1;
            const autionAddress = await factoryContract.getAutionContract(autionId);
            expect(autionAddress).to.equal(auctionContract.target);
        })
        //耗时过长
        it("应该接受更高的ETH出价", async () => {
            const bidAmount = ethers.parseEther("0.000002")
            const bidTx = await auctionContract.connect(bidder1).placeBidWithETH({ value: bidAmount })
            await bidTx.wait(); // 等待交易确认，获取包含事件的收据
            console.log("bidder1 出价:========"+auctionContract.highestBidder())
            expect(await auctionContract.highestBidder()).to.equal(bidder1.address)
            expect(await auctionContract.tokenAddress()).to.equal(ethers.ZeroAddress)
        })

        it("应该拒绝低于起拍价的出价", async () => {
            const bidAmount = ethers.parseEther("0.0000005")
            await expect(
                auctionContract.connect(bidder1).placeBidWithETH({ value: bidAmount })
            ).to.be.revertedWith("Bid not high enough")
        })

        it("应该拒绝低于当前最高价的出价", async () => {
            const firstBid = ethers.parseEther("0.000002")
            const secondBid = ethers.parseEther("0.000003")//设置比firstBid高

            const bidTx = await auctionContract.connect(bidder1).placeBidWithETH({ value: firstBid })
            await bidTx.wait();
            console.log("bidder1 出价:========"+auctionContract.highestBidder())
            const bidTx2 = auctionContract.connect(bidder2).placeBidWithETH({ value: secondBid });
            await bidTx2.wait();
            console.log("bidder2 出价:========"+auctionContract.highestBidder())
            //
            expect (bidTx2.to.be.revertedWith("Bid not high enough"))
            // bidTx2.to.be.revertedWith("Bid not high enough")
            // await expect(
            //     auctionContract.connect(bidder2).placeBidWithETH({ value: secondBid })
            // ).to.be.revertedWith("Bid not high enough")
        })

        it("应该正确退还之前的出价", async () => {
            const firstBid = ethers.parseEther("0.000002")
            const secondBid = ethers.parseEther("0.000003")

            const initialBalance = await ethers.provider.getBalance(bidder1.address)
            await auctionContract.connect(bidder1).placeBidWithETH({ value: firstBid })
            await auctionContract.connect(bidder2).placeBidWithETH({ value: secondBid })
            const finalBalance = await ethers.provider.getBalance(bidder1.address)

            // 考虑gas费用，余额应该接近初始余额
            expect(finalBalance).to.be.closeTo(initialBalance, ethers.parseEther("0.1"))
        })

        it("应该接受LINK代币出价", async () => {
            const bidAmount = ethers.parseEther("1"); // 出价1LINK
            // 关键：出价前授权，且授权额度 ≥ 出价金额
            const approveTx = await linkToken.connect(bidder1).approve(
                auctionContract.target, // 授权对象：拍卖合约
                bidAmount // 授权额度：至少等于出价金额
            );
            await approveTx.wait(); // 等待授权交易确认（必须！）
            // 验证授权额度（可选，提前规避错误）
            console.log("=== 开始approveTx 事件 ===");
            const allowance = await linkToken.allowance(bidder1.address, auctionContract.target);
            expect(allowance).to.be.gte(bidAmount, "授权额度不足");
            console.log("=== allowance ===");
            const startTime = await auctionContract.startTime();
            const endTime = await auctionContract.endTime();


            console.log("开始时间:", new Date(Number(startTime) * 1000).toLocaleString());
            console.log("结束时间:", new Date(Number(endTime) * 1000).toLocaleString());
            // 关键步骤：2. 手动将区块链时间设置到范围内（例如设置为 startTime + 10 秒，确保在中间）
            const targetTimestamp = Number(startTime) + 10; // 在开始时间后10秒，避免边界问题
            // await ethers.provider.send("evm_setNextBlockTimestamp", [targetTimestamp]); // 设置下一个区块的时间
            // await ethers.provider.send("evm_mine", []); // 挖矿，使时间生效

            // 关键步骤：3. 验证区块链时间是否已设置成功
            // const currentBlockTime = await ethers.provider.getBlock("latest");
            const block = await ethers.provider.getBlock("latest");
            const currentBlockTime = block?.timestamp;
            if (currentBlockTime === undefined) {
                throw new Error("获取区块信息失败，返回为null");
            }
            console.log("设置后的区块链时间:", new Date(currentBlockTime * 1000).toLocaleString());
            console.log("是否在范围内:", currentBlockTime >= Number(startTime) && currentBlockTime <= Number(endTime)); //
            const bidTx = await auctionContract.connect(bidder1).placeBidWithERC20(LINK_ADDRESS, bidAmount);
            const bidReceipt = await bidTx.wait(); // 等待交易确认，获取包含事件的收据
            // 3. 遍历收据中的所有日志，筛选并打印 DebugLog 事件
            console.log("=== 开始打印 DebugLog 事件 ===");
            for (const log of bidReceipt.logs) {
                // 检查日志是否属于当前拍卖合约（避免混入其他合约的事件）
                if (log.address.toLowerCase() === auctionContract.target.toLowerCase()) {
                    // 检查事件名称（通过 log.fragment.name 识别）
                    if (log.fragment?.name === "DebugLog" || log.fragment?.name === "DebugLogAddr" || log.fragment?.name === "DebugLogValue") {
                        console.log(`事件名称: ${log.fragment.name}`);
                        console.log(`事件参数:`, log.args); // 打印完整参数
                        console.log("------------------------");
                    }
                }
            }
            expect(await auctionContract.highestBidder()).to.equal(bidder1.address)
            expect(await auctionContract.tokenAddress()).to.equal(LINK_ADDRESS)
        })
        //// 错误：用transferFrom（需授权）
        // // IERC20(_linkAddress).transferFrom(address(this), previousBidder, bidAmount);
        //
        // // 正确：用transfer（无需授权，只要合约有余额）
        // IERC20(_linkAddress).transfer(previousBidder, bidAmount);
        it("应该正确退还之前的LINK出价", async () => {
            const firstBid = ethers.parseEther("1")
            const secondBid = ethers.parseEther("2")

            const approve = await linkToken.connect(bidder1).approve(auctionContract.target, firstBid)
            await approve.wait()
            const approve2=await linkToken.connect(bidder2).approve(auctionContract.target, secondBid)
            await approve2.wait()
            const startTime = await auctionContract.startTime();
            const endTime = await auctionContract.endTime();
            console.log("开始时间:", new Date(Number(startTime) * 1000).toLocaleString());
            console.log("结束时间:", new Date(Number(endTime) * 1000).toLocaleString());
            // 3. 关键：手动设置区块链时间到范围内（例如：开始时间 + 10秒，避免边界问题） 仅适用本地网络调试
            // const targetTime = Number(startTime) + 10; // 确保在 [startTime, endTime] 内
            // await ethers.provider.send("evm_setNextBlockTimestamp", [targetTime]); // 设置下一个区块的时间
            // await ethers.provider.send("evm_mine", []); // 挖矿生效时间
            // 关键步骤：3. 验证区块链时间是否已设置成功
            // const currentBlockTime = await ethers.provider.getBlock("latest");
            const block = await ethers.provider.getBlock("latest");
            const currentBlockTime = block?.timestamp;
            if (currentBlockTime === undefined) {
                throw new Error("获取区块信息失败，返回为null");
            }
            console.log("设置后的区块链时间:", new Date(currentBlockTime * 1000).toLocaleString());
            console.log("是否在范围内:", currentBlockTime >= Number(startTime) && currentBlockTime <= Number(endTime));
            const initialBalance = await linkToken.balanceOf(bidder1.address)
            const approveTx = await auctionContract.connect(bidder1).placeBidWithERC20(LINK_ADDRESS, firstBid)
            await approveTx.wait();
            const approveTx2 =await auctionContract.connect(bidder2).placeBidWithERC20(LINK_ADDRESS, secondBid)
            await approveTx2.wait();
            const finalBalance = await linkToken.balanceOf(bidder1.address)
            
            expect(finalBalance).to.equal(initialBalance)
        })

        it("卖家应该能够取消拍卖", async () => {
            try {
                // 1. 发送取消拍卖的交易（必须用 await 发送，否则函数不执行）
                console.log("开始调用 cancelAution...");
                const cancelTx = await auctionContract.connect(seller).cancelAution();
                // 2. 等待交易上链确认（此时合约函数才会被执行）
                console.log("等待 cancelAution 交易上链...");
                await cancelTx.wait();
                console.log("cancelAution 交易已确认，哈希：", cancelTx.hash);
                // 3. 通过合约实例验证状态（正确方式）
                // 验证 isEnd 已设为 true
                const isEnd = await auctionContract.isEnd();
                expect(isEnd).to.be.true;

                // 验证 NFT 已归还给卖家
                const nftOwner = await nftContract.ownerOf(tokenId);
                expect(nftOwner).to.equal(seller.address);

                // 验证工厂合约中拍卖计数已更新
                const auctionCount = await factoryContract.getAutionCount();
                expect(auctionCount).to.equal(0);
            } catch (error: any) {
                console.error("cancelAution 调用失败（被 revert）：", error.message);
                throw error; // 若 revert 会在这里捕获
            }


        });

        it("非卖家不能取消拍卖", async () => {
            await expect(
                auctionContract.connect(bidder1).cancelAution()
            ).to.be.revertedWith("Only seller can call this function")
        })
        //可以将时间设置短点，保证block.timestamp>endTime  设置10s
        it("应该正确结束拍卖并转移NFT和ETH", async () => {
            console.log("应该正确结束拍卖并转移NFT和ETH start====")
            const bidAmount = ethers.parseEther("0.0005")
            const bidTx = await auctionContract.connect(bidder1).placeBidWithETH({ value: bidAmount })

            const initialBalance = await ethers.provider.getBalance(seller.address)
            console.log("initialBalance====",initialBalance.toString())
            await bidTx.wait()
            console.log("出价完成，最高出价者:", await auctionContract.highestBidder());
            console.log("endAution start====")
            // 2. 从合约获取拍卖结束时间（endTime 是 BigInt 类型）
            const contractEndTime = await auctionContract.endTime();
            const provider = ethers.provider;
            await waitUntilAfterEndTime(provider, contractEndTime);
            let endTx;
            // 3. 捕获 endAution 调用的错误（关键！）  这样可以知道是哪个修改器测试出错
            try {
                endTx= await auctionContract.connect(seller).endAution()
                console.log("endAution 调用成功（未被 revert）");
            } catch (error: any) {
                console.error("endAution 调用失败（被 revert）：", error.message);
                throw error; // 抛出错误，让测试中断，方便查看原因
            }
            await endTx.wait()
            console.log("endAution end====")
            // await endTx.wait()
            const finalBalance = await ethers.provider.getBalance(seller.address)
            console.log("finalBalance====",finalBalance.toString())
            // const isEnd = auctionContract.isEnd();
            // isEnd.wait();
            expect(await auctionContract.isEnd()).to.be.true
            expect(await nftContract.ownerOf(tokenId)).to.equal(bidder1.address)
            expect(await factoryContract.getAutionCount()).to.equal(0)
            // 考虑gas费用，余额应该增加接近bidAmount
            expect(finalBalance).to.be.closeTo(initialBalance + bidAmount, ethers.parseEther("0.1"))
        })

        it("应该正确结束拍卖并转移NFT和LINK", async () => {
            const linkAmount = ethers.parseEther("1")
            const approve =  await linkToken.connect(bidder1).approve(auctionContract.target, linkAmount)
            await approve.wait()
            //要等授权成功才能出价 拍卖时长可以长一点
            const bidTx= await auctionContract.connect(bidder1).placeBidWithERC20(LINK_ADDRESS, linkAmount)
            await bidTx.wait()
            const initialBalance = await linkToken.balanceOf(seller.address)
            // 2. 从合约获取拍卖结束时间（endTime 是 BigInt 类型）
            const contractEndTime = await auctionContract.endTime();
            const provider = ethers.provider;
            await waitUntilAfterEndTime(provider, contractEndTime);
            const bidTx2= await auctionContract.connect(seller).endAution()
            await bidTx2.wait()
            console.log("endAution end====")
            const finalBalance = await linkToken.balanceOf(seller.address)
            
            expect(await auctionContract.isEnd()).to.be.true
            expect(await nftContract.ownerOf(tokenId)).to.equal(bidder1.address)
            expect(await factoryContract.getAutionCount()).to.equal(0)
            expect(finalBalance).to.equal(initialBalance + linkAmount)
        })
        //时间设置很短测试  拍卖时长1s
        it("拍卖结束后不能继续出价", async () => {
            // 2. 从合约获取拍卖结束时间（endTime 是 BigInt 类型）
            const contractEndTime = await auctionContract.endTime();
            // 3. 调用封装函数：等待链上时间超过 endTime（核心步骤）
            // 传入 Provider、合约 endTime，使用默认 10秒额外等待
            const provider = ethers.provider;
            await waitUntilAfterEndTime(provider, contractEndTime);
            const tx=await auctionContract.connect(seller).endAution()
            const bidAmount = ethers.parseEther("0.000002")
            await tx.wait()
            expect(await auctionContract.isEnd()).to.be.true
            const blockBefore = await provider.getBlock("latest");
            if (!blockBefore || blockBefore.timestamp === undefined) {
                throw new Error("等待前：获取区块信息失败，无法获取当前链上时间");
            }
            const startTime =await auctionContract.startTime();
            const endTime = await auctionContract.endTime();
            const currentBlockTime = blockBefore.timestamp;
            console.log("设置后的区块链时间:", new Date(currentBlockTime * 1000).toLocaleString());
            console.log("是否在范围内:", currentBlockTime >= Number(startTime) && currentBlockTime <= Number(endTime)); // false
            await expect(
                auctionContract.connect(bidder1).placeBidWithETH({ value: bidAmount })
            ).to.be.revertedWith("Aution has end")
        })
    })
})
/**
 * 延迟等待函数（测试网专用，等待真实时间流逝）
 * @param ms 等待时间（毫秒）
 * @returns Promise<void>
 */
function delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
}

