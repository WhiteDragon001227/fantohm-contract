const {ethers} = require("hardhat");

async function main() {

    let [deployer] = await ethers.getSigners();
    console.log('Deploying contracts with the account: ' + deployer.address);

    // const network = "rinkeby";
    const network = "fantom_testnet";
    const {
        daoAddress,
        zeroAddress,
        fhmAddress,
        usdbAddress,
        treasuryAddress,
        usdbMinterAddress,
    } = require(`../networks-${network}.json`);

    // Reserve addresses
    const reserve =
        {
            name: 'FHM',
            address: fhmAddress,
            bondBCV: '10000',
            depositAmount: '1000000000',
            depositProfit: '0',
        };

    // Large number for approval for reserve tokens
    const largeApproval = '100000000000000000000000000000000';

    // Bond vesting length in blocks. 33110 ~ 5 days
    const bondVestingLength = '1';

    // Min bond price
    const minBondPrice = '10000';

    // Max bond payout
    const maxBondPayout = '100000'

    // DAO fee for bond
    const bondFee = '10000';

    // Max debt bond can take on
    const maxBondDebt = '50000000000000000000000';

    // Initial Bond debt
    const initialBondDebt = '0';

    const soldBondsLimit = '10000000000000000000000';

    const useWhitelist = false;
    const useCircuitBreaker = true;

    const Treasury = await ethers.getContractFactory('FantohmTreasury');
    const treasury = await Treasury.attach(treasuryAddress);

    // Get Reserve Token
    const ReserveToken = await ethers.getContractFactory('contracts/fwsFHM.sol:ERC20'); // Doesn't matter which ERC20
    const reserveToken = await ReserveToken.attach(reserve.address);

    // Deploy Bond
    const Bond = await ethers.getContractFactory('UsdbFhmBurnBondDepository');
    // const bond = await Bond.attach("0xA1DFDc1d9dA00aaE194871C3fb2bF572EB1cC53e");
    const bond = await Bond.deploy(fhmAddress, usdbAddress, treasuryAddress, daoAddress, usdbMinterAddress);
    console.log(`Deployed ${reserve.name} Bond to: ${bond.address}`);

    // queue and toggle bond reserve depositor
    await treasury.queue('8', bond.address);
    console.log(`Queued ${reserve.name} Bond as reward manager`);
    await treasury.toggle('8', bond.address, zeroAddress);
    console.log(`Toggled ${reserve.name} Bond as reward manager`);

    // Set bond terms
    await bond.initializeBondTerms(reserve.bondBCV, bondVestingLength, minBondPrice, maxBondPayout, bondFee, maxBondDebt, initialBondDebt, soldBondsLimit, useWhitelist, useCircuitBreaker);
    console.log(`Initialized terms for ${reserve.name} Bond`);

    // Approve bonds to spend deployer's reserve tokens
    await reserveToken.approve(bond.address, largeApproval);
    console.log(`Approved bond to spend deployer ${reserve.name}`);

    const UsdbToken = await ethers.getContractFactory('USDB');
    const usdbToken = await UsdbToken.attach(usdbAddress);
    await usdbToken.grantRoleMinter(bond.address);
    console.log(`grant minter of USDB to ${bond.address}`);

    await bond.deposit('1000000000', '8000', deployer.address);
    console.log(`Deposited from deployer to Bond address: ${bond.address}`);

    // DONE
    console.log(`${reserve.name} Bond: "${reserveToken.address}",`);

    console.log(`\nVerify:\nnpx hardhat verify --network ${network} `+
        `${bond.address} "${fhmAddress}" "${usdbAddress}" "${treasuryAddress}" "${daoAddress}" "${usdbMinterAddress}"`);
}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
    })
