const { ethers } = require("hardhat");

async function main() {

    let [deployer] = await ethers.getSigners();
    console.log('Deploying contracts with the account: ' + deployer.address);

    const Multicall2 = await ethers.getContractFactory('Multicall2');
    const multicall2 = await Multicall2.deploy();
    console.log(`Deployed Multicall2 to: ${multicall2.address}`);
}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
})
