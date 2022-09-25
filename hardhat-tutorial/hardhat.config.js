require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config({path: ".env"});
require("@nomiclabs/hardhat-etherscan");

const QUICKNODE_HTTP_URL = process.env.QUICKNODE_HTTP_URL;

const MUMBAI_PRIVETE_KEY = process.env.MUMBAI_PRIVETE_KEY;

const POLYGONSCAN_KEY = process.env.POLYGONSCAN_KEY;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  networks: {
    mumbai: {
      url:QUICKNODE_HTTP_URL,
      accounts: [MUMBAI_PRIVETE_KEY],
    },
  },

  etherscan:{
    apiKey:{
      polygonMumbai: POLYGONSCAN_KEY,
    },
  },
};
