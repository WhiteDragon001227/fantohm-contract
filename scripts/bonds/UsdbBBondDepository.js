const {ethers} = require("hardhat");

async function main() {

    let [deployer] = await ethers.getSigners();
    console.log('Deploying contracts with the account: ' + deployer.address);

    const network = "rinkeby";
    // const network = "fantom_testnet";
    const {
        daoAddress,
        zeroAddress,
        fhmAddress,
        usdbAddress,
        treasuryAddress,
        stakingHelperAddress,
        usdbMinterAddress,
        twapOracleAddress,
        fhmDaiLpAddress,
        fhmCirculatingSupply
    } = require(`../networks-${network}.json`);

    // Reserve addresses
    const reserve =
        {
            name: 'USDB',
            address: usdbAddress,
            bondBCV: '10000',
            depositAmount: '100000000000000000000000',
            depositProfit: '0',
        };

    // Large number for approval for reserve tokens
    const largeApproval = '100000000000000000000000000000000';

    // Bond vesting length in blocks. 33110 ~ 5 days
    const bondVestingLength = '1';

    // Min bond price
    const maxDiscount = '8000';

    // Max bond payout
    const maxBondPayout = '100000'

    // DAO fee for bond
    const bondFee = '10000';

    // Max debt bond can take on
    const maxBondDebt = '50000000000000000000000';

    // Initial Bond debt
    const intialBondDebt = '0';

    const soldBondsLimit = '10000000000000000000000';

    const useWhitelist = false;
    const useCircuitBreaker = true;

    const Treasury = await ethers.getContractFactory('FantohmTreasury');
    const treasury = await Treasury.attach(treasuryAddress);

    // Get Reserve Token
    const ReserveToken = await ethers.getContractFactory('USDB');
    const reserveToken = await ReserveToken.attach(reserve.address);

    // Deploy Bond
    const Bond = await ethers.getContractFactory('UsdbBBondDepository');
    // const bond = await Bond.attach("0x05fE6236F28dCC67C4d6eD8D49369B5519696bA2");
    const bond = await Bond.deploy(fhmAddress, usdbAddress, treasury.address, daoAddress, usdbMinterAddress, fhmCirculatingSupply, twapOracleAddress, fhmDaiLpAddress);
    console.log(`Deployed ${reserve.name} Bond to: ${bond.address}`);

    // queue and toggle bond reserve depositor
    await treasury.queue('0', bond.address);
    console.log(`Queued ${reserve.name} Bond as reserve manager`);
    await treasury.toggle('0', bond.address, zeroAddress);
    console.log(`Toggled ${reserve.name} Bond as reserve manager`);

    // // Set bond terms
    await bond.initializeBondTerms(bondVestingLength, maxDiscount, maxBondPayout, bondFee, maxBondDebt, intialBondDebt, soldBondsLimit, useWhitelist, useCircuitBreaker);
    console.log(`Initialized terms for ${reserve.name} Bond`);

    // Set staking for bond
    await bond.setStaking(stakingHelperAddress, true);
    console.log(`Set Staking for ${reserve.name} Bond`);

    // Approve bonds to spend deployer's reserve tokens
    await reserveToken.approve(bond.address, largeApproval);
    console.log(`Approved bond to spend deployer ${reserve.name}`);

    await bond.deposit('10000000000000000000', '10000', deployer.address);
    console.log(`Deposited from deployer to Bond address: ${bond.address}`);

    // DONE
    console.log(`${reserve.name} Bond: "${reserveToken.address}",`);

    console.log(`\nVerify:\nnpx hardhat verify --network ${network} `+
        `${bond.address} "${fhmAddress}" "${usdbAddress}" "${treasury.address}" "${daoAddress}" "${usdbMinterAddress}" "${fhmCirculatingSupply}" "${twapOracleAddress}" "${fhmDaiLpAddress}"`);
}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
    })
