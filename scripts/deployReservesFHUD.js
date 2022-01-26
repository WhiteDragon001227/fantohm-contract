const { ethers } = require("hardhat");

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function main() {

    let [deployer] = await ethers.getSigners();
    console.log('Deploying contracts with the account: ' + deployer.address);

    // Reserve addresses
    const reserves = [
        {
            name: 'MIM',
            address: '0xFE2A3Da01681BD281cc77771c985CD7c4E372755',
        //    address: '0x82f0B8B456c1A451378467398982d4834b6829c1',
            bondBCV: '10000',
            depositAmount: '100000000000000000000000',
            depositProfit: '0',
        }
    ];

    // Ethereum 0 address, used when toggling changes in treasury
    const zeroAddress = '0x0000000000000000000000000000000000000000';

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

    // FHM address
    const fhmAddress = '0x4B209fd2826e6880e9605DCAF5F8dB0C2296D6d2';
    // const fhmAddress = '0xfa1FBb8Ef55A4855E5688C0eE13aC3f202486286';
    const sfhmAddress = '0x892bca2C0c2C2B244a43289885732a356Fde84cE';
    // const sfhmAddress = '0x5E983ff70DE345de15DbDCf0529640F14446cDfa';

    const fhudAddress = '0xc4175a594dff83FC9034f5b847251ce1e1a786EE';

    // Treasury address
    const treasuryAddress = '0xB58E41fadf1bebC1089CeEDbbf7e5E5e46dCd9b9';
    // const treasuryAddress = '0xA3b52d5A6d2f8932a5cD921e09DA840092349D71';

    // Staking address
    const stakingAddress = '0x8D4603d7302f2F962CCf6044A6AC2Dfd812B92bE';
    // const stakingAddress = '0xcb9297425C889A7CbBaa5d3DB97bAb4Ea54829c2';

    // Staking helper address
    // const stakingHelperAddress = '0x068e87aa1eABEBBad65378Ede4B5C16E75e5a671';

    const fhudMinterAddress = '0xA3b5fE35db679D21af9a499EE88231Ea9B656Cb8';
    // const fhudMinterAddress = '0xAF4B4A120e343996BFD9Dc48659fdbBd5055a735';

    const daoAddress = deployer.address;
    // const daoAddress = "0x34F93b12cA2e13C6E64f45cFA36EABADD0bA30fC";

    const Treasury = await ethers.getContractFactory('FantohmTreasury');
    const treasury = await Treasury.attach(treasuryAddress);

    // Get reserve tokens
    for (let i = 0; i < reserves.length; i++) {
        const reserve = reserves[i];

        // Get Reserve Token
        const ReserveToken = await ethers.getContractFactory('contracts/fwsFHM.sol:ERC20'); // Doesn't matter which ERC20
        const reserveToken = await ReserveToken.attach(reserve.address);

        // queue and toggle reserved tokens on treasury
        // await treasury.queue('2', reserveToken.address);
        // console.log(`Queued ${reserve.name} as reserve token`);
        // await treasury.toggle('2', reserveToken.address, zeroAddress);
        // console.log(`Toggled ${reserve.name} as reserve token`);

        // Deploy Bond
        // const Bond = await ethers.getContractFactory('FantohmBondDepository');
        // const bond = await Bond.deploy( fhmAddress, reserve.address, treasury.address, deployer.address, zeroAddress);
        const Bond = await ethers.getContractFactory('FantohmIsoBondDepository');
        // const bond = await Bond.attach("0x1e38e60F2c797A247A9b720F100d7E1cD8D256C0");
        const bond = await Bond.deploy( fhmAddress, fhudAddress, reserve.address, treasury.address, daoAddress, zeroAddress);
        console.log(`Deployed ${reserve.name} Bond to: ${bond.address}`);

        // queue and toggle bond reserve depositor
        await treasury.queue('0', bond.address);
        console.log(`Queued ${reserve.name} Bond as reserve depositor`);
        await treasury.toggle('0', bond.address, zeroAddress);
        console.log(`Toggled ${reserve.name} Bond as reserve depositor`);

        // // Set bond terms
        // await bond.initializeBondTerms(reserve.bondBCV, bondVestingLength, minBondPrice, maxDiscount, maxBondPayout, bondFee, maxBondDebt, intialBondDebt);
        // console.log(`Initialized terms for ${reserve.name} Bond`);
        //
        // // Set staking for bond
        // // await bond.setStaking(stakingAddress, stakingHelperAddress);
        // await bond.setStaking(stakingAddress);
        // console.log(`Set Staking for ${reserve.name} Bond`);
        //
        // // Approve the treasury to spend deployer's reserve tokens
        // await reserveToken.approve(treasury.address, largeApproval );
        // console.log(`Approved treasury to spend deployer ${reserve.name}`);
        //
        // // Approve bonds to spend deployer's reserve tokens
        // await reserveToken.approve(bond.address, largeApproval );
        // console.log(`Approved bond to spend deployer ${reserve.name}`);
        //
        // // Deposit reserve tokens to treasury, minting some FHM to deployer and depositProfit kept in treasury as excesss reserves
        // await treasury.deposit(reserve.depositAmount, reserveToken.address, reserve.depositProfit);
        // console.log(`Deposited ${reserve.name} into treasury`);
        //
        // await bond.deposit('1000000000000000000000', '60000', deployer.address );
        // console.log(`Deposited from deployer to Bond address: ${bond.address}`);

        // DONE
        console.log(`${reserve.name} Bond: "${reserveToken.address}",`);
    }

    // // Stake FHM through helper
    // await stakingHelper.stake('100000000000');
    // console.log('Staked FHM');
}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
})
