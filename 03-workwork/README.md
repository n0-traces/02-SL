# NFT 拍卖市场

这是一个基于以太坊的 NFT 拍卖市场项目，支持 NFT 的铸造、拍卖和跨链功能。



## 功能特性

### NFT 合约
- 支持 NFT 的铸造
- 支持跨链功能（使用 Chainlink CCIP）
- 使用 UUPS 代理模式，支持合约升级
- 自动递增的 Token ID

### 拍卖系统
- 支持 ETH 和 LINK 代币拍卖
- 实时价格转换（使用 Chainlink 预言机）
- 拍卖时间控制
- 自动退款机制
- 支持取消拍卖

## 部署方式

### 环境要求
- Node.js
- Hardhat
- MetaMask 或其他以太坊钱包

### 安装依赖
```bash
npm install
```

### 配置环境变量
创建 `.env.enc` 文件并配置以下变量：
```
SEPOLIA_RPC_URL=测试地址
ACCOUNT_1_PRIVATE_KEY=你的钱包秘钥
```

### 部署合约

1. 部署 NFT 合约：
```bash
npx hardhat run deploy/01_nft_uups_deploy.ts --network sepolia
```

2. 部署拍卖工厂合约：
```bash
npx hardhat run deploy/01_aution_factory_deploy.ts --network sepolia
```
3. 部署NFT V2升级合约：
```bash
npx hardhat run deploy/02_nft_uups_deploy.ts --network sepolia
```
## Sepolia 测试网合约地址



## 使用说明

### 铸造 NFT
1. 调用 NFT 合约的 `sendNFT` 函数
2. 传入接收者地址和 tokenURI
3. 等待交易确认

### 创建拍卖
1. 授权拍卖工厂合约操作你的 NFT
2. 调用工厂合约的 `createAution` 函数
3. 传入 NFT 合约地址、Token ID、起拍价和持续时间

### 参与拍卖
1. 使用 ETH 参与拍卖：
    - 调用拍卖合约的 `placeBidWithETH` 函数
    - 发送足够的 ETH

2. 使用 LINK 参与拍卖：
    - 授权拍卖合约使用你的 LINK 代币
    - 调用拍卖合约的 `placeBidWithERC20` 函数
    - 传入 LINK 代币地址和数量

### 结束拍卖
1. 拍卖时间结束后，卖家可以调用 `endAution` 函数
2. 如果拍卖成功，NFT 将转移给最高出价者
3. 如果拍卖失败，NFT 将返回给卖家

## 测试
运行测试：
```bash
npx hardhat test
```
具体测试某个函数
```bash
npx hardhat test test/test_name.ts



## 安全说明
- 所有合约都经过 OpenZeppelin 的安全库保护
- 使用 ReentrancyGuard 防止重入攻击
- 使用 Chainlink 预言机获取实时价格
- 使用 UUPS 代理模式支持合约升级

## 许可证
MIT
