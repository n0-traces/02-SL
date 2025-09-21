import "@nomicfoundation/hardhat-ethers";
import "@openzeppelin/hardhat-upgrades";
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";
import "dotenv/config";
// import {config} from "@chainlink/env-enc";
require("@chainlink/env-enc").config()
const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  solidity: {
    version: "0.8.28", // 确保与合约 pragma 版本一致
    settings: {
      optimizer: { enabled: true, runs: 200 }, // 启用优化，加快部署
    },
  },
  networks: {
    hardhat: {
      blockGasLimit: 30000000, // 足够大的 Gas 限制，避免部署因 Gas 不足失败
      gasPrice: 8000000000, // 合理 Gas 价格，避免 pending
    },
     sepolia: {
       url: process.env.SEPOLIA_RPC_URL || "",
       accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
     }
  },
  // typechain: {
  //   outDir: "typechain-types",
  //   target: "ethers-v5",
  // },
  mocha: {
    timeout: 240000, // 超时时间设为 2 分钟（120000 毫秒）
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  }
};

export default config;
