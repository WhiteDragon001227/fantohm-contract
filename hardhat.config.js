require("@nomiclabs/hardhat-waffle");
const { alchemyApiKey, privateKey, daoPrivateKey, etherscanApiKey, alchemyApiKeyProd } = require('./secrets.json');
require('@nomiclabs/hardhat-ethers');
require("@nomiclabs/hardhat-etherscan");
require('@openzeppelin/hardhat-upgrades');
// require('@symblox/hardhat-abi-gen');

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
      // url: `https://eth-mainnet.alchemyapi.io/v2/${alchemyApiKeyProd}`,
      url: `https://cloudflare-eth.com`,
      accounts: [`${privateKey}`]
    },
    bsc: {
      url: `https://bsc-dataseed.binance.org/`,
      accounts: [`${privateKey}`]
    },
    fantom_testnet: {
      url: `https://rpc.testnet.fantom.network/`,
      accounts: [`${privateKey}`]
    },
    fantom: {
      url: `https://rpc.ftm.tools/`,
      accounts: [`${privateKey}`]
    },
    moonriver: {
      url: `https://rpc.api.moonriver.moonbeam.network`,
      accounts: [`${privateKey}`],
      chainId: 1285
    },
    moonbase_testnet: {
      url: `https://rpc.testnet.moonbeam.network`,
      accounts: [`${privateKey}`],
      chainId: 1287
      // gas: 2100000,
      // gasPrice: 8000000000
    },
    avalanche: {
      url: `https://api.avax.network/ext/bc/C/rpc`,
      accounts: [`${privateKey}`],
      chainId: 43114
    },
    matic: {
      url: `https://rpc-mainnet.maticvigil.com`,
      accounts: [`${privateKey}`]
    }
    // hardhat: {
    //   chainId: 1287
    // },
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
  // abiExporter: {
  //   path: './data/abi',
  //   clear: true,
  //   flat: true,
  //   spacing: 2
  // }
};

