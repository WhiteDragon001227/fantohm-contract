const { ethers } = require("hardhat");

async function main() {

    let [deployer] = await ethers.getSigners();
    console.log('Deploying contracts with the account: ' + deployer.address);

    const network = "rinkeby";
    // const network = "fantom_testnet";
    const {
        fhmCirculatingSupply,
    } = require(`./networks-${network}.json`);

    const TreasuryHelper = await ethers.getContractFactory('TreasuryHelper');
    const treasuryHelper = await TreasuryHelper.deploy(fhmCirculatingSupply);
    console.log(`Deployed TreasuryHelper to: ${treasuryHelper.address}`);

    console.log(`\nVerify:\nnpx hardhat verify --network ${network} `+
        `${treasuryHelper.address} "${fhmCirculatingSupply}"`);
}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
})
