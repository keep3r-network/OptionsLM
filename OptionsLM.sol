// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

library Math {
    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }
}

interface erc20 {
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint amount) external returns (bool);
    function decimals() external view returns (uint8);
    function balanceOf(address) external view returns (uint);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
}

interface v3oracle {
    function assetToAsset(address, uint, address, uint) external view returns (uint);
}

contract OptionsLM {
    
    struct option {
        address owner;
        uint amount;
        uint strike;
        uint expiry;
        bool exercised; 
    }
    
    option[] public options;
    uint public nextIndex;
    
    function _claim(uint amount) internal returns (uint) {
        uint _twap = oracle.assetToAsset(reward, decimals, buyWith, 3600);
        options.push(option(msg.sender, amount, _twap, block.timestamp+OPTION_EXPIRY, false));
        return nextIndex++;
    }
    
    function redeem(uint id) external {
        option storage _opt = options[id];
        require(_opt.owner == msg.sender);
        require(_opt.expiry >= block.timestamp);
        require(!_opt.exercised);
        _safeTransferFrom(buyWith, msg.sender, treasury, _opt.amount * _opt.strike / decimals);
        _safeTransfer(reward, msg.sender, _opt.amount);
        _opt.exercised = true;
        options[id] = _opt;
    }
    
    address immutable public reward;
    address immutable public stake;
    address immutable public buyWith;
    address immutable public treasury;
    uint immutable public decimals;
    
    v3oracle constant oracle = v3oracle(0x0F1f5A87f99f0918e6C81F16E59F3518698221Ff);
    
    uint constant DURATION = 7 days;
    uint constant PRECISION = 10 ** 18;
    uint constant TWAP_PERIOD = 3600;
    uint constant OPTION_EXPIRY = 30 days;
    
    uint rewardRate;
    uint periodFinish;
    uint lastUpdateTime;
    uint rewardPerTokenStored;
    
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    
    constructor(address _reward, address _stake, address _buyWith, address _treasury) {
        reward = _reward;
        stake = _stake;
        buyWith = _buyWith;
        treasury = _treasury;
        decimals = 10**erc20(_reward).decimals();
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + ((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * PRECISION / totalSupply);
    }

    function earned(address account) public view returns (uint) {
        return (balanceOf[account] * (rewardPerToken() - userRewardPerTokenPaid[account]) / PRECISION) + rewards[account];
    }

    function getRewardForDuration() external view returns (uint) {
        return rewardRate * DURATION;
    }

    function deposit(uint amount) external update(msg.sender) {
        totalSupply += amount;
        balanceOf[msg.sender] += amount;
        _safeTransferFrom(stake, msg.sender, address(this), amount);
    }

    function withdraw(uint amount) public update(msg.sender) {
        totalSupply -= amount;
        balanceOf[msg.sender] -= amount;
        _safeTransfer(stake, msg.sender, amount);
    }

    function getReward() public update(msg.sender) returns (uint id) {
        uint _reward = rewards[msg.sender];
        if (_reward > 0) {
            rewards[msg.sender] = 0;
            id = _claim(_reward);
        }
    }

    function exit() external {
        withdraw(balanceOf[msg.sender]);
        getReward();
    }
    
    function notify(uint amount) external update(address(0)) {
        _safeTransferFrom(reward, msg.sender, address(this), amount);
        if (block.timestamp >= periodFinish) {
            rewardRate = amount / DURATION;
        } else {
            uint _remaining = periodFinish - block.timestamp;
            uint _leftover = _remaining * rewardRate;
            rewardRate = (amount + _leftover) / DURATION;
        }
        
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + DURATION;
    }

    modifier update(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }
    
    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
    
    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}