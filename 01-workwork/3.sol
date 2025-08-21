// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RomanNumeralConverter {
    
    /**
     * @dev 将罗马数字转换为整数
     * @param s 罗马数字字符串
     * @return 转换后的整数
     */
    function romanToInt(string memory s) public pure returns (uint256) {
        bytes memory strBytes = bytes(s);
        uint256 length = strBytes.length;
        uint256 result = 0;
        
        for (uint256 i = 0; i < length; i++) {
            uint256 currentValue = getRomanValue(strBytes[i]);
            
            // 检查是否有下一个字符，以及当前字符是否小于下一个字符
            if (i + 1 < length) {
                uint256 nextValue = getRomanValue(strBytes[i + 1]);
                
                // 处理特殊情况：小的数字在大的数字左边
                if (currentValue < nextValue) {
                    // 检查是否是有效的特殊情况
                    if ((strBytes[i] == bytes1("I") && (strBytes[i + 1] == bytes1("V") || strBytes[i + 1] == bytes1("X"))) ||
                        (strBytes[i] == bytes1("X") && (strBytes[i + 1] == bytes1("L") || strBytes[i + 1] == bytes1("C"))) ||
                        (strBytes[i] == bytes1("C") && (strBytes[i + 1] == bytes1("D") || strBytes[i + 1] == bytes1("M")))) {
                        result += nextValue - currentValue;
                        i++; // 跳过下一个字符，因为已经处理了
                        continue;
                    }
                }
            }
            
            result += currentValue;
        }
        
        return result;
    }
    
    /**
     * @dev 获取罗马字符对应的数值
     * @param c 罗马字符
     * @return 对应的数值
     */
    function getRomanValue(bytes1 c) private pure returns (uint256) {
        if (c == bytes1("I")) return 1;
        if (c == bytes1("V")) return 5;
        if (c == bytes1("X")) return 10;
        if (c == bytes1("L")) return 50;
        if (c == bytes1("C")) return 100;
        if (c == bytes1("D")) return 500;
        if (c == bytes1("M")) return 1000;
        return 0; // 无效字符
    }
    
    /**
     * @dev 测试函数 - 测试各种罗马数字转换
     */
    function testRomanConversions() public pure returns (uint256[5] memory) {
        uint256[5] memory results;
        
        // 测试用例1: "III" -> 3
        results[0] = romanToInt("III");
        
        // 测试用例2: "IV" -> 4
        results[1] = romanToInt("IV");
        
        // 测试用例3: "IX" -> 9
        results[2] = romanToInt("IX");
        
        // 测试用例4: "LVIII" -> 58
        results[3] = romanToInt("LVIII");
        
        // 测试用例5: "MCMXCIV" -> 1994
        results[4] = romanToInt("MCMXCIV");
        
        return results;
    }
    
    /**
     * @dev 获取单个测试结果
     */
    function testIII() public pure returns (uint256) {
        return romanToInt("III");
    }
    
    function testIV() public pure returns (uint256) {
        return romanToInt("IV");
    }
    
    function testIX() public pure returns (uint256) {
        return romanToInt("IX");
    }
    
    function testLVIII() public pure returns (uint256) {
        return romanToInt("LVIII");
    }
    
    function testMCMXCIV() public pure returns (uint256) {
        return romanToInt("MCMXCIV");
    }
}
