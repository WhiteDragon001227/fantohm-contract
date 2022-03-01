const { ethers } = require("hardhat");

async function main() {

	let [deployer] = await ethers.getSigners();
	console.log('Deploying contracts with the account: ' + deployer.address);

	const {
		zeroAddress,
		daiAddress,
		fhmAddress,
		fhudAddress,
		treasuryAddress,
		fhudMinterAddress,
		balancerVaultAddress,
		fhudDaiLpAddress,
	} = require('../networks-rinkeby.json');

	const daoAddress = deployer.address;
	// const daoAddress = "0x34F93b12cA2e13C6E64f45cFA36EABADD0bA30fC";

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

	// 6 weeks ~ 3628800
	// const bondVestingSecondsLength = '3628800';
	const bondVestingSecondsLength = '600';

	// 6 weeks/2 = 3628800/2 * 0.867 = 1573084
	// const bondVestingLength = '1573084';
	const bondVestingLengthSec = '100';
	const bondVestingLength = '10';

	const maxDiscount = '5000';

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

	const Library = await ethers.getContractFactory("IterableMappingSingleSided");
  	const library = await Library.deploy();
  	await library.deployed();
	// Deploy Bond
	const Bond = await ethers.getContractFactory('SingleSidedLPBondDepository', {
		libraries: {
			IterableMappingSingleSided: library.address,
		},
	});

	const bond = await Bond.deploy( fhmAddress, fhudAddress, reserve.address, treasury.address, daoAddress, fhudMinterAddress, balancerVaultAddress, fhudDaiLpAddress);
	// const bond = await Bond.attach( "0x9203e6F0E38e86a19CfECf496a2E07b3539B4924" );
	console.log(`Deployed ${reserve.name} Bond to: ${bond.address}`);

	// queue and toggle bond reserve depositor
	await treasury.queue('8', bond.address);
	console.log(`Queued ${reserve.name} Bond as reward manager`);
	await treasury.toggle('8', bond.address, zeroAddress);
	console.log(`Toggled ${reserve.name} Bond as reward manager`);

	// Set bond terms
	await bond.initializeBondTerms(bondVestingLengthSec, bondVestingLength, maxDiscount, maxBondPayout, bondFee, maxBondDebt, intialBondDebt, soldBondsLimit, useWhitelist, useCircuitBreaker);
	console.log(`Initialized terms for ${reserve.name} Bond`);

	// Approve the treasury to spend deployer's reserve tokens
	await reserveToken.approve(treasury.address, largeApproval );
	console.log(`Approved treasury to spend deployer ${reserve.name}`);
	//
	// Approve bonds to spend deployer's reserve tokens
	await reserveToken.approve(bond.address, largeApproval );
	console.log(`Approved bond to spend deployer ${reserve.name}`);

	const FhudToken = await ethers.getContractFactory('FHUD');
	const fhudToken = await FhudToken.attach(fhudAddress);
	await fhudToken.grantRole('0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6', bond.address);
	console.log(`grant minter of FHUD to ${bond.address}`);

	await bond.deposit('1000000000000000000000', '100', deployer.address );
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
