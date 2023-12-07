require("@nomiclabs/hardhat-waffle");
require("@pinata/hardhat-plugin");
//require('@openzeppelin/hardhat-upgrades');

const { alchemyApiKey, privateKey } = require("./secrets.json");

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.0",
  networks: {
    rinkeby: {
      url: `https://eth-rinkeby.alchemyapi.io/v2/${alchemyApiKey}`,
      accounts: [privateKey],
    },
  },
  pinata: {
    apiKey: "YOUR_PINATA_API_KEY",
    secretApiKey: "YOUR_PINATA_SECRET_API_KEY",
  },
};