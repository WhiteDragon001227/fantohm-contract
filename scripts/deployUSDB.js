const { ethers } = require("hardhat");

async function main() {

    let [deployer] = await ethers.getSigners();
    console.log('Deploying contracts with the account: ' + deployer.address);

    const {
        fhmAddress,
        fhudAddress,
        usdcAddress,
        fhmDaiLpAddress,
    } = require('./networks-rinkeby.json');

    const USDB = await ethers.getContractFactory('USDB');
    const usdb = await USDB.deploy();
    // const usdb = await USDB.attach(usdcAddress);
    console.log(`Deployed USDB to: ${usdb.address}`);

    // USDBMinter
    const USDBMinter = await ethers.getContractFactory('USDBMinter');
    const usdbMinter = await USDBMinter.deploy();
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
