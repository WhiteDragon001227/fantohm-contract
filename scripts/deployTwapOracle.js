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

    // const FantohmOracle = await ethers.getContractFactory('FantohmOracle');
    // const fantohmOracle = await FantohmOracle.deploy("0xd77fc9c4074b56Ecf80009744391942FBFDDd88b", "0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E", "0xfa1FBb8Ef55A4855E5688C0eE13aC3f202486286");
    // console.log(`Deployed fantohmOracle to: ${fantohmOracle.address}`);
}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
})
