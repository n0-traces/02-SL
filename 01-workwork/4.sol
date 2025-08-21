// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RomanNumeralConverter {
    
    // Roman numeral symbols and their values
    struct RomanSymbol {
        string symbol;
        uint256 value;
    }
    
    RomanSymbol[] private romanSymbols;
    
    constructor() {
        // Initialize Roman symbols in descending order of value
        romanSymbols.push(RomanSymbol("M", 1000));
        romanSymbols.push(RomanSymbol("CM", 900));
        romanSymbols.push(RomanSymbol("D", 500));
        romanSymbols.push(RomanSymbol("CD", 400));
        romanSymbols.push(RomanSymbol("C", 100));
        romanSymbols.push(RomanSymbol("XC", 90));
        romanSymbols.push(RomanSymbol("L", 50));
        romanSymbols.push(RomanSymbol("XL", 40));
        romanSymbols.push(RomanSymbol("X", 10));
        romanSymbols.push(RomanSymbol("IX", 9));
        romanSymbols.push(RomanSymbol("V", 5));
        romanSymbols.push(RomanSymbol("IV", 4));
        romanSymbols.push(RomanSymbol("I", 1));
    }
    
    /**
     * @dev Converts an integer to Roman numeral
     * @param num The integer to convert (1 <= num <= 3999)
     * @return The Roman numeral representation as a string
     */
    function intToRoman(uint256 num) public view returns (string memory) {
        require(num > 0 && num <= 3999, "Number must be between 1 and 3999");
        
        string memory result = "";
        uint256 remaining = num;
        
        for (uint256 i = 0; i < romanSymbols.length; i++) {
            while (remaining >= romanSymbols[i].value) {
                result = string(abi.encodePacked(result, romanSymbols[i].symbol));
                remaining -= romanSymbols[i].value;
            }
        }
        
        return result;
    }
    
    /**
     * @dev Test function to demonstrate the conversion with the given examples
     */
    function testExamples() public view returns (
        string memory example1,
        string memory example2,
        string memory example3
    ) {
        // Example 1: 3749 -> "MMMDCCXLIX"
        example1 = intToRoman(3749);
        
        // Example 2: 58 -> "LVIII"
        example2 = intToRoman(58);
        
        // Example 3: 1994 -> "MCMXCIV"
        example3 = intToRoman(1994);
    }
    
    /**
     * @dev Additional test cases to verify the conversion rules
     */
    function testAdditionalCases() public view returns (
        string memory case1,
        string memory case2,
        string memory case3,
        string memory case4
    ) {
        // Test case 1: 4 -> "IV" (subtraction form)
        case1 = intToRoman(4);
        
        // Test case 2: 9 -> "IX" (subtraction form)
        case2 = intToRoman(9);
        
        // Test case 3: 40 -> "XL" (subtraction form)
        case3 = intToRoman(40);
        
        // Test case 4: 90 -> "XC" (subtraction form)
        case4 = intToRoman(90);
    }
    
    /**
     * @dev Get the Roman symbols array for reference
     */
    function getRomanSymbols() public view returns (RomanSymbol[] memory) {
        return romanSymbols;
    }
}
