const { ethers } = require("hardhat");

async function main() {

    let [deployer] = await ethers.getSigners();
    console.log('Deploying contracts with the account: ' + deployer.address);

    const {
        fhmAddress,
        treasuryAddress,
        masterChefAddress,
    } = require('./networks-rinkeby.json');

    const fhmPerBlock = 10000000;
    const startBlock = 10311730;

    const MasterChefV2 = await ethers.getContractFactory('MasterChefV2');
    const masterChefV2 = await MasterChefV2.deploy(fhmAddress, treasuryAddress, treasuryAddress, fhmPerBlock, startBlock);
    // const masterChefV2 = await MasterChefV2.attach(masterChefAddress);
    console.log(`Deployed MasterChefV2 to: ${masterChefV2.address}`);

    const Treasury = await ethers.getContractFactory('FantohmTreasury');
    const treasury = await Treasury.attach(treasuryAddress);

    // queue and toggle bond reserve depositor
    await treasury.queue('8', masterChefV2.address);
    console.log(`Queued MasterChefV2 as reward manager`);
    await treasury.toggle('8', masterChefV2.address, zeroAddress);
    console.log(`Toggled MasterChefV2 as reward manager`);
}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
})
