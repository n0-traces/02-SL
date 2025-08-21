// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title MergeSortedArray
 * @dev 合并两个有序数组的合约
 */
contract MergeSortedArray {
    
    /**
     * @dev 合并两个有序数组为一个有序数组
     * @param arr1 第一个有序数组
     * @param arr2 第二个有序数组
     * @return 合并后的有序数组
     */
    function mergeSortedArrays(uint256[] memory arr1, uint256[] memory arr2) 
        public 
        pure 
        returns (uint256[] memory) 
    {
        uint256 len1 = arr1.length;
        uint256 len2 = arr2.length;
        uint256 totalLen = len1 + len2;
        
        // 创建结果数组
        uint256[] memory result = new uint256[](totalLen);
        
        uint256 i = 0; // arr1的索引
        uint256 j = 0; // arr2的索引
        uint256 k = 0; // result的索引
        
        // 合并两个数组
        while (i < len1 && j < len2) {
            if (arr1[i] <= arr2[j]) {
                result[k] = arr1[i];
                i++;
            } else {
                result[k] = arr2[j];
                j++;
            }
            k++;
        }
        
        // 将剩余的元素添加到结果数组
        while (i < len1) {
            result[k] = arr1[i];
            i++;
            k++;
        }
        
        while (j < len2) {
            result[k] = arr2[j];
            j++;
            k++;
        }
        
        return result;
    }
    
    /**
     * @dev 验证数组是否有序
     * @param arr 要验证的数组
     * @return 如果数组有序返回true，否则返回false
     */
    function isSorted(uint256[] memory arr) public pure returns (bool) {
        for (uint256 i = 1; i < arr.length; i++) {
            if (arr[i] < arr[i - 1]) {
                return false;
            }
        }
        return true;
    }
    
    /**
     * @dev 获取数组长度
     * @param arr 数组
     * @return 数组长度
     */
    function getArrayLength(uint256[] memory arr) public pure returns (uint256) {
        return arr.length;
    }
    
    /**
     * @dev 测试合并功能
     * @return 合并后的数组
     */
    function testMerge() public pure returns (uint256[] memory) {
        uint256[] memory arr1 = new uint256[](3);
        arr1[0] = 1;
        arr1[1] = 3;
        arr1[2] = 5;
        
        uint256[] memory arr2 = new uint256[](4);
        arr2[0] = 2;
        arr2[1] = 4;
        arr2[2] = 6;
        arr2[3] = 8;
        
        return mergeSortedArrays(arr1, arr2);
    }
}
