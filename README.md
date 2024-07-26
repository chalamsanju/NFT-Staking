1.SMART CONTRACTS
created the file named NFT-STAKING

//Installation of Hardhat 
npm install --save-dev hardhat
npx hardhat init

pacakages are installed

package.json - installing dependencies

{
  "name": "dzap-nft-staking",
  "version": "1.0.0",
  "description": "NFT Staking contract for DZap",
  "main": "hardhat.config.js",
  "scripts": {
    "test": "npx hardhat test",
    "deploy": "npx hardhat run scripts/deploy.js --network goerli"
  },
  "dependencies": {
    "@nomicfoundation/hardhat-toolbox": "^5.0.0",
    "@nomiclabs/hardhat-ethers": "^2.0.2",
    "@nomiclabs/hardhat-waffle": "^2.0.3",
    "@openzeppelin/contracts": "^5.0.2",
    "@openzeppelin/contracts-upgradeable": "^4.4.1",
    "@openzeppelin/hardhat-upgrades": "^1.11.0",
    "dotenv": "^10.0.0",
    "ethers": "^5.4.4",
    "hardhat": "^2.6.1"
  },
  "devDependencies": {
    "@nomicfoundation/hardhat-chai-matchers": "^2.0.7",
    "@nomicfoundation/hardhat-ethers": "^3.0.6",
    "@nomicfoundation/hardhat-ignition": "^0.15.5",
    "@nomicfoundation/hardhat-ignition-ethers": "^0.15.5",
    "@nomicfoundation/hardhat-network-helpers": "^1.0.11",
    "@nomicfoundation/hardhat-verify": "^2.0.8",
    "@nomicfoundation/ignition-core": "^0.15.5",
    "@typechain/ethers-v6": "^0.5.1",
    "@typechain/hardhat": "^9.1.0",
    "@types/chai": "^4.3.16",
    "@types/mocha": "^10.0.7",
    "chai": "^4.3.4",
    "ethereum-waffle": "^3.4.0",
    "hardhat": "^2.6.1",
    "hardhat-gas-reporter": "^1.0.10",
    "solidity-coverage": "^0.8.12",
    "ts-node": "^10.9.2",
    "typescript": "^5.5.4"
  }
}


=>CONTRACTS
1.NFTStaking.sol
2.MockNFT.sol
3.MockERC20.sol



2.COMPILATION USING HARDHAT

command--npx hardhat compile

create a file Staking.js
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




//3.DEPLOYING script

command-npx hardhat run scripts/deploy.js --network sepolia


hardhat-config-file

require("@nomiclabs/hardhat-ethers");
require("@openzeppelin/hardhat-upgrades");
require("dotenv").config();

const { INFURA_API_KEY, DEPLOYER_PRIVATE_KEY } = process.env;

const networks = {
  hardhat: {
    chainId: 1337,
  },
  sepolia: {
    url: `https://sepolia.infura.io/v3/${INFURA_API_KEY}`,
    accounts: DEPLOYER_PRIVATE_KEY ? [`0x${DEPLOYER_PRIVATE_KEY}`] : [],
  },
};

module.exports = {
  defaultNetwork: "hardhat",
  networks: networks,
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
};

//deploy.js


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


//creating dotenv file
INFURA_API_KEY=6283f856f0d5464d8a78eb70ad4d272c //infura api key
DEPLOYER_PRIVATE_KEY=1d0ef856b52ef007eb87b358ce8a606cfa844c146ed02d1ce765889db238d438 //your wallet private key




complted the Creation of smart contract for staking NFTs that rewards users with ERC20 tokens









