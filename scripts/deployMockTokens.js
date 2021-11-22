const { ethers } = require("hardhat");

async function main() {

    let [deployer] = await ethers.getSigners();
    console.log('Deploying mock reserves with the account: ' + deployer.address);

    // Initial mint for DAI (10,000,000)
    const initialMint = '10000000000000000000000000';

    // Deploy DAI
    const DAI = await ethers.getContractFactory('DAI');
    const dai = await DAI.deploy( 0 );
    console.log(`Deployed DAI to: ${dai.address}`)
    

    // Deploy 10,000,000 mock DAI
    await dai.mint( deployer.address, initialMint );
    console.log(`Minted DAI`)

    console.log( "DAI: " + dai.address );
}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
})