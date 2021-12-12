const { ethers } = require("hardhat");

//Deployed FHUD to: 0x471D67Af380f4C903aD74944D08cB00d0D07853a
//Deployed FHUDMinter to: 0x6039910e36D1f5823f88006eeaC13d0A486Aa0Bc

async function main() {

    let [deployer] = await ethers.getSigners();
    console.log('Deploying contracts with the account: ' + deployer.address);

    const FHUD = await ethers.getContractFactory('FHUD');
    const fhud = await FHUD.deploy();
    // const fhud = await FHUD.attach("0x471D67Af380f4C903aD74944D08cB00d0D07853a");
    console.log(`Deployed FHUD to: ${fhud.address}`);

    // FHUDMinter
    const FHUDMinter = await ethers.getContractFactory('FHUDMinter');
    const fhudMinter = await FHUDMinter.deploy();
    console.log(`Deployed FHUDMinter to: ${fhudMinter.address}`);

    await fhudMinter.setFhudAddress(`${fhud.address}`);

    // native token
    const NativeToken = await ethers.getContractFactory('FantohmERC20Token');
    const nativeToken = await NativeToken.attach("0xfa1FBb8Ef55A4855E5688C0eE13aC3f202486286");
    await nativeToken.approve(`${fhudMinter.address}`, "100000000000000000000000000000000");

    await fhudMinter.setFhmAddress(`${nativeToken.address}`);
    // await fhudMinter.setFhmLpAddress(<>,<>,<>);

}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
})
