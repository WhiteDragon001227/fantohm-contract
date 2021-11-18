const { ethers } = require("hardhat");

async function main() {

    let [deployer, DAO] = await ethers.getSigners();
    console.log('Deploying contracts with the account: ' + deployer.address);
    console.log('Deploying contracts with the account: ' + DAO.address);

    // Reserve addresses
    const reserves = [{
        name: 'DAI',
        address: '0x3D4f1706E2ef0E7Eb817DcEb815eCE6fadd37E04',
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
    const fhmAddress = '0x29a3f7E3E4925FC576d77b115E4F7327307bf018';

    // Treasury address
    const treasuryAddress = '0xcAa0EB441b18976EE4Dc3915c5dFb2124EDC69a4';

    // Staking address
    const stakingAddress = '0x1E79020Edb8872bd90fA73781b97862Da6f0D45e';

    // Staking helper address
    const stakingHelperAddress = '0x0bB56b553cc2Ff6A24aAbD67758D5aE0840AE560';

    const Treasury = await ethers.getContractFactory('FantohmTreasury');
    const treasury = await Treasury.attach(treasuryAddress);

    // Get reserve tokens
    for (let i = 0; i < reserves.length; i++) {
        const reserve = reserves[i];

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
        console.log(`${reserve.name} Bond: "${reserveToken.address}",`);
    }

    // Stake FHM through helper
    await stakingHelper.stake('100000000000');
    console.log('Staked FHM');
}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
})
