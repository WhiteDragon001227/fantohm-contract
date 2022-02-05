const { ethers } = require("hardhat");

async function main() {

    let [deployer] = await ethers.getSigners();
    console.log('Deploying contracts with the account: ' + deployer.address);

    const {
        zeroAddress,
        daiAddress,
        fhmAddress,
        treasuryAddress,
        stakingHelperAddress,
        fhudMinterAddress,
    } = require('../networks-fantom_testnet.json');

    const daoAddress = deployer.address;
    // const daoAddress = "0x34F93b12cA2e13C6E64f45cFA36EABADD0bA30fC";


    // Reserve addresses
    const reserves = [
        {
            name: 'DAI',
            address: daiAddress,
            bondBCV: '10000',
            depositAmount: '100000000000000000000000',
            depositProfit: '0',
        },
        // {
        //     name: 'MIM',
        //     address: mimAddress,
        //     bondBCV: '10000',
        //     depositAmount: '100000000000000000000000',
        //     depositProfit: '0',
        // },
    ];

    // Large number for approval for reserve tokens
    const largeApproval = '100000000000000000000000000000000';

    // Bond vesting length in blocks. 33110 ~ 5 days
    const bondVestingLength = '8640';
    // const bondVestingLength = '498300';

    // Min bond price
    const minBondPrice = '10000';

    const maxDiscount = '800';

    // Max bond payout
    const maxBondPayout = '1000'

    // DAO fee for bond
    const bondFee = '10000';

    // Max debt bond can take on
    const maxBondDebt = '50000000000000000000000';

    // Initial Bond debt
    const intialBondDebt = '0';


    const Treasury = await ethers.getContractFactory('FantohmTreasury');
    const treasury = await Treasury.attach(treasuryAddress);

    // Get reserve tokens
    for (let i = 0; i < reserves.length; i++) {
        const reserve = reserves[i];

        // Get Reserve Token
        const ReserveToken = await ethers.getContractFactory('contracts/fwsFHM.sol:ERC20'); // Doesn't matter which ERC20
        const reserveToken = await ReserveToken.attach(reserve.address);

        // Deploy Bond
        const Bond = await ethers.getContractFactory('FantohmBondDepository');
        const bond = await Bond.deploy( fhmAddress, reserve.address, treasury.address, daoAddress, zeroAddress, fhudMinterAddress);
        console.log(`Deployed ${reserve.name} Bond to: ${bond.address}`);

        // queue and toggle bond reserve depositor
        await treasury.queue('0', bond.address);
        console.log(`Queued ${reserve.name} Bond as reserve depositor`);
        await treasury.toggle('0', bond.address, zeroAddress);
        console.log(`Toggled ${reserve.name} Bond as reserve depositor`);

        // Set bond terms
        await bond.initializeBondTerms(reserve.bondBCV, bondVestingLength, minBondPrice, maxDiscount, maxBondPayout, bondFee, maxBondDebt, intialBondDebt);
        console.log(`Initialized terms for ${reserve.name} Bond`);

        // Set staking for bond
        await bond.setStaking(stakingHelperAddress, true);
        console.log(`Set Staking for ${reserve.name} Bond`);

        // Approve the treasury to spend deployer's reserve tokens
        await reserveToken.approve(treasury.address, largeApproval );
        console.log(`Approved treasury to spend deployer ${reserve.name}`);

        // Approve bonds to spend deployer's reserve tokens
        await reserveToken.approve(bond.address, largeApproval );
        console.log(`Approved bond to spend deployer ${reserve.name}`);

        await bond.deposit('1000000000000000000000', '60000', deployer.address );
        console.log(`Deposited from deployer to Bond address: ${bond.address}`);
        //
        // DONE
        console.log(`${reserve.name} Bond: "${reserveToken.address}",`);
    }
}

main()
        .then(() => process.exit())
        .catch(error => {
            console.error(error);
            process.exit(1);
        })
