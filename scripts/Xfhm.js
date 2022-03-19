const { ethers, upgrades } = require("hardhat");

async function main() {

    let [deployer] = await ethers.getSigners();
    console.log('Deploying contracts with the account: ' + deployer.address);

    const {
        fhmAddress,
    } = require('./networks-fantom.json');

    // Large number for approval for reserve tokens
    const largeApproval = '100000000000000000000000000000000';

    // XFHM
    const XFhm = await ethers.getContractFactory('XFHM');
    const xfhm = await upgrades.deployProxy(XFhm);
    await xfhm.deployed();
    console.log(`Deployed XFHM to: ${xfhm.address}`);

    await xfhm.initialize(fhmAddress);
    console.log(`Initialized XFHM`);

    const FhmToken = await ethers.getContractFactory('FantohmERC20Token');
    const fhmToken = await FhmToken.attach(fhmAddress);
    await fhmToken.approve(xfhm.address, largeApproval);
    console.log(`Approved FHM to be spent by XFHM`);

    await xfhm.deposit('1000000000000000000000');
    console.log(`Deposited from deployer to XFHM address: ${xfhm.address}`);

}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
})
