const { ethers } = require("hardhat");

//Deployed FHUD to: 0x471D67Af380f4C903aD74944D08cB00d0D07853a
//Deployed FHUDMinter to: 0x6039910e36D1f5823f88006eeaC13d0A486Aa0Bc

async function main() {

    let [deployer] = await ethers.getSigners();
    console.log('Deploying contracts with the account: ' + deployer.address);

    // fantom
    // const FwsFHM = await ethers.getContractFactory('fwsFHM');
    // const fwsFHM = await FwsFHM.deploy("0xb7118db48cb2D7ff0f93dbDDa9D2289F6AA7CbF5");
    // console.log(`Deployed fwsFHM to: ${fwsFHM.address}`);
    //
    // const SFHM = await ethers.getContractFactory('sFantohm');
    // const sFHM = await SFHM.attach("0xb7118db48cb2D7ff0f93dbDDa9D2289F6AA7CbF5");
    // await sFHM.approve(`${fwsFHM.address}`, "100000000000000000000000000000000");

    // moonbase alpha
    const MwsFHM = await ethers.getContractFactory('mwsFHM');
    const mwsFHM = await MwsFHM.deploy("0x2575633c713578a99D51317e2424d4CAbfda2cc2");
    console.log(`Deployed mwsFHM to: ${mwsFHM.address}`);

    const SFHM = await ethers.getContractFactory('sFantohm');
    const sFHM = await SFHM.attach("0x2575633c713578a99D51317e2424d4CAbfda2cc2");
    await sFHM.approve(`${mwsFHM.address}`, "100000000000000000000000000000000");
}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
})
