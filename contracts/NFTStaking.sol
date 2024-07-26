// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Importing the interfaces and contracts
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract NFTStaking is UUPSUpgradeable, PausableUpgradeable, OwnableUpgradeable {

    // State variables 
    IERC721 public ContractNFT; // NFT contract
    IERC20 public rewardTokens; 
    uint256 public rewardPerBlock; // Reward for each block
    uint256 public unbonding_Period;
    uint256 public reward_ClaimDelay; // Delay before rewards can be claimed
    
    // Struct for the stake
    struct Stake {
        // State variables of the stake
        uint256 tokenId;
        uint256 stakeBlock;
        uint256 unbondingStart; // Block number when unbonding starts (0 means not in unbonding process)
    }

    // Mapping to track the stake for each user
    mapping(address => Stake[]) public stakes;
    mapping(address => uint256) public rewardDebt;
    mapping(address => uint256) public lastRewardClaimBlock;
  
    // Events for staked, unstaked, and reward claimed
    event Staked(address indexed user, uint256 tokenId);
    event Unstaked(address indexed user, uint256 tokenId);
    event RewardClaimed(address indexed user, uint256 reward);

    // Initialize the function to set initial values
    function initialize(
        address _ContractNFT,
        address _rewardTokens,
        uint256 _rewardPerBlock,
        uint256 _unbondingPeriod,
        uint256 _rewardClaimDelay
    ) public initializer {
        __Pausable_init();
        __Ownable_init;

        // Assigning the contracts to the parameters of the initial values of function initialize
        ContractNFT = IERC721(_ContractNFT);
        rewardTokens = IERC20(_rewardTokens);
        rewardPerBlock = _rewardPerBlock;
        unbonding_Period = _unbondingPeriod;
        reward_ClaimDelay = _rewardClaimDelay;
    }

    // Function upgradability, allow only owner to update/upgrade
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // User stake function to stake the tokens
    function stake(uint256 tokenId) external whenNotPaused {
        // If the ContractNFT owner is equal to the msg.sender then it will execute otherwise gives error not the owner
        require(ContractNFT.ownerOf(tokenId) == msg.sender, "Not the owner"); 
        ContractNFT.transferFrom(msg.sender, address(this), tokenId);
        
        stakes[msg.sender].push(Stake({ // Pushing the tokenId, stakeBlock, unbondingStart to stakes
            tokenId: tokenId,
            stakeBlock: block.number,
            unbondingStart: 0 // Initializing the unbonding start to 0
        }));

        emit Staked(msg.sender, tokenId);
    }
     
    // Unstake function for a token
    function unstake(uint256 tokenId) external whenNotPaused {
        Stake[] storage userStakes = stakes[msg.sender];
        for (uint256 i = 0; i < userStakes.length; i++) {
            if (userStakes[i].tokenId == tokenId && userStakes[i].unbondingStart == 0) {
                userStakes[i].unbondingStart = block.number;
                emit Unstaked(msg.sender, tokenId);
                return;
            }
        }

        // If no stake matches ("token_id) or already in the process of unstake then revert this error message
        revert("Token not staked or already unstaking");
    }

    // Function for user to withdraw the unstaked tokens
    function withdraw(uint256 tokenId) external whenNotPaused {
        Stake[] storage userStakes = stakes[msg.sender];
        for (uint256 i = 0; i < userStakes.length; i++) {
            if (userStakes[i].tokenId == tokenId && userStakes[i].unbondingStart > 0 &&
                block.number >= userStakes[i].unbondingStart + unbonding_Period) {
                ContractNFT.transferFrom(address(this), msg.sender, tokenId);
                _removeStake(msg.sender, i);
                return;
            }
        }
        revert("Unbonding period not over or token not found");
    }
 
    // For claiming the rewards
    function claimRewards() external whenNotPaused {
        uint256 reward = _calculateReward(msg.sender);
        require(block.number >= lastRewardClaimBlock[msg.sender] + reward_ClaimDelay, "Claim delay not met");

        rewardDebt[msg.sender] += reward;
        lastRewardClaimBlock[msg.sender] = block.number;

        rewardTokens.transfer(msg.sender, reward);
        emit RewardClaimed(msg.sender, reward);
    }
 
    // Function to calculate the accumulated rewards for a user
    function _calculateReward(address user) internal view returns (uint256) {
        uint256 totalReward = 0;
        Stake[] storage userStakes = stakes[user];
        for (uint256 i = 0; i < userStakes.length; i++) {
            if (userStakes[i].unbondingStart == 0) {
                totalReward += (block.number - userStakes[i].stakeBlock) * rewardPerBlock;
            }
        }
        return totalReward;
    }
  
    // To remove the stake from the stake mapping
    function _removeStake(address user, uint256 index) internal {
        Stake[] storage userStakes = stakes[user];
        userStakes[index] = userStakes[userStakes.length - 1];
        userStakes.pop();
    }
 
    function pause() external onlyOwner { // External function for the owner to pause the operation
        _pause();
    }

    function unpause() external onlyOwner { // External function for the owner to unpause the operation
        _unpause();
    }
    
    // To update the reward rate per each block
    function updateRewardPerBlock(uint256 newReward) external onlyOwner {
        rewardPerBlock = newReward;
    }
}
