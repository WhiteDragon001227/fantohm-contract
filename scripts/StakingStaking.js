const { ethers } = require("hardhat");

async function main() {

    let [deployer] = await ethers.getSigners();
    console.log('Deploying contracts with the account: ' + deployer.address);

    const {
        zeroAddress,
        fhmAddress,
        sfhmAddress,
        wsfhmAddress,
        stakingWarmupManagerAddress,
    } = require('./networks-fantom_testnet.json');

    const daoAddress = `${deployer.address}`;

    const RewardsHolder = await ethers.getContractFactory('RewardsHolder');
    const rewardsHolder = await RewardsHolder.deploy(fhmAddress, sfhmAddress, wsfhmAddress, stakingWarmupManagerAddress);
    console.log(`Deployed rewardsHolder to: ${rewardsHolder.address}`);

    const StakingStaking = await ethers.getContractFactory('StakingStaking');
    const stakingStaking = await StakingStaking.deploy(wsfhmAddress, daoAddress);
    console.log(`Deployed StakingStaking to: ${stakingStaking.address}`);

    // each 30 minutes new sample
    await rewardsHolder.setParameters(`${stakingStaking.address}`, 2000);

    // each 30 minutes without fee
    await stakingStaking.setParameters(`${rewardsHolder.address}`, 2000, 3000, 1000, false, false, true);

}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
})
