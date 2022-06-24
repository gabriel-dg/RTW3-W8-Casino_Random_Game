require("@nomiclabs/hardhat-waffle");
require('dotenv').config()

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more


// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */

module.exports = {
  solidity: "0.8.4",

  networks: {
    // "local-devnode": {
    //   url: "http://localhost:8545",
    //   accounts: { mnemonic: "test test test test test test test test test test test junk" }
    // },
    "optimistic-kovan": {
      //  url: "https://kovan.optimism.io",
      url: process.env.OP_KOVAN_URL,
      accounts: { mnemonic: process.env.MNEMONIC }
    },
    "optimism": {
      url: "https://mainnet.optimism.io",
      accounts: { mnemonic: process.env.MNEMONIC }
    }
  }

};
