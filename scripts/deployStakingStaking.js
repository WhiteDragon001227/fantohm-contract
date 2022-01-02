const { ethers } = require("hardhat");

async function main() {

    let [deployer] = await ethers.getSigners();
    console.log('Deploying contracts with the account: ' + deployer.address);

    const RewardsHolder = await ethers.getContractFactory('RewardsHolder');
    const rewardsHolder = await RewardsHolder.deploy("0xA7e3647898A0F004a01a0EF832921f59b0c0A48e","0xb7118db48cb2D7ff0f93dbDDa9D2289F6AA7CbF5","0xeAF4d87871CA3064a39FD5c6740B0ec22F5dd024");
    console.log(`Deployed rewardsHolder to: ${rewardsHolder.address}`);

    const StakingStaking = await ethers.getContractFactory('StakingStaking');
    const stakingStaking = await StakingStaking.deploy("0xb7118db48cb2D7ff0f93dbDDa9D2289F6AA7CbF5", `${deployer.address}`);
    console.log(`Deployed StakingStaking to: ${stakingStaking.address}`);

    await rewardsHolder.init(`${stakingStaking.address}`, 2);

    await stakingStaking.init(`${rewardsHolder.address}`, 200, 3000, 100, false, false, false, true);

}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
})
