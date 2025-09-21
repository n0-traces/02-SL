// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title MockERC721
 * @dev 用于测试的简单ERC721实现
 */
contract MockERC721 is ERC721 {
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    /**
     * @dev 简单的mint函数，用于测试
     */
    function safeMint(address to, uint256 tokenId) public {
        _safeMint(to, tokenId);
    }
}
