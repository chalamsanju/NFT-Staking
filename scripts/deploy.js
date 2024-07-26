
async function main() {
    // Load environment variables
    require("dotenv").config();

    const { ethers, upgrades } = require("hardhat");

    // Get the contract factories
    const MockNFT = await ethers.getContractFactory("MockNFT");
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    const NFTStaking = await ethers.getContractFactory("NFTStaking");

    // Deploy MockNFT contract
    const mockNFT = await MockNFT.deploy();
    await mockNFT.deployed();
    console.log("MockNFT deployed to:", mockNFT.address);

    // Deploy MockERC20 contract
    const mockERC20 = await MockERC20.deploy("RewardToken", "RWT");
    await mockERC20.deployed();
    console.log("MockERC20 deployed to:", mockERC20.address);

    // Deployment parameters
    const rewardPerBlock = 10;
    const unbondingPeriod = 100;
    const rewardClaimDelay = 50;

    // Deploy the NFTStaking contract using a proxy
    const nftStaking = await upgrades.deployProxy(
        NFTStaking,
        [mockNFT.address, mockERC20.address, rewardPerBlock, unbondingPeriod, rewardClaimDelay],
        { initializer: "initialize" }
    );
    await nftStaking.deployed();
    console.log("NFTStaking deployed to:", nftStaking.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
