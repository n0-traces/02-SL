// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StringReverser {
    
    /**
     * @dev 反转字符串函数
     * @param input 输入的字符串
     * @return 反转后的字符串
     */
    function reverseString(string memory input) public pure returns (string memory) {
        // 将字符串转换为字节数组
        bytes memory strBytes = bytes(input);
        uint256 length = strBytes.length;
        
        // 如果字符串为空或只有一个字符，直接返回
        if (length <= 1) {
            return input;
        }
        
        // 创建新的字节数组来存储反转后的字符串
        bytes memory reversedBytes = new bytes(length);
        
        // 反转字符串
        for (uint256 i = 0; i < length; i++) {
            reversedBytes[i] = strBytes[length - 1 - i];
        }
        
        // 将字节数组转换回字符串
        return string(reversedBytes);
    }
    
    /**
     * @dev 测试函数 - 反转 "abcde" 应该返回 "edcba"
     */
    function testReverse() public pure returns (string memory) {
        return reverseString("abcde");
    }
}
