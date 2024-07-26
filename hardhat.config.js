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
