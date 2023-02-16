// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

//users stake usdt
//user get 20% APY CVIII as reward;
// tken ratio 1: 1

contract StakERC20 is Ownable {
    IERC20 public rewardToken;
    IERC20 public stakeToken;

    uint256 constant SECONDS_PER_YEAR = 31536000;

    struct User {
        uint256 stakedAmount;
        uint256 startTime;
        uint256 rewardAccrued;
    }

    mapping(address => User) user;
    error tryAgain();

    constructor(address _rewardToken) {
        rewardToken = IERC20(_rewardToken);
    }

    function setStakeToken(address _token)
        external
        onlyOwner
        returns (address _newToken)
    {
        require(IERC20(_token) != stakeToken, "Token already set");
        require(IERC20(_token) != rewardToken, "canot stake reward");

        require(_token != address(0), "cannot set address zero");

        stakeToken = IERC20(_token);
        _newToken = address(stakeToken);
    }

    function stake(uint256 amount) external {
        User storage _user = user[msg.sender];
        uint256 _amount = _user.stakedAmount;

        stakeToken.transferFrom(msg.sender, address(this), amount);

        if (_amount == 0) {
            _user.stakedAmount = amount;
            _user.startTime = block.timestamp;
        } else {
            updateReward();
            _user.stakedAmount += amount;
        }
    }

    function calcReward() public view returns (uint256 _reward) {
        User storage _user = user[msg.sender];

        uint256 _amount = _user.stakedAmount;
        uint256 _startTime = _user.startTime;
        uint256 duration = block.timestamp - _startTime;

        _reward = (duration * 20 * _amount) / (SECONDS_PER_YEAR * 100);
    }

    function claimReward(uint256 amount) public {
        User storage _user = user[msg.sender];
        updateReward();
        uint256 _claimableReward = _user.rewardAccrued;
        require(_claimableReward >= amount, "insufficient funds");
        _user.rewardAccrued -= amount;
        if (amount > rewardToken.balanceOf(address(this))) revert tryAgain();

        //require(amount <= rewardToken.balanceOf(address(this)), "insufficient funds");

        rewardToken.transfer(msg.sender, amount);
    }

    // There is a bug in the claimReward function that could result in a reentrancy attack. Specifically, if the amount being claimed is greater than the balance of the contract's rewardToken, then the tryAgain error is raised. However, this does not prevent the function from continuing to execute, and so the rewardToken.transfer call at the end of the function could potentially call an external contract that could call back into this contract and re-enter the function.

    // To fix this issue, the require statement should be updated to use require instead of if to revert the transaction and prevent any further execution of the function:

    function updateReward() public {
        User storage _user = user[msg.sender];
        uint256 _reward = calcReward();
        _user.rewardAccrued += _reward;
        _user.startTime = block.timestamp;
    }

    function withdraw(uint256 amount) public {
        User storage _user = user[msg.sender];
        uint256 staked = _user.stakedAmount;
        require(staked >= amount, "insufficient fund");
        updateReward();
        _user.stakedAmount -= amount;
        stakeToken.transfer(msg.sender, amount);
    }

    function closeAccount() external {
        User storage _user = user[msg.sender];
        uint256 staked = _user.stakedAmount;
        withdraw(staked);
        uint256 reward = _user.rewardAccrued;
        claimReward(reward);
    }

    function userInfo(address _user) external view returns (User memory) {
        return user[_user];
    }
}