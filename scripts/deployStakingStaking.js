const { ethers } = require("hardhat");

async function main() {

    let [deployer] = await ethers.getSigners();
    console.log('Deploying contracts with the account: ' + deployer.address);

    const RewardsHolder = await ethers.getContractFactory('RewardsHolder');
    const rewardsHolder = await RewardsHolder.deploy("0xb7118db48cb2D7ff0f93dbDDa9D2289F6AA7CbF5");
    console.log(`Deployed rewardsHolder to: ${rewardsHolder.address}`);

    // FHUDMinter
    const StakingStaking = await ethers.getContractFactory('StakingStaking');
    const stakingStaking = await StakingStaking.deploy("0xb7118db48cb2D7ff0f93dbDDa9D2289F6AA7CbF5");
    console.log(`Deployed StakingStaking to: ${stakingStaking.address}`);

    await rewardsHolder.init(`${stakingStaking.address}`, 2);

    await stakingStaking.init(`${rewardsHolder.address}`, 20, 3000, 100, false, false, false, true);

}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
})
