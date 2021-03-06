const {ethers} = require("hardhat");

// npx hardhat console --network rinkeby
// const ProjectX = await ethers.getContractFactory("TradFiBondDepository",{ libraries: { IterableMapping: "0x8fae7a5f94960e0b64e346918160f6276f232445" }})
// const projectX = await ProjectX.attach("0x65C0cA99697E1746A55DE416f7642234FCcDF778")
// npx hardhat verify --network rinkeby 0x52b27846dd773C8E16Fc8e75E2d1D6abd4e8C48A "0x9DC084Fd82860cDb4ED2b2BF59F1076F47B03Bd6" "0xE827c1D2da22496A09055140c2454c953710751C" "0xfa1FBb8Ef55A4855E5688C0eE13aC3f202486286" "0x686AcF5A89d09D936B09e5a5a64Dd6B241CD20c6" "0x3381e86306145b062cEd14790b01AC5384D23D82" "0x05db87C4Cbb198717F590AabA613cdD2180483Ce"

// npx hardhat console --network fantom_testnet
// const ProjectX = await ethers.getContractFactory("TradFiBondDepository",{ libraries: { IterableMapping: "0x1eFF5569aDBc45A7e15b3CC5701A93FF0ea8D761" }})
// const projectX = await ProjectX.attach("0x6f1d572B01fABA437297235f6D3C4e05Fb65eAfc")
// npx hardhat verify --network fantom_testnet 0x6f1d572B01fABA437297235f6D3C4e05Fb65eAfc "0x4B209fd2826e6880e9605DCAF5F8dB0C2296D6d2" "0xD40f6eDc014b42cF678D7eeF4A1310EEe229C50f" "0x05db87C4Cbb198717F590AabA613cdD2180483Ce" "0xB58E41fadf1bebC1089CeEDbbf7e5E5e46dCd9b9" "0x3381e86306145b062cEd14790b01AC5384D23D82" "0xc7330002761E52034efDC0cAe69B5Bd20D69aD38"

// npx hardhat console --network fantom
// const ProjectX = await ethers.getContractFactory("TradFiBondDepository",{ libraries: { IterableMapping: "0xc36b7E732A7DDbadF66f7d8B56b8E07e51bf42C7" }})
// const projectX = await ProjectX.attach("0x6f1d572B01fABA437297235f6D3C4e05Fb65eAfc")

// npx hardhat console --network mainnet
// const ProjectX = await ethers.getContractFactory("TradFiBondDepository",{ libraries: { IterableMapping: "0x728A9157ab70F3b42B34492A0eF1293BBDe374F7" }})
// const projectX = await ProjectX.attach("")


