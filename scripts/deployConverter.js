const { ethers } = require("hardhat");

async function main() {

    let [deployer] = await ethers.getSigners();
    console.log('Deploying contracts with the account: ' + deployer.address);

    const FantohmBridgeConverter = await ethers.getContractFactory('FantohmBridgeConverter');
    const bridgeConverter = await FantohmBridgeConverter.deploy("0x6039910e36D1f5823f88006eeaC13d0A486Aa0Bc", "0x02c811d5d59702A2Bf5c38eBD184299e7796BE45", "0x471D67Af380f4C903aD74944D08cB00d0D07853a");
    console.log(`Deployed FantohmBridgeConverter to: ${bridgeConverter.address}`);

    await bridgeConverter.setFee(10);
    await bridgeConverter.addBridgeContract("0x652648562f233c95E4E8DE417f8e99f4188649eF");

    // DAI (bridge token test)
    const BridgeToken = await ethers.getContractFactory('FantohmERC20Token');
    const bridgeToken = await BridgeToken.attach("0x652648562f233c95E4E8DE417f8e99f4188649eF");
    await bridgeToken.approve(`${bridgeConverter.address}`, "100000000000000000000000000000000");

    // native token
    const NativeToken = await ethers.getContractFactory('FantohmERC20Token');
    const nativeToken = await NativeToken.attach("0x471D67Af380f4C903aD74944D08cB00d0D07853a");
    await nativeToken.approve(`${bridgeConverter.address}`, "100000000000000000000000000000000");

}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
})
