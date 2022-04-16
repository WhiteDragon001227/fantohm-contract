const { ethers } = require("hardhat");

async function main() {

    let [deployer] = await ethers.getSigners();
    console.log('Deploying contracts with the account: ' + deployer.address);

    const network = "rinkeby";
    // const network = "fantom_testnet";
    // const network = "fantom";
    // const network = "moonriver";
    const {
        daoAddress,
        zeroAddress,
        fhmAddress,
        sfhmAddress,
        wsfhmAddress,
        stakingWarmupManagerAddress,
    } = require(`./networks-${network}.json`);

    // const blocksPerSample = 28800;
    // const blocksPerSample = 1960;
    const blocksPerSample = 10;

    const RewardsHolder = await ethers.getContractFactory('RewardsHolder');
    // const rewardsHolder = await RewardsHolder.attach("0xf3162417A5645ebd1A4553e5Be06Ef13d6a7dA95");
    const rewardsHolder = await RewardsHolder.deploy(fhmAddress, sfhmAddress, wsfhmAddress, stakingWarmupManagerAddress);
    console.log(`Deployed RewardsHolder to: ${rewardsHolder.address}`);

    console.log(`\nVerify:\nnpx hardhat verify --network ${network} `+
        `${rewardsHolder.address} "${fhmAddress}" "${sfhmAddress}" "${wsfhmAddress}" "${stakingWarmupManagerAddress}"`);

    const StakingStaking = await ethers.getContractFactory('StakingStaking');
    // const stakingStaking = await StakingStaking.attach("0x32bA75D49206b3A7123A5a38Eac0A77b9e205a51");
    const stakingStaking = await StakingStaking.deploy(wsfhmAddress, daoAddress);
    console.log(`Deployed StakingStaking to: ${stakingStaking.address}`);

    console.log(`\nVerify:\nnpx hardhat verify --network ${network} `+
        `${stakingStaking.address} "${wsfhmAddress}" "${daoAddress}"`);

    // each 30 minutes new sample
    await rewardsHolder.setParameters(`${stakingStaking.address}`, blocksPerSample);

    // each 30 minutes without fee
    await stakingStaking.setParameters(`${rewardsHolder.address}`, 2000, 3000, 1000, false, false, true);
    // await stakingStaking.setParameters(`${rewardsHolder.address}`, (blocksPerSample * 4 * 30), 3000, 1000, false, false, true);
    // await stakingStaking.setParameters(`${rewardsHolder.address}`, 101567, 3000, 1000, true, false, true);

}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
})
