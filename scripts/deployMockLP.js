const { ethers } = require("hardhat");

async function main() {

    let [deployer] = await ethers.getSigners();
    console.log('Deploying contracts with the account: ' + deployer.address);

    const MockLP = await ethers.getContractFactory('MockLP');
    const mock = await MockLP.deploy();
    console.log(`Deployed MockLP to: ${mock.address}`);
}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
})
