const { ethers } = require("hardhat");

async function main() {

    let [deployer] = await ethers.getSigners();
    console.log('Deploying contracts with the account: ' + deployer.address);

    const {
        fhmAddress,
        fhudAddress,
        usdbAddress,
        fhmDaiLpAddress,
    } = require('./networks-fantom.json');

    const USDB = await ethers.getContractFactory('USDB');
    const usdb = await USDB.deploy();
    // const usdb = await USDB.attach(usdbAddress);
    console.log(`Deployed USDB to: ${usdb.address}`);

    // USDBMinter
    const USDBMinter = await ethers.getContractFactory('USDBMinter');
    const usdbMinter = await USDBMinter.deploy();
    // const usdbMinter = await USDBMinter.attach("0xe036823Fa26455D9DF0e3ed5Ec287a19356941e3");
    console.log(`Deployed USDBMinter to: ${usdbMinter.address}`);

    await usdbMinter.setUsdbAddress(`${usdb.address}`);
    await usdbMinter.setFhudAddress(fhudAddress);

    // native token
    const NativeToken = await ethers.getContractFactory('FantohmERC20Token');
    const nativeToken = await NativeToken.attach(fhmAddress);
    await nativeToken.approve(`${usdbMinter.address}`, "100000000000000000000000000000000");

    await usdbMinter.setFhmAddress(`${nativeToken.address}`);
    await usdbMinter.setFhmLpAddress(fhmDaiLpAddress, 7, true);
    // await usdbMinter.setFhmLpAddress(fhmDaiLpAddress, 5, false); // MOVR
}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
})
