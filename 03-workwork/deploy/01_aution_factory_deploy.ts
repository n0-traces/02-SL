import { ethers } from "hardhat";
import { verify } from "../utils/verify";
import { saveProxyAddress } from "../utils/proxyAddress";

async function main() {
  // 获取部署账户
  const [deployer] = await ethers.getSigners();
  console.log("使用账户地址进行部署:", deployer.address);

  // LINK 代币地址 - Sepolia 测试网
  const LINK_ADDRESS = "0x779877A7B0D9E8603169DdbD7836e478b4624789";

  // 部署拍卖工厂合约
  console.log("开始部署拍卖工厂合约...");
  const AutionFactory = await ethers.getContractFactory("AutionFactory");
  const factory = await AutionFactory.deploy(false, LINK_ADDRESS);
  await factory.waitForDeployment();

  // 获取部署后的合约地址
  const factoryAddress = await factory.getAddress();
  console.log("拍卖工厂合约已部署到:", factoryAddress);

  console.log("等待区块确认...");
  // 获取部署交易并等待 6 个区块确认
  const deploymentTx = await factory.deploymentTransaction();
  if (deploymentTx) {
    await deploymentTx.wait(6);
  }
}

// 执行部署脚本
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("部署过程中发生错误:", error);
    process.exit(1);
  }); 