const { ethers } = require("hardhat");

async function main() {

    let [deployer] = await ethers.getSigners();
    console.log('Deploying contracts with the account: ' + deployer.address);

    const VotingHelper = await ethers.getContractFactory('VotingHelper');
    const votingHelper = await VotingHelper.deploy();
    console.log(`Deployed VotingHelper to: ${votingHelper.address}`);
}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
})
