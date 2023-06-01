// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Poll is Ownable {
    // 总提案数
    uint8 public candidates;
    //总票数
    uint public turnout;
    //投票时间
    uint public duration;
    bool public started;
    uint public startTime;
    bool public ended;
    uint public endTime;
    //已投票数
    uint public votedNum;
    //记录投票人投给哪个提案
    mapping(address => uint8) public votedMap;
    //记录每个提案的得票数
    mapping(uint8 => uint) public scoreMap;
    //当前最高票提案的索引
    uint8 public highestCandidate;
    //当前最高票得票数
    uint public highestScore;
    event Started();
    event Ended();

    constructor(uint8 _candidates, uint _turnout, uint _duration) {
        candidates = _candidates;
        turnout = _turnout;
        duration = _duration;
    }

    function start() external onlyOwner {
        // 检查是否已经结束
        require(!ended, "Vote is ended");
        started = true;
        startTime = block.timestamp;

        emit Started();
    }

    function end() public {
        // 检查是否已经开始
        require(started, "Vote is not started");
        // 检查是否过了过期时间
        require(block.timestamp - duration >= startTime, "Still Voting");
        ended = true;
        endTime = startTime + duration;

        emit Ended();
    }

    function vote(uint8 candidateIndex) external {
        // 检查index
        require(candidateIndex > 0 && candidateIndex <= candidates, "Invalid index");
        // 检查是否已投票
        require(votedMap[msg.sender] == 0, "Already vote");
        // 检查投票数量
        require(votedNum <= turnout, "Max turnout");
        // 修改变量
        votedMap[msg.sender] = candidateIndex;
        scoreMap[candidateIndex] += 1;
        votedNum++;
        if(scoreMap[candidateIndex] > scoreMap[highestCandidate]) {
            highestCandidate = candidateIndex;
        }
        highestScore = scoreMap[highestCandidate];
    }

    function getResult() external view returns (uint8) {
        require(ended);
        return highestCandidate;
    }
}
