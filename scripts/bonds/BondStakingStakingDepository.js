const {ethers} = require("hardhat");

async function main() {

    let [deployer] = await ethers.getSigners();
    console.log('Deploying contracts with the account: ' + deployer.address);

    const network = "rinkeby";
    // const network = "fantom_testnet";
    // const network = "fantom";
    const {
        daoAddress,
        zeroAddress,
        daiAddress,
        usdcAddress,
        usdbAddress,
        fhmAddress,
        sfhmAddress,
        wsfhmAddress,
        treasuryAddress,
        stakingWarmupManagerAddress,
        usdbMinterAddress,
        fhmCirculatingSupply,
        stakingStakingAddress
    } = require(`../networks-${network}.json`);

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
        //     name: 'USDC',
        //     address: usdcAddress,
        //     bondBCV: '10000',
        //     depositAmount: '100000000000000000000000',
        //     depositProfit: '0',
        // },
    ];

    // Large number for approval for reserve tokens
    const largeApproval = '100000000000000000000000000000000';

    // Bond vesting length in blocks. 33110 ~ 5 days
    const bondVestingLength = 1; // rinkeby testnet
    const bondVestingSecondsLength = '501'; // rinkeby testnet
    // const bondVestingLength = '2592000'; // FTM mainnet
    // const bondVestingLength = '29400'; // MOVR?

    // Min bond price
    const minBondPrice = '2000';

    const maxDiscount = '0';

    // Max bond payout
    const maxBondPayout = '1000'

    // DAO fee for bond
    const bondFee = '10000';

    // Max debt bond can take on
    const maxBondDebt = '50000000000000000000000';

    // Initial Bond debt
    const initialBondDebt = '0';
    //claimPageSize
    const claimPageSize = '1000';

    const Treasury = await ethers.getContractFactory('FantohmTreasury');
    const treasury = await Treasury.attach(treasuryAddress);

    // Get reserve tokens
    for (let i = 0; i < reserves.length; i++) {
        const reserve = reserves[i];

        // Get Reserve Token
        const ReserveToken = await ethers.getContractFactory('contracts/fwsFHM.sol:ERC20'); // Doesn't matter which ERC20
        const reserveToken = await ReserveToken.attach(reserve.address);

        // Deploy Bond
        const Bond = await ethers.getContractFactory('BondStakingStakingDepository');
        // const bond = await Bond.attach("0x0D9b531C1e0AD04a7Da2d2E5Bc4a189aC0780118");
        const bond = await Bond.deploy(fhmAddress, sfhmAddress, wsfhmAddress, reserve.address, treasury.address, daoAddress, zeroAddress, usdbMinterAddress, fhmCirculatingSupply, stakingStakingAddress);
        await bond.deployed();
        console.log(`Deployed ${reserve.name} Bond to: ${bond.address}`);

        // queue and toggle bond reserve depositor
        await treasury.queue('0', bond.address);
        console.log(`Queued ${reserve.name} Bond as reserve depositor`);
        await treasury.toggle('0', bond.address, zeroAddress);
        console.log(`Toggled ${reserve.name} Bond as reserve depositor`);

        //Set bond terms
        await bond.initializeBondTerms(reserve.bondBCV, bondVestingSecondsLength, bondVestingLength, minBondPrice, maxDiscount, maxBondPayout, bondFee, maxBondDebt, initialBondDebt, claimPageSize);
        console.log(`Initialized terms for ${reserve.name} Bond`);

        // Set staking for bond
        await bond.setStakingWarmupManager(stakingWarmupManagerAddress, 2);
        console.log(`Set Staking for ${reserve.name} Bond`);

        // Approve the treasury to spend deployer's reserve tokens
        await reserveToken.approve(treasury.address, largeApproval);
        console.log(`Approved treasury to spend deployer ${reserve.name}`);

        // Approve bonds to spend deployer's reserve tokens
        await reserveToken.approve(bond.address, largeApproval);
        console.log(`Approved bond to spend deployer ${reserve.name}`);

        // await bond.deposit('1000000000000000000000', '60000', deployer.address);
        // console.log(`Deposited from deployer to Bond address: ${bond.address}`);
       
        // DONE
        console.log(`${reserve.name} Bond: "${reserveToken.address}",`);

        console.log(`\nVerify:\nnpx hardhat verify --network ${network} `+
                    `${bond.address} "${fhmAddress}" "${sfhmAddress}" "${wsfhmAddress}" "${reserve.address}" "${treasury.address}" "${daoAddress}" "${zeroAddress}" "${usdbMinterAddress}" "${fhmCirculatingSupply}" "${stakingStakingAddress}"`);
    }
}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
    })
