const { ethers } = require("hardhat");

async function main() {

    let [deployer] = await ethers.getSigners();
    console.log('Deploying contracts with the account: ' + deployer.address);

    //const network = "rinkeby";
    //const network = "fantom_testnet";
    // const network = "fantom";
    // const network = "moonriver";
    const network = "bsc";
    const {
        layerZeroEndpoint,
    } = require(`../networks-${network}.json`);
    const baseTokenURI = "https://vids.invidme.com/nft-metadata";
    const maxMint = '100';
    // fantom
    const UsdbNFT = await ethers.getContractFactory('USDBNFT');
    const usdbnft = await UsdbNFT.deploy(baseTokenURI, layerZeroEndpoint, maxMint);
    console.log(`Deployed NFT to: ${usdbnft.address}`);
    
    console.log(`\nVerify:\nnpx hardhat verify --network ${network} `+
    `${usdbnft.address} "${baseTokenURI}" "${layerZeroEndpoint}" "${maxMint}"`);
    // // moonbase alpha
    // const MwsFHM = await ethers.getContractFactory('mwsFHM');
    // const mwsFHM = await MwsFHM.deploy("0x2575633c713578a99D51317e2424d4CAbfda2cc2");
    // console.log(`Deployed mwsFHM to: ${mwsFHM.address}`);

    // const SFHM = await ethers.getContractFactory('sFantohm');
    // const sFHM = await SFHM.attach("0x2575633c713578a99D51317e2424d4CAbfda2cc2");
    // await sFHM.approve(`${mwsFHM.address}`, "100000000000000000000000000000000");
}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
})
