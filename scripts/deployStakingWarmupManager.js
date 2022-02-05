const { ethers } = require("hardhat");

async function main() {

    let [deployer] = await ethers.getSigners();
    console.log('Deploying contracts with the account: ' + deployer.address);

    const {
        fhmAddress,
        sfhmAddress,
        stakingAddress,
    } = require('./networks-rinkeby.json');

    const StakingWarmupManager = await ethers.getContractFactory('StakingWarmupManager');
    const manager = await StakingWarmupManager.deploy(fhmAddress, stakingAddress);
    console.log(`Deployed StakingWarmupManager to: ${manager.address}`);

    const StakingWarmupExecutor = await ethers.getContractFactory('StakingWarmupExecutor');
    const executor1 = await StakingWarmupExecutor.deploy(fhmAddress, sfhmAddress, stakingAddress, `${manager.address}`);
    const executor2 = await StakingWarmupExecutor.deploy(fhmAddress, sfhmAddress, stakingAddress, `${manager.address}`);
    console.log(`Deployed StakingWarmupExecutor to: ${executor1.address}`);
    console.log(`Deployed StakingWarmupExecutor to: ${executor2.address}`);

    await manager.addExecutor(`${executor1.address}`);
    console.log(`added exec1`);
    await manager.addExecutor(`${executor2.address}`);
    console.log(`added exec2`);
}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
})
