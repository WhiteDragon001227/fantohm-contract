const { ethers, upgrades } = require("hardhat");

async function main() {

    let [deployer] = await ethers.getSigners();
    console.log('Deploying contracts with the account: ' + deployer.address);

    const {
        fhmAddress,
    } = require('./networks-fantom.json');

    // XFHM
    const XFhm = await ethers.getContractFactory('XFHM');
    const xfhm = await upgrades.deployProxy(XFhm, fhmAddress);
    await xfhm.deployed();
    console.log(`Deployed XFHM to: ${xfhm.address}`);

    await xfhm.deposit('1000000000000000000000');
    console.log(`Deposited from deployer to XFHM address: ${xfhm.address}`);

}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
})
