const {ethers} = require("hardhat");

async function main() {

    let [deployer] = await ethers.getSigners();
    console.log('Deploying contracts with the account: ' + deployer.address);

    // const network = "rinkeby";
    const network = "fantom_testnet";
    const {
        daoAddress,
        zeroAddress,
        daiAddress,
        usdbAddress,
        fhmAddress,
        sfhmAddress,
        treasuryAddress,
        stakingWarmupManagerAddress,
        usdbMinterAddress,
        fhmCirculatingSupply
    } = require(`../networks-${network}.json`);

    // Reserve addresses
    const reserves = [
        // {
        //     name: 'DAI',
        //     address: daiAddress,
        //     bondBCV: '10000',
        //     depositAmount: '100000000000000000000000',
        //     depositProfit: '0',
        // },
        {
            name: 'USDB',
            address: usdbAddress,
            bondBCV: '10000',
            depositAmount: '100000000000000000000000',
            depositProfit: '0',
        },
    ];

    // Large number for approval for reserve tokens
    const largeApproval = '100000000000000000000000000000000';

    // Bond vesting length in blocks. 33110 ~ 5 days
    const bondVestingLength = '8640'; // FTM testnet
    // const bondVestingLength = '498300'; // FTM mainnet
    // const bondVestingLength = '29400'; // MOVR?

    // Min bond price
    const minBondPrice = '2000';

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
        const Bond = await ethers.getContractFactory('FantohmBondStakingDepository');
        // const bond = await Bond.attach("0xd96f833613b4a85c26D870f71F0450E07dc6Efc9");
        const bond = await Bond.deploy(fhmAddress, sfhmAddress, reserve.address, treasury.address, daoAddress, zeroAddress, usdbMinterAddress, fhmCirculatingSupply);
        await bond.deployed();
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
        await bond.setStaking(stakingWarmupManagerAddress);
        console.log(`Set Staking for ${reserve.name} Bond`);

        // Approve the treasury to spend deployer's reserve tokens
        await reserveToken.approve(treasury.address, largeApproval);
        console.log(`Approved treasury to spend deployer ${reserve.name}`);

        // Approve bonds to spend deployer's reserve tokens
        await reserveToken.approve(bond.address, largeApproval);
        console.log(`Approved bond to spend deployer ${reserve.name}`);

        await bond.deposit('1000000000000000000000', '60000', deployer.address);
        console.log(`Deposited from deployer to Bond address: ${bond.address}`);

        // DONE
        console.log(`${reserve.name} Bond: "${reserveToken.address}",`);

        console.log(`\nVerify:\nnpx hardhat verify --network ${network} `+
                    `${bond.address} "${fhmAddress}" "${sfhmAddress}" "${reserve.address}" "${treasury.address}" "${daoAddress}" "${zeroAddress}" "${usdbMinterAddress}" "${fhmCirculatingSupply}"`);
    }
}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
    })
