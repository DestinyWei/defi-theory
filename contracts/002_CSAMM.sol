// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CSAMM {
    IERC20 immutable token0;
    IERC20 immutable token1;

    uint public reserve0;
    uint public reserve1;

    uint public totalSupply; // share的总供应量
    mapping(address => uint) public balanceOf; // 账户 => share余额

    bool flag;

    constructor(address _token0, address _token1) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    modifier isInit() {
        require(flag == true, "Don't Init!");
        _;
    }

    function _mint(address _to, uint _amount) private {
        // 此处补全
        require(_to != address(0), "ERC20: mint to the zero address");
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            balanceOf[_to] += _amount;
        }
    }

    function _burn(address _from, uint _amount) private {
        // 此处补全
        require(_from != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = balanceOf[_from];
        require(accountBalance >= _amount, "ERC20: burn amount exceeds balance");
        unchecked {
            balanceOf[_from] = accountBalance - _amount;
        }
    }

    function swap(
        address _tokenIn,
        uint _amountIn
    ) external isInit returns (uint amountOut) {
        // 此处补全
        // 判断是传入的是哪个token
        bool isToken0 = _tokenIn == address(token0) ? true : false;
        if(isToken0) {
            // x + dx
            reserve0 += _amountIn;
            // 实际的y
            uint realToken1 = totalSupply - reserve0;
            // dy = 原来的y - 实际的y
            amountOut = reserve1 - realToken1;
            // 更新reserve1
            reserve1 -= amountOut; // 或 reserve1 = realToken1;
        } else {
            // y + dy
            reserve1 += _amountIn;
            // 实际的x
            uint realToken0 = totalSupply - reserve1;
            // dx = 原来的x - 实际的x
            amountOut = reserve0 - realToken0;
            // 更新reserve0
            reserve0 -= amountOut; // 或 reserve0 = realToken0;
        }
    }

    function addLiquidity(
        uint _amount0,
        uint _amount1
    ) external returns (uint shares) {
        // 此处补全
        // 检查数量
        require(_amount0 > 0 && _amount1 > 0, "Invalid Amount!");
        // 更新变量
        if(reserve0 == 0 && reserve1 == 0) {
            flag = true;
        }
        totalSupply = _amount0 + _amount1;
        _update(reserve0 + _amount0, reserve1 + _amount1);
        // 两个token的转账
        token0.transferFrom(msg.sender, address(this), _amount0);
        token1.transferFrom(msg.sender, address(this), _amount1);
        // 计算share数量
        shares = (_amount0 + _amount1) * totalSupply / (reserve0 + reserve1);
        // mint对应数量的share
        _mint(msg.sender, shares);
    }

    function removeLiquidity(uint _shares) external isInit returns (uint d0, uint d1) {
        // 此处补全
        // 检查share余额
        require(_shares > 0 && _shares <= this.balanceOf(msg.sender), "Invalid Shares!");
        // 计算d0 d1
        d0 = reserve0 * _shares / totalSupply;
        d1 = reserve1 * _shares / totalSupply;
        // 更新变量
        _update(reserve0 - d0, reserve1 - d1);
        totalSupply = reserve0 + reserve1;
        // 转账
        token0.transfer(msg.sender, d0);
        token1.transfer(msg.sender, d1);
    }

    function _update(uint _res0, uint _res1) private {
        reserve0 = _res0;
        reserve1 = _res1;
    }
}
