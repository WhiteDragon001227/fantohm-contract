const { ethers } = require("hardhat");

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function main() {

    const {
        daoAddress
    } = require('../networks-fantom_testnet.json');

    const beets = "0x0";
    const fbeets = "0x0";
    const beetsMasterChef = "0x0";

    let [deployer] = await ethers.getSigners();
    console.log('Deploying contracts with the account: ' + deployer.address);

    const SfBeets = await ethers.getContractFactory('SfBeets');
    const sfBeets = await SfBeets.deploy();
    console.log(`Deployed SfBeets to: ${sfBeets.address}`);

    const SfBeetsManager = await ethers.getContractFactory('SfBeetsManager');
    const sfBeetsManager = await SfBeetsManager.deploy(beets, fbeets, sfBeets.address, daoAddress, beetsMasterChef);
    console.log(`Deployed SfBeetsManager to: ${sfBeetsManager.address}`);

    await sfBeetsManager.setup(22, 500, false);
    console.log("Parameters set");
}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
    })
