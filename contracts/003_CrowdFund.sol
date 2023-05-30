// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
    function transfer(address, uint) external returns (bool);

    function transferFrom(address, address, uint) external returns (bool);
}

contract CrowdFund {
    struct Campaign {
        // 活动创建人
        address creator;
        // 目标筹集金额
        uint goal;
        // 已筹集资金
        uint pledged;
        // 开始时间
        uint32 startAt;
        // 结束时间
        uint32 endAt;
        // 是否已领取
        bool claimed;
    }

    IERC20 public immutable token;
    // 活动的id也是根据count来创建
    uint public count;
    mapping(uint => Campaign) public campaigns;
    // campaign id => pledger => amount pledged
    mapping(uint => mapping(address => uint)) public pledgedAmount;

    // 以下事件需要全部被用上！
    event Launch(
        uint id,
        address creator,
        uint goal,
        uint32 startAt,
        uint32 endAt
    );
    event Pledge(uint id, address caller, uint amount);
    event Unpledge(uint id, address caller, uint amount);
    event Claim(uint id);
    event Refund(uint id, address caller, uint amount);

    constructor(address _token) {
        token = IERC20(_token);
    }

    function launch(uint _goal, uint32 _startAt, uint32 _endAt) external {
        require(_startAt >= block.timestamp, "start at < now");
        require(_endAt >= _startAt, "end at < start at");
        require(
            _endAt <= block.timestamp + 20 minutes,
            "end at > max duration"
        ); // 至少持续20分钟

        // 补全
        Campaign memory campaign = Campaign(
            msg.sender,
            _goal,
            0,
            _startAt,
            _endAt,
            false
        );
        campaigns[count] = campaign;
        emit Launch(count, msg.sender, _goal, _startAt, _endAt);
        // id递增
        count++;
    }

    function pledge(uint _id, uint _amount) external {
        // 检查id是否合法
        require(_id >= 0 && _id < count, "Invalid Id");

        Campaign storage campaign = campaigns[_id];
        require(block.timestamp >= campaign.startAt, "not started");
        require(block.timestamp <= campaign.endAt, "ended");
        // 检查是否已取回
        require(!campaign.claimed, "claimed");

        // 补全
        // 增加众筹的总数量
        campaign.pledged += _amount;
        // 增加单个用户的投资数量
        pledgedAmount[_id][msg.sender] += _amount;
        // 转账
        token.transferFrom(msg.sender, address(this), _amount);

        emit Pledge(_id, msg.sender, _amount);

    }

    function unpledge(uint _id, uint _amount) external {
        // 补全
        // 检查id是否合法
        require(_id >= 0 && _id < count, "Invalid Id");
        Campaign storage campaign = campaigns[_id];
        // 检查活动是否已经开始
        require(block.timestamp >= campaign.startAt, "not started");
        // 检查活动是否已经结束
        require(block.timestamp <= campaign.endAt, "ended");
        // 检查数量是否合法
        require(_amount > 0 && _amount <= pledgedAmount[_id][msg.sender], "Invalid amount");
        // 检查是否已取回
        require(!campaign.claimed, "claimed");
        // 取出相应数量的资金
        token.transfer(msg.sender, _amount);
        // 修改变量
        campaign.pledged -= _amount;
        pledgedAmount[_id][msg.sender] -= _amount;

        emit Unpledge(_id, msg.sender, _amount);
    }

    function claim(uint _id) external {
        // 补全
        // 检查id是否合法
        require(_id >= 0 && _id < count, "Invalid Id");
        Campaign storage campaign = campaigns[_id];

        require(campaign.creator == msg.sender, "not creator");
        require(block.timestamp > campaign.endAt, "not ended");
        require(campaign.pledged >= campaign.goal, "pledged < goal");
        require(!campaign.claimed, "claimed");

        // 补全
        token.transfer(msg.sender, campaign.pledged);
        // 修改campaign状态
        campaign.claimed = true;
        // 清空用户投资
        // delete pledgedAmount[_id];

        emit Claim(_id);
    }

    function refund(uint _id) external {
        // 补全
        // 检查id是否合法
        require(_id >= 0 && _id < count, "Invalid Id");
        Campaign storage campaign = campaigns[_id];

        require(block.timestamp > campaign.endAt, "not ended");
        require(campaign.pledged < campaign.goal, "pledged >= goal");
        // 检查是否已取回
        require(!campaign.claimed, "claimed");

        // 补全
        uint amount = pledgedAmount[_id][msg.sender];
        // 修改状态变量
        campaign.pledged -= amount;
        pledgedAmount[_id][msg.sender] -= amount;
        token.transfer(msg.sender, amount);

        emit Refund(_id, msg.sender, amount);
    }
}
