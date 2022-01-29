const { ethers } = require("hardhat");

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function main() {

    let [deployer] = await ethers.getSigners();
    console.log('Deploying contracts with the account: ' + deployer.address);

    const TWAPOracle = await ethers.getContractFactory('FantohmTwapOracle');
    const twap = await TWAPOracle.deploy();
    console.log(`Deployed twap to: ${twap.address}`);
}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
})
