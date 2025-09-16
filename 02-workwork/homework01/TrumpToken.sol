// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

/**
 * @title TrumpToken
 * @dev 一个简单的 ERC20 代币合约实现
 * @author Your Name
 */
contract TrumpToken {
    // 代币基本信息
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    // 合约所有者
    address public owner;
    
    // 余额映射
    mapping(address => uint256) public balanceOf;
    
    // 授权映射 (授权者 => (被授权者 => 授权金额))
    mapping(address => mapping(address => uint256)) public allowance;
    
    // 事件定义
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed to, uint256 value);
    
    // 修饰符：只有所有者可以调用
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    // 构造函数
    constructor() {
        name = "Trump Token";
        symbol = "TRUMP";
        decimals = 18;
        totalSupply = 1000000 * 10**decimals; // 初始供应量 100万代币
        owner = msg.sender;
        
        // 将所有初始代币分配给合约部署者
        balanceOf[msg.sender] = totalSupply;
        
        // 发出初始转账事件
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    /**
     * @dev 查询账户余额
     * @param account 要查询的账户地址
     * @return 账户余额
     */
    function getBalance(address account) public view returns (uint256) {
        return balanceOf[account];
    }
    
    /**
     * @dev 转账代币
     * @param to 接收者地址
     * @param value 转账金额
     * @return 转账是否成功
     */
    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0), "Transfer to zero address");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    /**
     * @dev 授权其他地址使用自己的代币
     * @param spender 被授权者地址
     * @param value 授权金额
     * @return 授权是否成功
     */
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0), "Approve to zero address");
        
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    /**
     * @dev 代扣转账（被授权者调用）
     * @param from 代币所有者地址
     * @param to 接收者地址
     * @param value 转账金额
     * @return 转账是否成功
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");
        
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        
        emit Transfer(from, to, value);
        return true;
    }
    
    /**
     * @dev 增发代币（只有所有者可以调用）
     * @param to 接收者地址
     * @param value 增发金额
     */
    function mint(address to, uint256 value) public onlyOwner {
        require(to != address(0), "Mint to zero address");
        require(value > 0, "Mint amount must be greater than 0");
        
        totalSupply += value;
        balanceOf[to] += value;
        
        emit Mint(to, value);
        emit Transfer(address(0), to, value);
    }
    
    /**
     * @dev 查询授权额度
     * @param tokenOwner 代币所有者地址
     * @param spender 被授权者地址
     * @return 授权额度
     */
    function getAllowance(address tokenOwner, address spender) public view returns (uint256) {
        return allowance[tokenOwner][spender];
    }
}

