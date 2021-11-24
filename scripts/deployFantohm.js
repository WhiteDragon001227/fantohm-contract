const { ethers } = require("hardhat");

async function main() {

    let [deployer, DAO] = await ethers.getSigners();
    console.log('Deploying contracts with the account: ' + deployer.address);
    console.log('Deploying contracts with the account: ' + DAO.address);

    // Initial staking index
    const initialIndex = '7675210820';

    // First block epoch occurs
    const firstEpochBlock = '1177162'; // MAKE SURE THIS MATCHES CHAIN

    // What epoch will be first epoch
    const firstEpochNumber = '0';

    // How many blocks are in each epoch
    const epochLengthInBlocks = '28800';

    // Initial reward rate for epoch
    const initialRewardRate = '3000';

    // Ethereum 0 address, used when toggling changes in treasury
    const zeroAddress = '0x0000000000000000000000000000000000000000';

    // Large number for approval for reserve tokens
    const largeApproval = '100000000000000000000000000000000';

    // Deploy FHM
    const FHM = await ethers.getContractFactory('FantohmERC20Token');
    const fhm = await FHM.deploy();
    console.log(`Deployed FHM to: ${fhm.address}`);

    // Deploy treasury
    const Treasury = await ethers.getContractFactory('FantohmTreasury');
    const treasury = await Treasury.deploy( fhm.address, 0 );
    console.log(`Deployed Treasury to: ${treasury.address}`);

    // Deploy bonding calc
    const FantohmBondingCalculator = await ethers.getContractFactory('FantohmBondingCalculator');
    const fantohmBondingCalculator = await FantohmBondingCalculator.deploy( fhm.address );
    console.log(`Deployed FantohmBondingCalculator to: ${fantohmBondingCalculator.address}`);

    // Deploy staking distributor
    const Distributor = await ethers.getContractFactory('Distributor');
    const distributor = await Distributor.deploy(treasury.address, fhm.address, epochLengthInBlocks, firstEpochBlock);
    console.log(`Deployed Distributor to: ${distributor.address}`);

    // Deploy sFHM
    const SFHM = await ethers.getContractFactory('sFantohm');
    const sFHM = await SFHM.deploy();
    console.log(`Deployed SFHM to: ${sFHM.address}`);

    // Deploy Staking
    const Staking = await ethers.getContractFactory('FantohmStaking');
    const staking = await Staking.deploy( fhm.address, sFHM.address, epochLengthInBlocks, firstEpochNumber, firstEpochBlock );
    console.log(`Deployed Staking to: ${staking.address}`);

    // Deploy staking warmpup
    const StakingWarmpup = await ethers.getContractFactory('StakingWarmup');
    const stakingWarmup = await StakingWarmpup.deploy( staking.address, sFHM.address );
    console.log(`Deployed StakingWarmpup to: ${stakingWarmup.address}`);

    // Deploy staking helper
    const StakingHelper = await ethers.getContractFactory('StakingHelper');
    const stakingHelper = await StakingHelper.deploy( staking.address, fhm.address );
    console.log(`Deployed StakingHelper to: ${stakingHelper.address}`);

    // Initialize sFHM and set the index
    await sFHM.initialize(staking.address);
    console.log('Initialized sFHM');
    await sFHM.setIndex(initialIndex);
    console.log('Set index for sFHM');

    // set distributor contract and warmup contract
    await staking.setContract('0', distributor.address);
    console.log('Set contract for staking for distributor');
    await staking.setContract('1', stakingWarmup.address);
    console.log('Set contract for staking for stakingWarmup');

    // Set treasury for FHM token
    await fhm.setVault(treasury.address);
    console.log('Set vault for fhm');

    // Add staking contract as distributor recipient
    await distributor.addRecipient(staking.address, initialRewardRate);
    console.log('Added recipient for distributor');

    // queue and toggle reward manager
    await treasury.queue('8', distributor.address);
    console.log('Queued distributor as reward manager for treasury');
    await treasury.toggle('8', distributor.address, zeroAddress);
    console.log('Toggled distributor as reward manager for treasury');

    // queue and toggle deployer reserve depositor
    await treasury.queue('0', deployer.address);
    console.log('Queued deployer as reserve depositor for treasury');
    await treasury.toggle('0', deployer.address, zeroAddress);
    console.log('Toggled deployer as reserve depositor for treasury');

    // queue and toggle liquidity depositor
    await treasury.queue('4', deployer.address, );
    console.log('Queued deployer as liquidity depositor for treasury');
    await treasury.toggle('4', deployer.address, zeroAddress);
    console.log('Toggled deployer as liquidity depositor for treasury');

    // Approve staking and staking helper contact to spend deployer's FHM
    await fhm.approve(staking.address, largeApproval);
    console.log('Approved staking to spend deployer FHM');
    await fhm.approve(stakingHelper.address, largeApproval);
    console.log('Approved stakingHelper to spend deployer FHM');

    // OHMCirculatingSupplyContract
    const OHMCirculatingSupplyContract = await ethers.getContractFactory('OHMCirculatingSupplyContract');
    const supplyContract = await OHMCirculatingSupplyContract.deploy(deployer.address);
    console.log(`Deployed SupplyContract to: ${supplyContract.address}`);
    await supplyContract.initialize(fhm.address);
    console.log('Initialized OHMCirculatingSupplyContract');

    // RedeemHelper
    const RedeemHelper = await ethers.getContractFactory('RedeemHelper');
    const redeemHelper = await RedeemHelper.deploy();
    console.log(`Deployed RedeemHelper to: ${redeemHelper.address}`);

    console.log( "DONE!" );
    console.log( "----------------------------------------" );
    console.log( "----------------------------------------" );
    console.log(`OHM_ADDRESS: "${fhm.address}",`);
    console.log(`STAKING_ADDRESS: "${staking.address}",`);
    console.log(`STAKING_HELPER_ADDRESS: "${stakingHelper.address}",`);
    console.log(`SOHM_ADDRESS: "${sFHM.address}",`);
    console.log(`DISTRIBUTOR_ADDRESS: "${distributor.address}",`);
    console.log(`BONDINGCALC_ADDRESS: "${fantohmBondingCalculator.address}",`);
    console.log(`CIRCULATING_SUPPLY_ADDRESS: "${supplyContract.address}",`);
    console.log(`TREASURY_ADDRESS: "${treasury.address}",`);
    console.log(`REDEEM_HELPER_ADDRESS: "${redeemHelper.address}",`);
    console.log(`DAO_ADDRESS: "${DAO.address}",`);
    console.log(`OLD_STAKING_ADDRESS: "${zeroAddress}",`);
    console.log(`OLD_SOHM_ADDRESS: "${zeroAddress}",`);
    console.log(`MIGRATE_ADDRESS: "${zeroAddress}",`);
    console.log(`PT_TOKEN_ADDRESS: "${zeroAddress}",`);
    console.log(`PT_PRIZE_POOL_ADDRESS: "${zeroAddress}",`);
    console.log(`PT_PRIZE_STRATEGY_ADDRESS: "${zeroAddress}",`);
}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
})
