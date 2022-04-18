const { ethers } = require("hardhat");

async function main() {

    let [deployer] = await ethers.getSigners();
    console.log('Deploying mock reserves with the account: ' + deployer.address);

    // Initial mint for DAI (10,000,000)
    const initialMint = '10000000000000000000000000';
    const initialMintUsdc = '10000000000000';

    // Deploy DAI
    const DAI = await ethers.getContractFactory('DAI');
    const dai = await DAI.deploy( 0 );
    console.log(`Deployed DAI to: ${dai.address}`)


    // Deploy 10,000,000 mock DAI
    await dai.mint( deployer.address, initialMint );
    console.log(`Minted DAI`)
    console.log( "DAI: " + dai.address );


    // Deploy MIM
    const MIM = await ethers.getContractFactory('Mim');
    const mim = await MIM.deploy( 0 );
    console.log(`Deployed MIM to: ${mim.address}`)

    // Deploy 10,000,000 mock MIM
    await mim.mint( deployer.address, initialMint );
    console.log(`Minted MIM`)
    console.log( "MIM: " + mim.address );

    // Deploy Lqdr
    const Lqdr = await ethers.getContractFactory('Lqdr');
    const lqdr = await Lqdr.deploy( 0 );
    console.log(`Deployed Lqdr to: ${lqdr.address}`)

    // Deploy 10,000,000 mock Lqdr
    await lqdr.mint( deployer.address, initialMint );
    console.log(`Minted Lqdr`)
    console.log( "Lqdr: " + lqdr.address );

    // Deploy Usdc
    const Usdc = await ethers.getContractFactory('Usdc');
    const usdc = await Usdc.deploy( 0 );
    console.log(`Deployed Usdc to: ${usdc.address}`)

    // Deploy 10,000,000 mock Usdc
    await usdc.mint( deployer.address, initialMintUsdc );
    console.log(`Minted Usdc`)
    console.log( "Usdc: " + usdc.address );
}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
})
