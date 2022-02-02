const { ethers } = require("hardhat");

async function main() {

    let [deployer] = await ethers.getSigners();
    console.log('Deploying mock reserves with the account: ' + deployer.address);

    // Deploy DAI
    const MockTwapOracle = await ethers.getContractFactory('MockTwapOracle');
    const oracle = await MockTwapOracle.deploy( );
    console.log(`Deployed oracle to: ${oracle.address}`)

    await oracle.setAmountOut("35000000000000000000");
}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
})
