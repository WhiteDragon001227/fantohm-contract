const { ethers } = require("hardhat");

async function main() {

    let [deployer, DAO] = await ethers.getSigners();
    console.log('Deploying contracts with the account: ' + deployer.address);
    console.log('Deploying contracts with the account: ' + DAO.address);

    // Reserve addresses
    const reserves = [{
        name: 'DAI',
        address: '0x3B5ee34b19aB125D0033Ba620e98B984a38DEc16',
        bondBCV: '369',
        depositAmount: '9000000000000000000000000',
        depositProfit: '8400000000000000',
    }];

    // Ethereum 0 address, used when toggling changes in treasury
    const zeroAddress = '0x0000000000000000000000000000000000000000';

    // Large number for approval for reserve tokens
    const largeApproval = '100000000000000000000000000000000';

    // Bond vesting length in blocks. 33110 ~ 5 days
    const bondVestingLength = '33110';

    // Min bond price
    const minBondPrice = '50000';

    // Max bond payout
    const maxBondPayout = '50'

    // DAO fee for bond
    const bondFee = '10000';

    // Max debt bond can take on
    const maxBondDebt = '1000000000000000';

    // Initial Bond debt
    const intialBondDebt = '0';

    // FHM address
    const fhmAddress = '';

    // Treasury address
    const treasuryAddress = '';

    // Staking address
    const stakingAddress = '';

    // Staking helper address
    const stakingHelperAddress = '';

    const Treasury = await ethers.getContractFactory('FantohmTreasury');
    const treasury = await Treasury.attach(treasuryAddress);

    // Get reserve tokens
    for (let i = 0; i < reserves.length; i++) {
        // Get Reserve Token
        const ReserveToken = await ethers.getContractFactory('contracts/wOHM.sol:ERC20'); // Doesn't matter which ERC20
        const reserveToken = await ReserveToken.attach(reserve.address);

        // queue and toggle reserved tokens on treasury
        await treasury.queue('2', reserveToken.address);
        console.log(`Queued ${reserve.name} as reserve token`);
        await treasury.toggle('2', reserveToken.address, zeroAddress);
        console.log(`Toggled ${reserve.name} as reserve token`);

        // Deploy Bond
        const Bond = await ethers.getContractFactory('FantohmBondDepository');
        const bond = await Bond.deploy( fhmAddress, reserve.address, treasury.address, DAO.address, zeroAddress);
        console.log(`Deployed ${reserve.name} Bond to: ${bond.address}`);

        // queue and toggle bond reserve depositor
        await treasury.queue('0', bond.address);
        console.log(`Queued ${reserve.name} Bond as reserve depositor`);
        await treasury.toggle('0', bond.address, zeroAddress);
        console.log(`Toggled ${reserve.name} Bond as reserve depositor`);

        // Set bond terms
        await bond.initializeBondTerms(reserve.bondBCV, bondVestingLength, minBondPrice, maxBondPayout, bondFee, maxBondDebt, intialBondDebt);
        console.log(`Initialized terms for ${reserve.name} Bond`);

        // Set staking for bond
        await bond.setStaking(stakingAddress, stakingHelperAddress);
        console.log(`Set Staking for ${reserve.name} Bond`);

        // Approve the treasury to spend deployer's reserve tokens
        await reserveToken.approve(treasury.address, largeApproval );
        console.log(`Approved treasury to spend deployer ${reserve.name}`);

        // Approve bonds to spend deployer's reserve tokens
        await reserveToken.approve(bond.address, largeApproval );
        console.log(`Approved bond to spend deployer ${reserve.name}`);
        
        // Deposit reserve tokens to treasury, minting some FHM to deployer and depositProfit kept in treasury as excesss reserves
        await treasury.deposit(reserve.depositAmount, reserveToken.address, reserve.depositProfit);
        console.log(`Deposited ${reserve.name} into treasury`);

        await bond.deposit('1000000000000000000000', '60000', deployer.address );
        console.log(`Deposited from deployer to Bond address: ${bond.address}`);

        // DONE
        console.log(`${reserve.name}: "${reserveTokens[0].address}",`);
    }
}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
})
