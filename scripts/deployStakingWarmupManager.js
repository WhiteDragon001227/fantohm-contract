const { ethers } = require("hardhat");

async function main() {

    let [deployer] = await ethers.getSigners();
    console.log('Deploying contracts with the account: ' + deployer.address);

    const StakingWarmupManager = await ethers.getContractFactory('StakingWarmupManager');
    const manager = await StakingWarmupManager.deploy("0x4B209fd2826e6880e9605DCAF5F8dB0C2296D6d2", "0x1cED6A6253388A56759da72F16D16544577D4dB7");
    console.log(`Deployed StakingWarmupManager to: ${manager.address}`);

    const StakingWarmupExecutor = await ethers.getContractFactory('StakingWarmupExecutor');
    const executor1 = await StakingWarmupExecutor.deploy("0x4B209fd2826e6880e9605DCAF5F8dB0C2296D6d2", "0x892bca2C0c2C2B244a43289885732a356Fde84cE", "0x1cED6A6253388A56759da72F16D16544577D4dB7", `${manager.address}`);
    const executor2 = await StakingWarmupExecutor.deploy("0x4B209fd2826e6880e9605DCAF5F8dB0C2296D6d2", "0x892bca2C0c2C2B244a43289885732a356Fde84cE", "0x1cED6A6253388A56759da72F16D16544577D4dB7", `${manager.address}`);
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
