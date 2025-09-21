import { Provider } from "ethers"; // 引入 ethers Provider 类型

/**
 * 测试网专用：等待链上时间超过拍卖结束时间
 * @param {Provider} provider - ethers Provider 实例（用于获取区块时间）
 * @param {BigInt | number} endTime - 合约中拍卖的结束时间（链上 timestamp，支持 BigInt/number）
 * @param {number} [extraWaitMs=10000] - 额外等待时间（毫秒），默认 10秒，抵消测试网区块误差
 * @returns {Promise<boolean>} - 等待完成后返回 true（确认时间已超过 endTime）
 * @throws {Error} - 若获取区块信息失败或等待后时间仍未超过，抛出错误
 */
export async function waitUntilAfterEndTime(
    provider: Provider,
    endTime: BigInt | number,
    extraWaitMs: number = 10000
): Promise<boolean> {
    // 1. 统一 endTime 类型为 number（BigInt 转 number，测试网时间不会超过 Number 安全范围）
    const endTimeNum = Number(endTime);

    // 2. 获取当前链上时间（等待前）
    const blockBefore = await provider.getBlock("latest");
    if (!blockBefore || blockBefore.timestamp === undefined) {
        throw new Error("等待前：获取区块信息失败，无法获取当前链上时间");
    }
    const currentTimeBefore = blockBefore.timestamp;

    // 3. 打印等待前的时间信息（便于调试）
    console.log("=== 等待前时间信息 ===");
    console.log("拍卖结束时间:", new Date(endTimeNum * 1000).toLocaleString());
    console.log("当前链上时间:", new Date(currentTimeBefore * 1000).toLocaleString());
    console.log("当前时间是否已超过结束时间？", currentTimeBefore > endTimeNum);

    // 4. 计算需要等待的时间（确保等待后时间 = endTime + extraWaitMs）
    // 若当前时间已超过，无需等待；否则等待「结束时间 - 当前时间 + 额外时间」
    const timeToWaitMs = Math.max(0, (endTimeNum - currentTimeBefore) * 1000 + extraWaitMs);
    if (timeToWaitMs > 0) {
        console.log(`=== 开始等待 ===`);
        console.log(`需要等待 ${(timeToWaitMs / 1000).toFixed(1)} 秒（含 ${extraWaitMs / 1000} 秒额外缓冲）`);

        // 5. 执行等待（封装 setTimeout 为 Promise，支持 await）
        await new Promise<void>((resolve) => {
            setTimeout(() => {
                resolve();
            }, timeToWaitMs);
        });
    } else {
        console.log("=== 无需等待 ===");
        console.log("当前链上时间已超过拍卖结束时间，直接进入下一步");
    }

    // 6. 等待后验证时间是否已超过 endTime
    const blockAfter = await provider.getBlock("latest");
    if (!blockAfter || blockAfter.timestamp === undefined) {
        throw new Error("等待后：获取区块信息失败，无法验证时间");
    }
    const currentTimeAfter = blockAfter.timestamp;

    // 7. 打印等待后的时间信息（便于调试）
    console.log("=== 等待后时间信息 ===");
    console.log("拍卖结束时间:", new Date(endTimeNum * 1000).toLocaleString());
    console.log("当前链上时间:", new Date(currentTimeAfter * 1000).toLocaleString());
    console.log("当前时间是否已超过结束时间？", currentTimeAfter > endTimeNum);

    // 8. 若等待后时间仍未超过，抛出错误（极端情况，如测试网区块生成异常）
    if (currentTimeAfter <= endTimeNum) {
        throw new Error(
            `等待 ${timeToWaitMs / 1000} 秒后，链上时间仍未超过结束时间！` +
            `当前时间：${currentTimeAfter}，结束时间：${endTimeNum}`
        );
    }

    return true; // 确认时间已满足条件
}