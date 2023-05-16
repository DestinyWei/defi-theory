// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract VaultTest {
    IERC20 public immutable token; // 质押的Token

    uint public totalSupply; // Vault中质押总量
    uint public rewardRate = 1; // 质押奖励的发放速率
    uint public lastUpdateTime; // 每次有用户操作时，更新为当前时间
    uint256 public rewardPerTokenStored; // 每单位数量获得奖励的累加值(乘上奖励发放速率后的值)

    mapping(address => uint) public balanceOf; // 用户质押数量
    mapping(address => uint256) public userRewardPerTokenPaid; // 记录每个用户每次操作的累加值(乘上奖励发放速率后的值)
    mapping(address => uint256) public rewards; // 用户到当前时刻可领取的奖励数量

    constructor(address _token) {
        token = IERC20(_token);
    }

    // 每次操作时更新奖励
    modifier updateReward(address _account) {
        // 更新累加值
        rewardPerTokenStored = rewardPerToken();
        // 更新上次操作时间
        lastUpdateTime = block.timestamp;
        // 检查账户地址
        require(_account != address(0), "Vault: not the zero address");
        // 更新账户奖励
        rewards[_account] = earned(_account);
        // 更新用户累加值
        userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        _;
    }

    function _mint(address _to, uint _amount) private {
        // 检查_to地址不为0
        require(_to != address(0), "Vault: mint to the zero address");
        // totalSupply增加
        totalSupply += _amount;
        // _to余额增加
        balanceOf[_to] += _amount;
    }

    function _burn(address _from, uint _amount) private {
        // 检查_from地址不为0
        require(_from != address(0), "Vault: mint to the zero address");
        // 检查_amount是否合法
        uint256 accountBalance = balanceOf[_from];
        require(
            accountBalance >= _amount,
            "Vault: burn amount exceeds balance"
        );
        // _from余额减少
        balanceOf[_from] = accountBalance - _amount;
        // totalSupply减少
        totalSupply -= _amount;
    }

    function deposit(uint _amount) external updateReward(msg.sender) {
        // 检查_amount数量
        require(_amount > 0, "Invalid amount");
        _mint(msg.sender, _amount);
        // 转账
        token.transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint _shares) external updateReward(msg.sender) {
        // 检查_amount数量
        require(_shares > 0, "Invalid amount");
        _burn(msg.sender, _shares);
        // 转账
        token.transferFrom(address(this), msg.sender, rewards[msg.sender]);
    }

    // 计算当前时刻的累加值
    function rewardPerToken() public view returns (uint256) {
        // 池子中没有代币
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        // 上一个累加值 + 最近一个区间的单位数量可获得的奖励数量
        return
            rewardPerTokenStored +
            ((block.timestamp - lastUpdateTime) * rewardRate) /
            totalSupply;
    }

    // 计算用户可以领取的奖励数量
    // 质押数量 * （当前累加值 - 用户上次操作时的累加值）+ 上次更新的奖励数量
    function earned(address _account) public view returns (uint256) {
        return
            balanceOf[_account] *
            (rewardPerTokenStored - userRewardPerTokenPaid[_account]) +
            rewards[_account];
    }
}
