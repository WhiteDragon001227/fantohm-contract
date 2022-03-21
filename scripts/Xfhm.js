const { ethers, upgrades } = require("hardhat");

async function main() {

    let [deployer] = await ethers.getSigners();
    console.log('Deploying contracts with the account: ' + deployer.address);

    const network = "rinkeby";
    // const network = "fantom_testnet";
    const {
        fhmAddress,
    } = require(`./networks-${network}.json`);

    // Large number for approval for reserve tokens
    const largeApproval = '100000000000000000000000000000000';

    // XFHM
    const XFhm = await ethers.getContractFactory('XFhm');
    // const xfhm = await XFhm.attach("0xcd9703c30454D9a9113cf0cC2e2762E237d8AaA9");
    // const xfhm = await upgrades.deployProxy(XFhm, [fhmAddress], { unsafeAllow: ['delegatecall'] });
    const xfhm = await XFhm.deploy();
    await xfhm.deployed();
    console.log(`Deployed XFHM to: ${xfhm.address}`);

    await xfhm.initialize(fhmAddress);
    console.log(`Initialized XFHM`);

    const FhmToken = await ethers.getContractFactory('FantohmERC20Token');
    const fhmToken = await FhmToken.attach(fhmAddress);
    await fhmToken.approve(xfhm.address, largeApproval);
    console.log(`Approved FHM to be spent by XFHM`);

    await xfhm.deposit('1000000000');
    console.log(`Deposited from deployer to XFHM address: ${xfhm.address}`);

    console.log(`\nVerify:\nnpx hardhat verify --network ${network} `+
        `${xfhm.address}`);

}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
})
