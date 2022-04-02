const { ethers } = require("hardhat");

async function main() {

    let [deployer] = await ethers.getSigners();
    console.log('Deploying contracts with the account: ' + deployer.address);

    // const network = "rinkeby";
    // const network = "fantom_testnet";
    const network = "fantom";
    const {
        daoAddress,
        zeroAddress,
        fhmAddress,
        treasuryAddress,
        masterChefAddress,
    } = require(`./networks-${network}.json`);

    // const fhmPerBlock = 100000000000;
    const fhmPerBlock = 1000000000;
    // const startBlock = 10383396;
    const startBlock = 35073029;

    const MasterChefV2 = await ethers.getContractFactory('MasterChefV2');
    // const masterChefV2 = await MasterChefV2.attach(masterChefAddress);
    const masterChefV2 = await MasterChefV2.deploy(fhmAddress, treasuryAddress, daoAddress, fhmPerBlock, startBlock);
    console.log(`Deployed MasterChefV2 to: ${masterChefV2.address}`);

    const Treasury = await ethers.getContractFactory('FantohmTreasury');
    const treasury = await Treasury.attach(treasuryAddress);

    // queue and toggle bond reserve depositor
    await treasury.queue('8', masterChefV2.address);
    console.log(`Queued MasterChefV2 as reward manager`);
    await treasury.toggle('8', masterChefV2.address, zeroAddress);
    console.log(`Toggled MasterChefV2 as reward manager`);

    console.log(`\nVerify:\nnpx hardhat verify --network ${network} `+
        `${masterChefV2.address} "${fhmAddress}" "${treasuryAddress}" "${daoAddress}" ${fhmPerBlock} ${startBlock}`);

}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
})
