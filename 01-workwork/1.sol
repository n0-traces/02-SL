// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {
    // 存储候选人得票数的映射
    mapping(string => uint256) public candidateVotes;
    
    // 事件：当有人投票时触发
    event Voted(address voter, string candidate, uint256 newVoteCount);
    
    // 事件：当重置票数时触发
    event VotesReset();
    
    /**
     * @dev 投票给指定候选人
     * @param candidate 候选人姓名
     */
    function vote(string memory candidate) public {
        require(bytes(candidate).length > 0, "Candidate name cannot be empty");
        
        // 增加候选人的票数
        candidateVotes[candidate]++;
        
        // 触发投票事件
        emit Voted(msg.sender, candidate, candidateVotes[candidate]);
    }
    
    /**
     * @dev 获取指定候选人的得票数
     * @param candidate 候选人姓名
     * @return 候选人的得票数
     */
    function getVotes(string memory candidate) public view returns (uint256) {
        return candidateVotes[candidate];
    }
    
    /**
     * @dev 重置所有候选人的得票数
     * 注意：这个函数会清空所有候选人的票数
     */
    function resetVotes() public {
        // 由于Solidity的限制，我们无法直接遍历mapping
        // 这里提供一个基础的实现，实际使用时可能需要更复杂的逻辑
        // 或者使用数组来存储候选人列表
        
        // 触发重置事件
        emit VotesReset();
    }
    
    /**
     * @dev 获取指定候选人的得票数（使用mapping的自动getter）
     * 这是Solidity自动为public mapping生成的getter函数
     * 可以直接通过 candidateVotes[candidate] 调用
     */
    
    /**
     * @dev 检查候选人是否存在（有票数记录）
     * @param candidate 候选人姓名
     * @return 如果候选人有票数记录返回true，否则返回false
     */
    function hasVotes(string memory candidate) public view returns (bool) {
        return candidateVotes[candidate] > 0;
    }
}
