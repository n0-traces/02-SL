import fs from 'fs';
import path from 'path';

// 存储代理合约地址的文件路径
const PROXY_ADDRESS_FILE = path.join(__dirname, '../.proxy-address');

/**
 * 保存代理合约地址到文件
 * @param address 代理合约地址
 */
export function saveProxyAddress(address: string) {
  fs.writeFileSync(PROXY_ADDRESS_FILE, address);
  console.log(`代理合约地址已保存到: ${PROXY_ADDRESS_FILE}`);
}

/**
 * 从文件读取代理合约地址
 * @returns 代理合约地址
 */
export function getProxyAddress(): string {
  try {
    const address = fs.readFileSync(PROXY_ADDRESS_FILE, 'utf8').trim();
    if (!address) {
      throw new Error('代理合约地址文件为空');
    }
    return address;
  } catch (error) {
    console.error('读取代理合约地址失败:', error);
    throw new Error('请先部署合约或确保代理地址文件存在');
  }
} 