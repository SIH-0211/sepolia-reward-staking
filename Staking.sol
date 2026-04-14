// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title ERC20Mock
 * @dev Mock ERC20 Token used for testing Staking and Reward Tokens.
 *      It allows anyone to mint tokens without restriction for testing purposes.
 */
contract ERC20Mock is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    /**
     * @dev Mint new tokens to a specified address.
     * @param to The address to receive the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

/**
 * @title Staking
 * @dev A smart contract for staking an ERC20 token to earn another ERC20 token as a reward.
 *      Includes a time-lock mechanism and emergency withdrawal.
 */
contract Staking is ReentrancyGuard {
    ERC20 public stakingToken;
    ERC20 public rewardToken;

    // 5 minutes lock-up period for testing purposes
    uint256 public constant LOCK_UP_PERIOD = 5 minutes;
    
    // Reward rate: 100 reward token wei per 1 staked token wei per second.
    uint256 public constant REWARD_RATE = 100;

    // User's staked balance
    mapping(address => uint256) public stakedBalanceOf;
    
    // The timestamp when a user last staked (resets lock-up period)
    mapping(address => uint256) public stakingTime; 
    
    // The timestamp when a user's reward was last calculated
    mapping(address => uint256) public lastUpdateTime;
    
    // Total accumulated rewards per user
    mapping(address => uint256) public accumulatedRewards;

    // Events for logging activities
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);
    event EmergencyWithdrawn(address indexed user, uint256 amount);

    /**
     * @dev Constructor to set the staking and reward tokens.
     * @param _stakingToken The contract address of the ERC20 token to stake.
     * @param _rewardToken The contract address of the ERC20 token given as rewards.
     */
    constructor(address _stakingToken, address _rewardToken) {
        require(_stakingToken != address(0), "Invalid staking token address");
        require(_rewardToken != address(0), "Invalid reward token address");
        stakingToken = ERC20(_stakingToken);
        rewardToken = ERC20(_rewardToken);
    }

    /**
     * @dev View function to calculate pending rewards based on staked balance and time passed.
     * @param user The address of the user.
     * @return The pending reward amount.
     */
    function pendingReward(address user) public view returns (uint256) {
        if (stakedBalanceOf[user] == 0) {
            return accumulatedRewards[user];
        }
        uint256 timeElapsed = block.timestamp - lastUpdateTime[user];
        // Calculates reward: (staked amount * time elapsed * rate) / 10^18
        uint256 currentReward = (stakedBalanceOf[user] * timeElapsed * REWARD_RATE) / 1e18;
        return accumulatedRewards[user] + currentReward;
    }

    /**
     * @dev Internal function to update a user's accumulated rewards before any state changes.
     * @param user The address of the user.
     */
    function _updateRewards(address user) internal {
        accumulatedRewards[user] = pendingReward(user);
        lastUpdateTime[user] = block.timestamp;
    }

    /**
     * @dev Allows users to stake a specified amount of tokens.
     *      Tokens must be approved prior to calling this function.
     * @param amount The amount of tokens to stake.
     */
    function stake(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        
        // Update user's reward state before modifying their balance
        _updateRewards(msg.sender);
        
        stakedBalanceOf[msg.sender] += amount;
        
        // Set/Reset the lock-up timer on every new stake
        stakingTime[msg.sender] = block.timestamp;
        
        // Transfer tokens from the user to the contract
        bool success = stakingToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Staking transfer failed");
        
        emit Staked(msg.sender, amount);
    }

    /**
     * @dev Allows users to withdraw their staked tokens after the lock-up period ends.
     * @param amount The amount of tokens to withdraw.
     */
    function unstake(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(stakedBalanceOf[msg.sender] >= amount, "Insufficient staked balance");
        
        // Enforce the 5-minute time-lock
        require(block.timestamp >= stakingTime[msg.sender] + LOCK_UP_PERIOD, "Tokens are still locked (5 minutes)");

        // Update user's reward state before modifying their balance
        _updateRewards(msg.sender);
        
        stakedBalanceOf[msg.sender] -= amount;
        
        // Transfer staked tokens back to the user
        bool success = stakingToken.transfer(msg.sender, amount);
        require(success, "Withdrawal transfer failed");

        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @dev Allows users to claim their accumulated reward tokens.
     */
    function claimReward() external nonReentrant {
        _updateRewards(msg.sender);
        
        uint256 reward = accumulatedRewards[msg.sender];
        require(reward > 0, "No rewards to claim");

        // Reset the user's accumulated rewards to 0
        accumulatedRewards[msg.sender] = 0;
        
        // Provide the user with their reward tokens
        bool success = rewardToken.transfer(msg.sender, reward);
        require(success, "Reward transfer failed. Contract might be out of reward tokens.");

        emit RewardClaimed(msg.sender, reward);
    }

    /**
     * @dev Allows users to immediately withdraw their staked tokens by bypassing the time-lock.
     *      WARNING: Calling this function FORFEITS all accumulated and pending rewards!
     */
    function emergencyWithdraw() external nonReentrant {
        uint256 amount = stakedBalanceOf[msg.sender];
        require(amount > 0, "No staked tokens to withdraw");

        // Forfeit rewards by securely resetting balance and reward states immediately
        stakedBalanceOf[msg.sender] = 0;
        accumulatedRewards[msg.sender] = 0;
        
        // We reset the update time so `pendingReward` doesn't calculate falsely later
        lastUpdateTime[msg.sender] = block.timestamp; 

        // Transfer all staked tokens back securely and immediately
        bool success = stakingToken.transfer(msg.sender, amount);
        require(success, "Emergency withdrawal transfer failed");

        emit EmergencyWithdrawn(msg.sender, amount);
    }
}
