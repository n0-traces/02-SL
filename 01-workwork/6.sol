// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BinarySearch {
    
    /**
     * @dev 二分查找算法 - 在有序数组中查找目标值
     * @param arr 有序数组（升序）
     * @param target 要查找的目标值
     * @return 如果找到目标值，返回其索引；如果未找到，返回-1
     */
    function binarySearch(uint[] memory arr, uint target) public pure returns (int) {
        // 处理空数组的情况
        if (arr.length == 0) {
            return -1;
        }
        
        int left = 0;
        int right = int(arr.length) - 1;
        
        while (left <= right) {
            int mid = left + (right - left) / 2;
            
            if (arr[uint(mid)] == target) {
                return mid;
            } else if (arr[uint(mid)] < target) {
                left = mid + 1;
            } else {
                right = mid - 1;
            }
        }
        
        return -1; // 未找到目标值
    }
    
    /**
     * @dev 查找目标值在有序数组中的插入位置
     * @param arr 有序数组（升序）
     * @param target 要插入的目标值
     * @return 应该插入的位置索引
     */
    function findInsertPosition(uint[] memory arr, uint target) public pure returns (uint) {
        uint left = 0;
        uint right = arr.length;
        
        while (left < right) {
            uint mid = left + (right - left) / 2;
            
            if (arr[mid] < target) {
                left = mid + 1;
            } else {
                right = mid;
            }
        }
        
        return left;
    }
    
    /**
     * @dev 查找目标值在有序数组中的第一个出现位置
     * @param arr 有序数组（升序）
     * @param target 要查找的目标值
     * @return 第一个出现位置的索引，如果未找到返回-1
     */
    function findFirstOccurrence(uint[] memory arr, uint target) public pure returns (int) {
        uint left = 0;
        uint right = arr.length;
        int result = -1;
        
        while (left < right) {
            uint mid = left + (right - left) / 2;
            
            if (arr[mid] == target) {
                result = int(mid);
                right = mid; // 继续向左查找
            } else if (arr[mid] < target) {
                left = mid + 1;
            } else {
                right = mid;
            }
        }
        
        return result;
    }
    
    /**
     * @dev 查找目标值在有序数组中的最后一个出现位置
     * @param arr 有序数组（升序）
     * @param target 要查找的目标值
     * @return 最后一个出现位置的索引，如果未找到返回-1
     */
    function findLastOccurrence(uint[] memory arr, uint target) public pure returns (int) {
        uint left = 0;
        uint right = arr.length;
        int result = -1;
        
        while (left < right) {
            uint mid = left + (right - left) / 2;
            
            if (arr[mid] == target) {
                result = int(mid);
                left = mid + 1; // 继续向右查找
            } else if (arr[mid] < target) {
                left = mid + 1;
            } else {
                right = mid;
            }
        }
        
        return result;
    }
    
    /**
     * @dev 测试函数 - 演示二分查找的使用
     */
    function testBinarySearch() public pure returns (bool) {
        uint[] memory arr = new uint[](7);
        arr[0] = 1;
        arr[1] = 3;
        arr[2] = 5;
        arr[3] = 7;
        arr[4] = 9;
        arr[5] = 11;
        arr[6] = 13;
        
        // 测试查找存在的值
        int result1 = binarySearch(arr, 7);
        int result2 = binarySearch(arr, 1);
        int result3 = binarySearch(arr, 13);
        
        // 测试查找不存在的值
        int result4 = binarySearch(arr, 6);
        int result5 = binarySearch(arr, 0);
        int result6 = binarySearch(arr, 15);
        
        // 验证结果
        return result1 == 3 && result2 == 0 && result3 == 6 && 
               result4 == -1 && result5 == -1 && result6 == -1;
    }
}
