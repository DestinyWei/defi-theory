// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract Vault {
    IERC20 public immutable token; // 质押的Token

    uint256 public totalDeposit; // Vault中质押总量
    uint256 public totalShare; // 总权益股份

    mapping(address => uint256) public depositOf; // 用户质押数量
    mapping(address => uint256) public shares;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function _mint(address _to, uint256 _amount) private {
        // 检查_to地址不为0
        require(_to != address(0), "Vault: mint to the zero address");
        // totalShare增加
        totalShare += _amount;
        // _to股份权益增加
        shares[_to] += _amount;
    }

    function _burn(address _from, uint256 _amount) private {
        // 检查_from地址不为0
        require(_from != address(0), "Vault: mint to the zero address");
        // 检查_amount是否合法
        uint256 accountBalance = shares[_from];
        require(
            accountBalance >= _amount,
            "Vault: burn amount exceeds balance"
        );
        // _from股份权益减少
        shares[_from] = accountBalance - _amount;
        // totalShare减少
        totalShare -= _amount;
    }

    function deposit(uint256 _amount) external {
        // 检查_amount数量
        require(_amount > 0, "Invalid amount");
        // totalSupply增加
        totalDeposit += _amount;
        // _to余额增加
        depositOf[msg.sender] += _amount;
        // 增加股份权益
        _mint(msg.sender, _amount);
        // 转账
        token.transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint256 _shares) external {
        // 检查_shares数量
        require(_shares > 0 && _shares <= shares[msg.sender], "Invalid amount");
        // 计算奖励
        uint256 contractBalance = token.balanceOf(address(this));
        uint256 reward = shares[msg.sender] / totalShare * contractBalance;
        // 更新存款
        uint256 deposit = shares[msg.sender] / totalShare * depositOf[msg.sender];
        depositOf[msg.sender] -= deposit;
        // totalDeposit减少
        totalDeposit -= deposit;
        // 销毁股份权益
        _burn(msg.sender, _shares);
        // 转账
        token.transfer(msg.sender, reward);
    }
}
