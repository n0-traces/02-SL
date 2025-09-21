import { ethers, upgrades } from "hardhat";
import { verify } from "../utils/verify";
import { getProxyAddress, saveProxyAddress } from "../utils/proxyAddress";

async function main() {
  // 获取部署账户
  const [deployer] = await ethers.getSigners();
  console.log("使用账户地址进行升级:", deployer.address);

  // 从文件读取代理合约地址
  const PROXY_ADDRESS = getProxyAddress();
  console.log("读取到的代理合约地址:", PROXY_ADDRESS);

  // 部署新的 NFTV2 合约
  console.log("开始部署 NFTV2 合约...");
  const NFTV2 = await ethers.getContractFactory("NFTV2");
  
  // 执行升级
  // 注意：upgradeProxy 会自动：
  // 1. 部署新的实现合约
  // 2. 更新代理合约指向新的实现
  // 3. 保持所有存储数据不变
  console.log("正在升级到 NFTV2...");
  const nftV2 = await upgrades.upgradeProxy(PROXY_ADDRESS, NFTV2);
  await nftV2.waitForDeployment();

  // 获取升级后的合约地址
  const nftV2Address = await nftV2.getAddress();
  console.log("NFTV2 合约已部署到:", nftV2Address);

  // 保存新的代理合约地址（虽然地址相同，但为了保持一致性）
  saveProxyAddress(nftV2Address);

  // 获取新的实现合约地址
  const implementationAddress = await upgrades.erc1967.getImplementationAddress(nftV2Address);
  console.log("新的实现合约地址:", implementationAddress);

  // 验证新的实现合约
  if (process.env.ETHERSCAN_API_KEY) {
    console.log("等待区块确认...");
    // 等待 6 个区块确认以确保交易被确认
    const deploymentTx = await nftV2.deploymentTransaction();
    if (deploymentTx) {
      await deploymentTx.wait(6);
    }
    
    console.log("正在验证新的实现合约...");
    await verify(implementationAddress, []);
  }

  // 测试新功能
  console.log("测试新功能 getNextTokenId...");
  const nftV2Contract = await ethers.getContractAt("NFTV2", nftV2Address);
  const nextTokenId = await nftV2Contract.getNextTokenId();
  console.log("下一个 Token ID:", nextTokenId.toString());
}

// 执行升级脚本
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("升级过程中发生错误:", error);
    process.exit(1);
  });
