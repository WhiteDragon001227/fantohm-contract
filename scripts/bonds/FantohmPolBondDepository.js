const {ethers} = require("hardhat");

async function main() {

    let [deployer] = await ethers.getSigners();
    console.log('Deploying contracts with the account: ' + deployer.address);

    const network = "rinkeby";
    // const network = "fantom_testnet";
    const {
        daoAddress,
        zeroAddress,
        principleAddress,
        fhmAddress,
        usdbAddress,
        treasuryAddress,
        usdbMinterAddress,
        uniswapRouterAddress,
        principleUsdbLPAddress,
        principleUsdbMultisigAddress,
        xfhmAddress,
        treasuryHelperAddress,
    } = require(`../networks-${network}.json`);


    // Reserve addresses
    const reserve =
        {
            name: 'Lqdr',
            address: principleAddress,
            bondBCV: '10000',
            depositAmount: '100000000000000000000000',
            depositProfit: '0',
        };
    // Large number for approval for reserve tokens
    const largeApproval = '100000000000000000000000000000000';

    // 6 weeks ~ 3628800
    // const bondVestingSecondsLength = '3628800';
    const bondVestingSecondsLength = '1';

    // 6 weeks/2 = 3628800/2 * 0.867 = 1573084
    // const bondVestingLength = '1573084';
    const bondVestingLengthSec = '1';
    const bondVestingLength = '10';

    const maxDiscount = '0';

    // Max bond payout
    const maxBondPayout = '10000000000000000000000000'

    // DAO fee for bond
    const bondFee = '100';

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
    const Bond = await ethers.getContractFactory('FantohmPolBondDepository');
    // const bond = await Bond.attach("0x4f06EC6079BB6F6B39aF11010d764f1B4747E3eC");
    const bond = await Bond.deploy(fhmAddress, usdbAddress, reserve.address, treasury.address, daoAddress, usdbMinterAddress, uniswapRouterAddress, principleUsdbLPAddress, xfhmAddress, treasuryHelperAddress, principleUsdbMultisigAddress);
    await bond.deployed();
    console.log(`Deployed ${reserve.name} Bond to: ${bond.address}`);

    // queue and toggle bond reserve depositor
    await treasury.queue('8', bond.address);
    console.log(`Queued ${reserve.name} Bond as reward manager`);
    await treasury.toggle('8', bond.address, zeroAddress);
    console.log(`Toggled ${reserve.name} Bond as reward manager`);

    // Set bond terms
    await bond.initializeBondTerms(bondVestingLengthSec, maxDiscount, maxBondPayout, bondFee, maxBondDebt, intialBondDebt, soldBondsLimit, useCircuitBreaker);
    console.log(`Initialized terms for ${reserve.name} Bond`);

    //Approve the treasury to spend deployer's reserve tokens
    await reserveToken.approve(treasury.address, largeApproval);
    console.log(`Approved treasury to spend deployer ${reserve.name}`);

    // Approve bonds to spend deployer's reserve tokens
    await reserveToken.approve(bond.address, largeApproval);
    console.log(`Approved bond to spend deployer ${reserve.name}`);

    const UsdbToken = await ethers.getContractFactory('USDB');
    const usdbToken = await UsdbToken.attach(usdbAddress);
    await usdbToken.grantRoleMinter(bond.address);
    console.log(`grant minter of USDB to ${bond.address}`);

    // Approve bonds to spend deployer's Xfhm tokens
    const XFHM = await ethers.getContractFactory('XFhm');
    const xFHM = await XFHM.attach(xfhmAddress);
    await xFHM.approve(bond.address, largeApproval);
    console.log(`Approved bond to spend deployer XFHM`);

    const LPToken = await ethers.getContractFactory('contracts/fwsFHM.sol:ERC20'); // Doesn't matter which ERC20
    const lpToken = await LPToken.attach(principleUsdbLPAddress);

    await lpToken.approve(bond.address, largeApproval);
    console.log(`Approved bond to spend vaults LP token`);

    await bond.deposit('1000000000000000000', '1000000000000000000', deployer.address);
    console.log(`Deposited from deployer to Bond address: ${bond.address}`);

    // DONE
    console.log(`${reserve.name} Bond: "${reserveToken.address}",`);

    console.log(`\nVerify:\nnpx hardhat verify --network ${network} `+
        `${bond.address} "${fhmAddress}" "${usdbAddress}" "${reserve.address}" "${treasuryAddress}" "${daoAddress}" "${usdbMinterAddress}" "${uniswapRouterAddress}" "${principleUsdbLPAddress}" "${xfhmAddress}" "${treasuryHelperAddress}" "${principleUsdbMultisigAddress}"`);
}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
    })
