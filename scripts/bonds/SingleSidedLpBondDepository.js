const {ethers} = require("hardhat");

async function main() {

    let [deployer] = await ethers.getSigners();
    console.log('Deploying contracts with the account: ' + deployer.address);

    const {
        daoAddress,
        zeroAddress,
        daiAddress,
        fhmAddress,
        usdbAddress,
        treasuryAddress,
        usdbMinterAddress,
        balancerVaultAddress,
        usdbDaiLpAddress,
        masterChefAddress
    } = require('../networks-rinkeby.json');

    // Reserve addresses
    const reserve =
        {
            name: 'DAI',
            address: daiAddress,
            bondBCV: '10000',
            depositAmount: '100000000000000000000000',
            depositProfit: '0',
        };

    // Large number for approval for reserve tokens
    const largeApproval = '100000000000000000000000000000000';

    const bondVestingLength = '1';
    const maxDiscount = '0';

    // Max bond payout
    const maxBondPayout = '100000'

    // DAO fee for bond
    const bondFee = '10000';

    // Max debt bond can take on
    const maxBondDebt = '50000000000000000000000';

    // Initial Bond debt
    const intialBondDebt = '0';

    const soldBondsLimit = '10000000000000000000000';

    const useWhitelist = true;
    const useCircuitBreaker = false;

    const Treasury = await ethers.getContractFactory('FantohmTreasury');
    const treasury = await Treasury.attach(treasuryAddress);

    // Get Reserve Token
    const ReserveToken = await ethers.getContractFactory('contracts/fwsFHM.sol:ERC20'); // Doesn't matter which ERC20
    const reserveToken = await ReserveToken.attach(reserve.address);

    // Deploy Bond
    const Bond = await ethers.getContractFactory('SingleSidedLPBondDepository');
    // const bond = await Bond.attach( "0xaC1A9E0c70a7f187980ee5A8072ef6e0Aec9C472" );
    const bond = await Bond.deploy(fhmAddress, usdbAddress, reserve.address, treasury.address, daoAddress, usdbMinterAddress, balancerVaultAddress, usdbDaiLpAddress, masterChefAddress);
    await bond.deployed();
    console.log(`Deployed ${reserve.name} Bond to: ${bond.address}`);

    // queue and toggle bond reserve depositor
    await treasury.queue('8', bond.address);
    console.log(`Queued ${reserve.name} Bond as reward manager`);
    await treasury.toggle('8', bond.address, zeroAddress);
    console.log(`Toggled ${reserve.name} Bond as reward manager`);

    // Set bond terms
    await bond.initializeBondTerms(bondVestingLength, maxDiscount, maxBondPayout, bondFee, maxBondDebt, intialBondDebt, soldBondsLimit, useWhitelist, useCircuitBreaker);
    console.log(`Initialized terms for ${reserve.name} Bond`);

    // Approve the treasury to spend deployer's reserve tokens
    await reserveToken.approve(treasury.address, largeApproval);
    console.log(`Approved treasury to spend deployer ${reserve.name}`);
    //
    // Approve bonds to spend deployer's reserve tokens
    await reserveToken.approve(bond.address, largeApproval);
    console.log(`Approved bond to spend deployer ${reserve.name}`);

    const UsdbToken = await ethers.getContractFactory('USDB');
    const usdbToken = await UsdbToken.attach(usdbAddress);
    await usdbToken.grantRoleMinter(bond.address);
    console.log(`grant minter of USDB to ${bond.address}`);

    const MasterChefV2 = await ethers.getContractFactory('MasterChefV2');
    const masterChefV2 = await MasterChefV2.attach(masterChefAddress);
    await masterChefV2.grantRoleWhitelistWithdraw(bond.address);
    console.log(`grant WhitelistWithdraw of MasterChefV2 to ${bond.address}`);

    await bond.deposit('1000000000000000000', '100', deployer.address);
    console.log(`Deposited from deployer to Bond address: ${bond.address}`);

    // DONE
    console.log(`${reserve.name} Bond: "${reserveToken.address}",`);
}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
    })
