const { ethers } = require("hardhat");

async function main() {

    let [deployer] = await ethers.getSigners();
    console.log('Deploying contracts with the account: ' + deployer.address);

    const RewardsHolder = await ethers.getContractFactory('RewardsHolder');
    const rewardsHolder = await RewardsHolder.deploy("0x4B209fd2826e6880e9605DCAF5F8dB0C2296D6d2","0x892bca2C0c2C2B244a43289885732a356Fde84cE","0x2FD0fF45263143DcD616EcADa45c0D22e49aDBB7","0x1cED6A6253388A56759da72F16D16544577D4dB7");
    // const rewardsHolder = await RewardsHolder.deploy("0xA7e3647898A0F004a01a0EF832921f59b0c0A48e","0xb7118db48cb2D7ff0f93dbDDa9D2289F6AA7CbF5","0x5dbd56f663b76e47dcd8463407b0c671bb7a2e86","0xeAF4d87871CA3064a39FD5c6740B0ec22F5dd024");
    // const rewardsHolder = await RewardsHolder.deploy("0xfa1FBb8Ef55A4855E5688C0eE13aC3f202486286","0x5E983ff70DE345de15DbDCf0529640F14446cDfa","0x73199ba57BBFe82a935B9C95850395d80a400937","0xcb9297425C889A7CbBaa5d3DB97bAb4Ea54829c2");
    console.log(`Deployed rewardsHolder to: ${rewardsHolder.address}`);
    // const rewardsHolder = await RewardsHolder.attach("0x3423959f41744c9Ac4E8e403E55cCB457d6612dD");

    const StakingStaking = await ethers.getContractFactory('StakingStaking');
    const stakingStaking = await StakingStaking.deploy("0x2FD0fF45263143DcD616EcADa45c0D22e49aDBB7", `${deployer.address}`);
    // const stakingStaking = await StakingStaking.deploy("0x5dbd56f663b76e47dcd8463407b0c671bb7a2e86", `${deployer.address}`);
    // const stakingStaking = await StakingStaking.deploy("0x73199ba57BBFe82a935B9C95850395d80a400937", `${deployer.address}`);
    console.log(`Deployed StakingStaking to: ${stakingStaking.address}`);
    // const stakingStaking = await StakingStaking.attach("0x677381701B80AD66f93c35Bb1c284857B49eE39A");

    // each 30 mintues new sample
    await rewardsHolder.setParameters(`${stakingStaking.address}`, 2880);

    // each 30 minutes without fee
    await stakingStaking.setParameters(`${rewardsHolder.address}`, 2000, 3000, 1000, false, false, false, true);

}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
})
