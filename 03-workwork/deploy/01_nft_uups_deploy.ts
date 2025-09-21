import { ethers } from "hardhat";
import { upgrades } from "hardhat";
import { verify } from "../utils/verify";
import { saveProxyAddress } from "../utils/proxyAddress";
//NFT 的本质是 “链上凭证 + 链下元数据” 的结合——tokenURI 就是指向链下「元数据 JSON 文件」的链接，所以它的源头正是这个 JSON 文件的存储地址
//NFT 本身（如你代码中的 NFT 合约）在链上只存储 核心凭证信息（比如 tokenId、所有者地址），但 NFT 的 “详情”（名称、图片、描述、属性等）会存放在一个 JSON 格式的元数据文件 中。


const tokenURI = "https://blush-perfect-jaguar-352.mypinata.cloud/ipfs/bafkreidmlalqb4edwiinfb6s4uvzpe7lpo2evpwvqdngkye2lj54tpwvfm";

async function main() {
  // 获取部署账户
  const [deployer, addr1] = await ethers.getSigners();
  console.log("使用账户地址进行部署:", deployer.address);
  console.log("addr1.address:===="+addr1.address);
  // CCIP Router 地址 - Sepolia 测试网
  // 这是 Chainlink CCIP 在 Sepolia 测试网上的路由器地址
  // 用于处理跨链消息传递  Sepolia 测试网的 CCIP 路由器地址，仅适用于在 Sepolia 网络部署合约。
  const CCIP_ROUTER = "0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59";
  
  // 源链 ID - 这里使用 Solana 的链 ID 作为示例
  // 这个 ID 用于验证跨链消息的来源
  const SOURCE_CHAIN_ID = 101;

  // 部署 NFT 合约（使用 UUPS 代理模式）
  console.log("开始部署 NFT 合约...");
  const NFT = await ethers.getContractFactory("NFT");
  
  // 使用 UUPS 代理模式部署合约 合约未来可以升级（修改逻辑）而不改变地址。
  // initializer: "initialize" - 指定初始化函数名
  // kind: "uups" - 使用 UUPS 代理模式
//   upgrades.deployProxy 方法
//   同时部署 代理合约（用户实际交互的地址）和 实现合约（存储业务逻辑）
//   自动将代理合约指向实现合约，并调用初始化函数
//   确保合约符合可升级标准（避免存储冲突等问题）
//   第一个参数：NFT
//   是通过 ethers.getContractFactory("NFT") 获取的合约工厂对象
//   代表你要部署的「NFT 实现合约」（包含实际业务逻辑的合约）
//   第二个参数：[CCIP_ROUTER, SOURCE_CHAIN_ID]
//   这是传给合约 初始化函数（initializer） 的参数列表
//   对应你 NFT 合约中 initialize 函数的参数，例如你的合约可能这样定义初始化函数：
  const nft = await upgrades.deployProxy(NFT, [CCIP_ROUTER, SOURCE_CHAIN_ID], {
    initializer: "initialize",
    kind: "uups",
  });
//   执行这段代码后，会生成两个合约地址：
// 代理合约地址：用户实际交互的地址（不变），通过 nft.getAddress() 获取
//   实现合约地址：存储业务逻辑的地址（可通过升级替换），通过 upgrades.erc1967.getImplementationAddress() 获取
  // 等待部署完成
  await nft.waitForDeployment();

  // 获取部署后的合约地址
  // 这是代理合约的地址，用户将使用这个地址与合约交互
  const nftAddress = await nft.getAddress();
  console.log("NFT 合约已部署到:", nftAddress);

  // 保存代理合约地址到文件
  saveProxyAddress(nftAddress);

  // 获取实现合约地址
  // 这是实际包含合约逻辑的地址
  const implementationAddress = await upgrades.erc1967.getImplementationAddress(nftAddress);
  console.log("实现合约地址:", implementationAddress);

  console.log("等待区块确认...");
  // 获取部署交易并等待 6 个区块确认
  // 这是为了确保交易被充分确认，避免验证失败
  const deploymentTx = await nft.deploymentTransaction();
  if (deploymentTx) {
    await deploymentTx.wait(6);
  }

  // 铸造一个NFT
  const nftContract = await ethers.getContractAt("NFT", nftAddress);
  console.log("开始铸造 NFT...");
  //sendNFT 是写入链上的交易，必须等待交易确认后，链上才会生成 tokenId=1 的 NFT 数据。
  // 你当前代码中没有等待 tx 确认，直接调用 ownerOf(1) 时，链上可能还未记录该 NFT，导致 ownerOf 返回异常，间接引发后续 address 读取错误。
  //nftContract.connect(deployer).sendNFT(addr1.address, tokenURI) 这是代理合约关联你的钱包账户调用NFT 合约的
  // sendNFT 函数，向指定地址铸造并发送一个 NFT
  console.log("addr1.address:===="+addr1.address);
  const tx = await nftContract.connect(deployer).sendNFT(addr1.address, tokenURI);
  console.log("等待铸造交易确认...，交易哈希:", tx.hash);
  await tx.wait(1); // 等待1个区块确认（测试网足够，主网可设3-6）
  // 3. 正确获取 tokenId（根据你的合约逻辑调整）
// 情况A：如果 sendNFT 铸造后 tokenId 自增（如从1开始），且有 getNextTokenId() 方法
  const nextTokenId = await nftContract.getNextTokenId();
  const currentTokenId = nextTokenId - 1n; // 因为 nextTokenId 是“下一个要铸造的ID”，当前已铸造的是它减1
  console.log("已铸造 NFT 的 Token ID:", currentTokenId.toString());

// 情况B：如果想验证所有者地址（用 ownerOf + 正确的 tokenId）
  const ownerAddress = await nftContract.ownerOf(currentTokenId);
  console.log("Token ID", currentTokenId.toString(), "的所有者地址:", ownerAddress);

// 4. 再次打印下一个 Token ID（验证自增逻辑）
  console.log("下一个待铸造的 Token ID:", nextTokenId.toString());
  // // 获取当前 tokenId
  // const tokenId = await nftContract.ownerOf(1);
  // console.log("NFT Token ID:", tokenId.toString());
  //
  // console.log("获取下一个 Token ID...");
  // const nextTokenId = await nftContract.getNextTokenId();
  // console.log("下一个 Token ID:", nextTokenId.toString());

}

// 执行部署脚本
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("部署过程中发生错误:", error);
    process.exit(1);
  });
