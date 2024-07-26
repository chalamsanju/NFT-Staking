const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("NFTStaking", function () {
    let nft, rewardToken, staking, owner, addr1, addr2;

    beforeEach(async function () {
        [owner, addr1, addr2, _] = await ethers.getSigners();

        // Deploy mock NFT and reward token contracts
        const NFT = await ethers.getContractFactory("MockNFT");
        nft = await NFT.deploy();
        await nft.deployed();

        const RewardToken = await ethers.getContractFactory("MockERC20");
        rewardToken = await RewardToken.deploy();
        await rewardToken.deployed();

        // Deploy the staking contract
        const NFTStaking = await ethers.getContractFactory("NFTStaking");
        staking = await upgrades.deployProxy(NFTStaking, [nft.address, rewardToken.address, 1, 100, 50]);
        await staking.deployed();
    });

    it("Should set the right owner", async function () {
        expect(await staking.owner()).to.equal(owner.address);
    });

    it("Should stake NFT and emit event", async function () {
        await nft.mint(addr1.address, 1);
        await nft.connect(addr1).approve(staking.address, 1);
        await expect(staking.connect(addr1).stake(1))
            .to.emit(staking, "Staked")
            .withArgs(addr1.address, 1);
    });

    it("Should unstake NFT and emit event", async function () {
        await nft.mint(addr1.address, 1);
        await nft.connect(addr1).approve(staking.address, 1);
        await staking.connect(addr1).stake(1);

        await expect(staking.connect(addr1).unstake(1))
            .to.emit(staking, "Unstaked")
            .withArgs(addr1.address, 1);
    });

    it("Should withdraw NFT after unbonding period", async function () {
        await nft.mint(addr1.address, 1);
        await nft.connect(addr1).approve(staking.address, 1);
        await staking.connect(addr1).stake(1);
        await staking.connect(addr1).unstake(1);

        await ethers.provider.send("evm_increaseTime", [100]);
        await ethers.provider.send("evm_mine", []);

        await staking.connect(addr1).withdraw(1);
        expect(await nft.ownerOf(1)).to.equal(addr1.address);
    });

    it("Should claim rewards", async function () {
        await nft.mint(addr1.address, 1);
        await nft.connect(addr1).approve(staking.address, 1);
        await staking.connect(addr1).stake(1);

        await ethers.provider.send("evm_mine", []);
        await ethers.provider.send("evm_mine", []);

        await staking.connect(addr1).claimRewards();
        expect(await rewardToken.balanceOf(addr1.address)).to.equal(2);
    });

    it("Should pause and unpause staking", async function () {
        await staking.pause();
        await expect(staking.connect(addr1).stake(1)).to.be.revertedWith("Pausable: paused");

        await staking.unpause();
        await expect(staking.connect(addr1).stake(1)).to.be.not.reverted;
    });

    it("Should update reward per block", async function () {
        await staking.updateRewardPerBlock(2);
        expect(await staking.rewardPerBlock()).to.equal(2);
    });
});

