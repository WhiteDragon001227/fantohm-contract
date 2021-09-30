require("@nomiclabs/hardhat-waffle");
const { alchemyApiKey, privateKey, etherscanApiKey, alchemyApiKeyProd } = require('./secrets.json');
require('@nomiclabs/hardhat-ethers');
require("@nomiclabs/hardhat-etherscan");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  networks: {
     rinkeby: {
       url: `https://eth-rinkeby.alchemyapi.io/v2/${alchemyApiKey}`,
        accounts: [`${privateKey}`]
     },
    mainnet: {
       url: `https://eth-mainnet.alchemyapi.io/v2/${alchemyApiKeyProd}`,
        accounts: [`${privateKey}`]
     },
    fantom_testnet: {
	url: `https://rpc.testnet.fantom.network/`,
	accounts: [`${privateKey}`]
    },
    hardhat: {
      chainId: 1337
    },
  },
  solidity: {
    version: "0.7.5",
    settings: {
	optimizer: {
    	    enabled: true,
    	    runs: 200
        }
    }
  },
etherscan: {
    apiKey: `${etherscanApiKey}`
},
};

