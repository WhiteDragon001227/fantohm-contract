// @dev. This script will deploy this V1.1 of Olympus. It will deploy the whole ecosystem except for the LP tokens and their bonds. 
// This should be enough of a test environment to learn about and test implementations with the Olympus as of V1.1.
// Not that the every instance of the Treasury's function 'valueOf' has been changed to 'valueOfToken'... 
// This solidity function was conflicting w js object property name

const { ethers } = require("hardhat");

async function main() {

    let [deployer, MockDAO] = await ethers.getSigners();
    // FIXME hack
    MockDAO = deployer;
    console.log('Deploying contracts with the account: ' + deployer.address);

    // Initial staking index
    const initialIndex = '7675210820';

    // First block epoch occurs
    const firstEpochBlock = '20187783';

    // What epoch will be first epoch
    const firstEpochNumber = '0';

    // How many blocks are in each epoch
    const epochLengthInBlocks = '28800';

    // Initial reward rate for epoch
    const initialRewardRate = '3000';

    // Ethereum 0 address, used when toggling changes in treasury
    const zeroAddress = '0x0000000000000000000000000000000000000000';

    // Large number for approval for Frax and DAI
    const largeApproval = '100000000000000000000000000000000';

    // Initial mint for Frax and DAI (10,000,000)
    const initialMint = '10000000000000000000000000';

    // DAI bond BCV
    const daiBondBCV = '369';

    // Frax bond BCV
    const fraxBondBCV = '690';

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
    const intialBondDebt = '0'

    // Deploy OHM 0x3381e86306145b062ced14790b01ac5384d23d82
    // const OHM = await ethers.getContractFactory('FantohmERC20Token');
    // const ohm = await OHM.deploy();

    // Deploy DAI
    // const DAI = await ethers.getContractFactory('DAI');
    // const dai = await DAI.deploy( 0 );

    // Deploy Frax
    // const Frax = await ethers.getContractFactory('FRAX');
    // const frax = await Frax.deploy( 0 );

    // Deploy 10,000,000 mock DAI and mock Frax
    // await dai.mint( deployer.address, initialMint );
    // await frax.mint( deployer.address, initialMint );

    // Deploy treasury 0xA3b52d5A6d2f8932a5cD921e09DA840092349D71
    //@dev changed function in treaury from 'valueOf' to 'valueOfToken'... solidity function was coflicting w js object property name
    // const Treasury = await ethers.getContractFactory('FantohmTreasury');
    // const treasury = await Treasury.deploy( '0xfa1FBb8Ef55A4855E5688C0eE13aC3f202486286', '0x82f0B8B456c1A451378467398982d4834b6829c1', 0 );

    // Deploy bonding calc 0xf7595d3D87D976CA011E89Ca6A95e827E31Dd581
    // const OlympusBondingCalculator = await ethers.getContractFactory('FantohmBondingCalculator');
    // const olympusBondingCalculator = await OlympusBondingCalculator.deploy( '0xfa1FBb8Ef55A4855E5688C0eE13aC3f202486286' );

    // Deploy staking distributor 0xCD12666f754aCefa1ee5477fA809911bAB915aa0
    // const Distributor = await ethers.getContractFactory('Distributor');
    // const distributor = await Distributor.deploy('0xA3b52d5A6d2f8932a5cD921e09DA840092349D71', '0xfa1FBb8Ef55A4855E5688C0eE13aC3f202486286', epochLengthInBlocks, firstEpochBlock);

    // Deploy sOHM 0x5E983ff70DE345de15DbDCf0529640F14446cDfa
    // const SOHM = await ethers.getContractFactory('sFantohm');
    // const sOHM = await SOHM.deploy();

    // Deploy Staking 0xcb9297425C889A7CbBaa5d3DB97bAb4Ea54829c2
    // const Staking = await ethers.getContractFactory('FantohmStaking');
    // const staking = await Staking.deploy( '0xfa1FBb8Ef55A4855E5688C0eE13aC3f202486286', '0x5E983ff70DE345de15DbDCf0529640F14446cDfa', epochLengthInBlocks, firstEpochNumber, firstEpochBlock );

    // Deploy staking warmpup 0x0265e9fEA16431C84BF3916276cA64102e19b356
    // const StakingWarmpup = await ethers.getContractFactory('StakingWarmup');
    // const stakingWarmup = await StakingWarmpup.deploy('0xcb9297425C889A7CbBaa5d3DB97bAb4Ea54829c2', '0x5E983ff70DE345de15DbDCf0529640F14446cDfa');

    // Deploy staking helper 0x068e87aa1eABEBBad65378Ede4B5C16E75e5a671
    // const StakingHelper = await ethers.getContractFactory('StakingHelper');
    // const stakingHelper = await StakingHelper.deploy('0xcb9297425C889A7CbBaa5d3DB97bAb4Ea54829c2', '0xfa1FBb8Ef55A4855E5688C0eE13aC3f202486286');

    // Deploy MIM bond: 0xD4B8A4E823923Ac6f57E457615a57f41E09B5613
    // const Depository = await ethers.getContractFactory('FantohmBondDepository');
    // const depository = await Depository.deploy('0xfa1FBb8Ef55A4855E5688C0eE13aC3f202486286', '0x82f0B8B456c1A451378467398982d4834b6829c1', '0xA3b52d5A6d2f8932a5cD921e09DA840092349D71', '0xD4aC626A1F87b5955f78FF86237DB055e62D43a0', zeroAddress);

    // Deploy Frax bond
    //@dev changed function call to Treasury of 'valueOf' to 'valueOfToken' in BondDepository due to change in Treausry contract
    // const FraxBond = await ethers.getContractFactory('MockOlympusBondDepository');
    // const fraxBond = await FraxBond.deploy(ohm.address, frax.address, treasury.address, MockDAO.address, zeroAddress);

    // queue and toggle DAI and Frax bond reserve depositor
    // await treasury.queue('0', daiBond.address);
    // await treasury.queue('0', fraxBond.address);
    // await treasury.toggle('0', daiBond.address, zeroAddress);
    // await treasury.toggle('0', fraxBond.address, zeroAddress);

    // Set DAI and Frax bond terms
    // await daiBond.initializeBondTerms(daiBondBCV, bondVestingLength, minBondPrice, maxBondPayout, bondFee, maxBondDebt, intialBondDebt);
    // await fraxBond.initializeBondTerms(fraxBondBCV, bondVestingLength, minBondPrice, maxBondPayout, bondFee, maxBondDebt, intialBondDebt);

    // Set staking for DAI and Frax bond
    // await daiBond.setStaking(staking.address, stakingHelper.address);
    // await fraxBond.setStaking(staking.address, stakingHelper.address);

    // Initialize sOHM and set the index
    // await sOHM.initialize(staking.address);
    // await sOHM.setIndex(initialIndex);

    // set distributor contract and warmup contract
    // await staking.setContract('0', distributor.address);
    // await staking.setContract('1', stakingWarmup.address);

    // Set treasury for OHM token
    // await ohm.setVault(treasury.address);

    // Add staking contract as distributor recipient
    // await distributor.addRecipient(staking.address, initialRewardRate);

    // queue and toggle reward manager
    // await treasury.queue('8', distributor.address);
    // await treasury.toggle('8', distributor.address, zeroAddress);

    // queue and toggle deployer reserve depositor
    // await treasury.queue('0', deployer.address);
    // await treasury.toggle('0', deployer.address, zeroAddress);

    // queue and toggle liquidity depositor
    // await treasury.queue('4', deployer.address, );
    // await treasury.toggle('4', deployer.address, zeroAddress);

    // Approve the treasury to spend DAI and Frax
    // await dai.approve(treasury.address, largeApproval );
    // await frax.approve(treasury.address, largeApproval );

    // Approve dai and frax bonds to spend deployer's DAI and Frax
    // await dai.approve(daiBond.address, largeApproval );
    // await frax.approve(fraxBond.address, largeApproval );

    // Approve staking and staking helper contact to spend deployer's OHM
    // await ohm.approve(staking.address, largeApproval);
    // await ohm.approve(stakingHelper.address, largeApproval);

    // Deposit 9,000,000 DAI to treasury, 600,000 OHM gets minted to deployer and 8,400,000 are in treasury as excesss reserves
    // await treasury.deposit('9000000000000000000000000', dai.address, '8400000000000000');

    // Deposit 5,000,000 Frax to treasury, all is profit and goes as excess reserves
    // await treasury.deposit('5000000000000000000000000', frax.address, '5000000000000000');

    // Stake OHM through helper
    // await stakingHelper.stake('100000000000');

    // Bond 1,000 OHM and Frax in each of their bonds
    // await daiBond.deposit('1000000000000000000000', '60000', deployer.address );
    // await fraxBond.deposit('1000000000000000000000', '60000', deployer.address );


    // OHMCirculatingSupplyContract 0xD6034108E056a74a355E6f8425773FBBA548f99E
    // const OHMCirculatingSupplyContract = await ethers.getContractFactory('OHMCirculatingSupplyContract');
    // const supplyContract = await OHMCirculatingSupplyContract.deploy('0x3381e86306145b062cEd14790b01AC5384D23D82');
    // console.log(supplyContract.address);

    // // RedeemHelper 0xF709c33F84Da692f76F035e51EE660a456196A67
    // const RedeemHelper = await ethers.getContractFactory('RedeemHelper');
    // const redeemHelper = await RedeemHelper.deploy();
    // console.log(redeemHelper.address);


    // console.log( "OHM: " + ohm.address );
    // console.log( "DAI: " + dai.address );
    // console.log( "Frax: " + frax.address );
    // console.log( "Treasury: " + treasury.address );
    // console.log( "Calc: " + olympusBondingCalculator.address );
    // console.log( "Staking: " + staking.address );
    // console.log( "sOHM: " + sOHM.address );
    // console.log( "Distributor " + distributor.address);
    // console.log( "Staking Wawrmup " + stakingWarmup.address);
    // console.log( "Staking Helper " + stakingHelper.address);
    // console.log("MIM Bond: " + depository.address);
    // console.log("Frax Bond: " + fraxBond.address);
}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
})