async function main() {

    let [deployer] = await ethers.getSigners();
    console.log('Deploying contracts with the account: ' + deployer.address);

    // const network = "rinkeby";
    // const network = "fantom_testnet";
    // const network = "fantom";
    const network = "ethereum_mainnet";
    const {
        daoAddress,
        zeroAddress,
        daiAddress,
        fhmAddress,
        usdbAddress,
        treasuryAddress,
        usdbMinterAddress,
    } = require(`../../networks-${network}.json`);

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
    // const bondVestingSecondsLength = '600';
    // const bondVestingSecondsLength = '1200';

    // const bondVestingSecondsLength = '7776000'; // 3m
    const bondVestingSecondsLength = '15552000'; // 6m

    // 6 weeks/2 = 3628800/2 * 0.867 = 1573084
    // const bondVestingLength = '10';
    // const bondVestingLength = '20';

    // const bondVestingLength = '3738461'; // 1/2 3m ftm
    // const bondVestingLength = '7476923';
    // const bondVestingLength = '299076'; // 1/2 3m eth
    const bondVestingLength = '598152';

    // const maxDiscount = '4762'; // 3m
    const maxDiscount = '13044'; //6m

    // Max bond payout
    const maxBondPayout = '100000'

    // DAO fee for bond
    const bondFee = '10000';

    // Max debt bond can take on
    const maxBondDebt = '50000000000000000000000';

    // Initial Bond debt
    const initialBondDebt = '0';

    // const soldBondsLimit = '300000000000000000000000'; // ftm
    const soldBondsLimit = '700000000000000000000000'; // eth

    const useWhitelist = false;
    const useCircuitBreaker = true;
    const prematureReturnRate = 9500;
    const limitBondAmount = 10;

    const Treasury = await ethers.getContractFactory('FantohmTreasury');
    const treasury = await Treasury.attach(treasuryAddress);

    // Get Reserve Token
    const ReserveToken = await ethers.getContractFactory('contracts/fwsFHM.sol:ERC20'); // Doesn't matter which ERC20
    const reserveToken = await ReserveToken.attach(reserve.address);

    const Library = await ethers.getContractFactory("IterableMapping");
    // const library = await Library.attach("0xc36b7E732A7DDbadF66f7d8B56b8E07e51bf42C7"); // prod
    // const library = await Library.attach("0xA6E6e8720C70f4715a34783381d6745a7aC32652"); // rinkeby
    // const library = await Library.attach("0x728A9157ab70F3b42B34492A0eF1293BBDe374F7"); // eth mainnet
    const library = await Library.deploy();
    await library.deployed();
    console.log(`Deployed library to: ${library.address}`);

    // Deploy Bond
    const Bond = await ethers.getContractFactory('TradFiBondDepository', {
        libraries: {
            IterableMapping: library.address,
        },
    });
    // const bond = await Bond.attach("0xD9fDd86ecc03e34DAf9c645C40DF670406836816");
    const bond = await Bond.deploy(fhmAddress, usdbAddress, reserve.address, treasury.address, daoAddress, usdbMinterAddress);
    await bond.deployed();
    console.log(`Deployed ${reserve.name} Bond to: ${bond.address}`);

    // queue and toggle bond reserve depositor
    await treasury.queue('8', bond.address);
    console.log(`Queued ${reserve.name} Bond as reward manager`);
    await treasury.toggle('8', bond.address, zeroAddress);
    console.log(`Toggled ${reserve.name} Bond as reward manager`);

    // Set bond terms
    await bond.initializeBondTerms(bondVestingSecondsLength, bondVestingLength, maxDiscount, maxBondPayout, bondFee, maxBondDebt, initialBondDebt, soldBondsLimit, useWhitelist, useCircuitBreaker, prematureReturnRate, limitBondAmount);
    console.log(`Initialized terms for ${reserve.name} Bond`);

    // Approve the treasury to spend deployer's reserve tokens
    await reserveToken.approve(treasury.address, largeApproval);
    console.log(`Approved treasury to spend deployer ${reserve.name}`);

    // Approve bonds to spend deployer's reserve tokens
    await reserveToken.approve(bond.address, largeApproval);
    console.log(`Approved bond to spend deployer ${reserve.name}`);

    const UsdbToken = await ethers.getContractFactory('USDB');
    const usdbToken = await UsdbToken.attach(usdbAddress);
    await usdbToken.grantRoleMinter(bond.address);
    console.log(`grant minter of USDB to ${bond.address}`);

    await bond.deposit('1000000000000000000000', '100', deployer.address);
    console.log(`Deposited from deployer to Bond address: ${bond.address}`);

    // DONE
    console.log(`${reserve.name} Bond: "${reserveToken.address}",`);

    console.log(`\nVerify:\nnpx hardhat verify --network ${network} `+
        `${bond.address} "${fhmAddress}" "${usdbAddress}" "${reserve.address}" "${treasuryAddress}" "${daoAddress}" "${usdbMinterAddress}"`);

    // redeemAll
    const pageSize = 1000;
    var count = await bond.usersCount();
    console.log("count: " + count);
    const min = (a, b) => (a < b ? a : b);
    for (var i = 0; i <= count / pageSize; i++) {
        const start = i * pageSize;
        const end = min(start + pageSize, count);
        console.log("start:" + start + ", end:" + end);
        var result = await bond.redeemAll(start, end);
        var num = result[0], indices = result[1];
        while (num > 0) {
            result = await bond.redeem(indices);
            num = result[0];
            indices = result[1];
        }
    }

}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
    })
