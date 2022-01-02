// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IsFHM {
    function balanceForGons(uint gons) external view returns (uint);

    function gonsForBalance(uint amount) external view returns (uint);
}

interface IRewardsHolder {
    function newTick() external;
}

// FIXME test rebase
// FIXME voting token
// FIXME borrowing
contract StakingStaking is Ownable, AccessControl, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using SafeMath for uint;

    bytes32 public constant BORROWER_ROLE = keccak256("BORROWER_ROLE");

    address public immutable sFHM;
    address public immutable DAO;
    address public rewardsHolder;
    uint public noFeeBlocks; // 30 days in blocks
    uint public unstakeFee; // 100 means 1%
    uint public claimPageSize; // maximum iteration threshold

    // actual number of gons staking, which is user staking pool
    uint public totalGonsStaking;
    // staked token mapping in time of gons write
    uint public totalSfhmStaking;
    // actual number of gons transferred during sample ticks which were not claimed to any user, which is rewards pool
    uint public totalGonsPendingClaim;
    // staked token mapping in time of gons write
    uint public totalSfhmPendingClaim;
    // actual number of gons borrowed
    uint public totalGonsBorrowed;
    // staked token mapping in time of gons write
    uint public totalSfhmBorrowed;

    bool public disableContracts;
    bool public pauseNewStakes;
    bool public useWhitelist;
    bool public enableEmergencyWithdraw;
    bool private initCalled;

    // data structure holding info about all stakers
    struct UserInfo {
        uint gonsStaked; // absolute number of gons user is staking or rewarded
        uint sfhmStaked; // staked tokens mapping in time of gons write

        uint gonsBorrowed; // absolute number of gons user agains user has borrowed something
        uint sfhmBorrowed; // staked tokens mapping in time of gons write

        uint lastStakeBlockNumber; // time of last stake from which is counting noFeeDuration
        uint lastClaimIndex; // index in rewardSamples last claimed

        mapping(address => uint) allowances;
    }

    // data structure holding info about all rewards gathered during time
    struct SampleInfo {
        uint blockNumber; // time of newSample tick
        uint timestamp; // time of newSample tick as unix timestamp

        uint totalGonsRewarded; // absolute number of gons transferred during newSample
        uint totalSfhmRewarded; // staked tokens mapping in time of gons write

        uint gonsTvl; // gons supply staking contract is holding from which rewards will be dispersed
        uint sfhmTvl; // staked tokens mapping in time of gons write
    }

    mapping(address => bool) public whitelist;

    mapping(address => UserInfo) public userInfo;

    SampleInfo[] public rewardSamples;

    //
    // ----------- events -----------
    //

    event StakingDeposited(address indexed wallet, uint gonsStaked, uint sfhmStaked, uint lastStakeBlockNumber);
    event StakingWithdraw(address indexed wallet, uint gonsUnstaked, uint sfhmUnstaked, uint gonsTransferred, uint sfhmTransferred, uint unstakeBlock);
    event RewardSampled(uint blockNumber, uint blockTimestamp, uint gonsRewarded, uint sfhmRewarded);
    event RewardClaimed(address indexed wallet, uint indexed startClaimIndex, uint indexed lastClaimIndex, uint gonsClaimed, uint sfhmClaimed);
    event BorrowApproved(address indexed owner, address indexed spender, uint value);
    event Borrowed(address indexed wallet, address indexed spender, uint gonsBorrowed, uint sfhmBorrowed, uint blockNumber);
    event BorrowReturned(address indexed wallet, address indexed spender, uint gonsReturned, uint sfhmReturned, uint blockNumber);
    event BorrowLiquidated(address indexed wallet, address indexed spender, uint gonsLiquidated, uint sfhmLiquidated, uint blockNumber);
    event EmergencyTokenRecovered(address indexed token, address indexed recipient, uint amount);
    event EmergencyRewardsWithdraw(address indexed recipient, uint gonsRewarded, uint sfhmRewarded);
    event EmergencyEthRecovered(address indexed recipient, uint amount);

    constructor(address _sFHM, address _DAO) {
        sFHM = _sFHM;
        DAO = _DAO;
        initCalled = false;
    }

    //
    // suggested values:
    // _noFeeBlocks - 30 days in blocks
    // _unstakeFee - 3000 aka 30%
    // _claimPageSize - 100/1000
    // _disableContracts - true
    // _useWhitelist - false (we can set it when we will test on production)
    // _pauseNewStakes - false (you can set as some emergency leave precaution)
    // _enableEmergencyWithdraw - false (you can set as some emergency leave precaution)
    function init(address _rewardsHolder, uint _noFeeBlocks, uint _unstakeFee, uint _claimPageSize, bool _disableContracts, bool _useWhitelist, bool _pauseNewStakes, bool _enableEmergencyWithdraw) public onlyOwner {
        rewardsHolder = _rewardsHolder;
        noFeeBlocks = _noFeeBlocks;
        unstakeFee = _unstakeFee;
        claimPageSize = _claimPageSize;
        disableContracts = _disableContracts;
        useWhitelist = _useWhitelist;
        pauseNewStakes = _pauseNewStakes;
        enableEmergencyWithdraw = _enableEmergencyWithdraw;

        if (!initCalled) {
            newSample(0);
            initCalled = true;
        }
    }

    function modifyWhitelist(address user, bool add) external {
        if (add) {
            require(!whitelist[user], "Already in whitelist");
            whitelist[user] = true;
        } else {
            require(whitelist[user], "Not in whitelist");
            delete whitelist[user];
        }
    }

    //
    // fail fast stake/unstake for well known conditions
    //
    function checkBefore(bool stake) private {
        // whether to disable contracts to call staking pool
        if (disableContracts) require(msg.sender == tx.origin, "Contracts are not allowed here");

        // temporary disable new stakes, but allow to call claim and unstake
        require(!(pauseNewStakes && stake), "New staking is paused!");

        // allow only whitelisted contracts
        if (useWhitelist) require(whitelist[msg.sender], "User isn't in whitelist!");
    }

    //
    // --- operations of 2 gons by converting into balance, doing operation and converting again to gons with its balance in unionm ---
    //

    function gonsAdd(uint gonsA, uint gonsB) private view returns (uint, uint) {
        uint balance = balanceForGons(gonsA).add(balanceForGons(gonsB));
        return (gonsForBalance(balance), balance);
    }

    function gonsSub(uint gonsA, uint gonsB) private view returns (uint, uint) {
        uint balance = balanceForGons(gonsA).sub(balanceForGons(gonsB));
        return (gonsForBalance(balance), balance);
    }

    function gonsDiv(uint gonsA, uint gonsB) private view returns (uint, uint) {
        uint balance = balanceForGons(gonsA).div(balanceForGons(gonsB));
        return (gonsForBalance(balance), balance);
    }

    function gonsMul(uint gonsA, uint gonsB) private view returns (uint, uint) {
        uint balance = balanceForGons(gonsA).mul(balanceForGons(gonsB));
        return (gonsForBalance(balance), balance);
    }

    //
    // Insert _amount to the pool, add to your share, need to claim everything before new stake
    //
    function stake(uint _amount) external nonReentrant {
        doClaim(msg.sender, claimPageSize);

        // unsure that user claim everything before stake again
        require(userInfo[msg.sender].lastClaimIndex == rewardSamples.length - 1, "Cannot stake if not claimed everything");

        // erc20 transfer of staked tokens
        IERC20(sFHM).safeTransferFrom(msg.sender, address(this), _amount);
        uint gonsToStake = gonsForBalance(_amount);

        (uint gonsStaked,uint sfhmStaked) = gonsAdd(userInfo[msg.sender].gonsStaked, gonsToStake);

        // persist it
        UserInfo storage info = userInfo[msg.sender];
        info.gonsStaked = gonsStaked;
        info.sfhmStaked = sfhmStaked;
        info.lastStakeBlockNumber = block.number;

        (totalGonsStaking, totalSfhmStaking) = gonsAdd(totalGonsStaking, gonsToStake);

        // and record in history
        emit StakingDeposited(msg.sender,
            userInfo[msg.sender].gonsStaked,
            userInfo[msg.sender].sfhmStaked,
            userInfo[msg.sender].lastStakeBlockNumber);
    }

    //
    // Return current TVL of staking contract
    //
    function totalValueLocked() public view returns (uint, uint) {
        return gonsAdd(totalGonsStaking, totalGonsPendingClaim);
    }

    //
    // Return user balance
    // 1 - gonsStaked, 2 - sfhmStaked, 3 - gonsWithdrawable, 4 - sfhmWithdrawable, 5 - gonsBorrowed, 6 - sfhmBorrowed
    //
    function userBalance(address _user) public view returns (uint, uint, uint, uint, uint, uint) {
        UserInfo storage info = userInfo[_user];

        // count amount to withdraw from staked gons except borrowed gons
        (uint gonsToWithdraw, uint sfhmToWithdraw) = (0, 0);
        if (info.gonsStaked >= info.gonsBorrowed) {
            (gonsToWithdraw, sfhmToWithdraw) = gonsSub(info.gonsStaked, info.gonsBorrowed);
        }

        (uint gonsWithdrawable, uint sfhmWithdrawable) = getWithdrawableBalance(info.lastStakeBlockNumber, gonsToWithdraw);

        return (info.gonsStaked, info.sfhmStaked, gonsWithdrawable, sfhmWithdrawable, info.gonsBorrowed, info.sfhmBorrowed);
    }

    function getWithdrawableBalance(uint lastStakeBlockNumber, uint _gons) private view returns (uint, uint) {
        uint balanceWithdrawable = balanceForGons(_gons);
        if (block.number < lastStakeBlockNumber.add(noFeeBlocks)) {
            uint fee = balanceWithdrawable.mul(unstakeFee).div(10 ** 4);
            balanceWithdrawable = balanceWithdrawable.sub(fee);
        }
        return (gonsForBalance(balanceWithdrawable), balanceWithdrawable);
    }

    //
    // Rewards holder accumulated enough balance during its period to create new sample
    // Record our current staking TVL
    //
    function newSample(uint _balance) public {
        // transfer balance from rewards holder
        if (_balance > 0) IERC20(sFHM).safeTransferFrom(msg.sender, address(this), _balance);
        uint gonsRewarded = gonsForBalance(_balance);
        uint sfhmRewarded = balanceForGons(gonsRewarded);

        (uint gonsTvl, uint sfhmTvl) = totalValueLocked();

        rewardSamples.push(SampleInfo({
        // remember time data
        blockNumber : block.number,
        timestamp : block.timestamp,

        // rewards size
        totalGonsRewarded : gonsRewarded,
        totalSfhmRewarded : sfhmRewarded,

        // holders snapshot based on staking and pending claim gons
        gonsTvl : gonsTvl,
        sfhmTvl : sfhmTvl
        }));

        // count total value to be claimed
        (totalGonsPendingClaim, totalSfhmPendingClaim) = gonsAdd(totalGonsPendingClaim, gonsRewarded);

        // and record in history
        emit RewardSampled(block.number, block.timestamp, gonsRewarded, sfhmRewarded);
    }

    function balanceForGons(uint gons) private view returns (uint) {
        return IsFHM(sFHM).balanceForGons(gons);
    }

    function gonsForBalance(uint balance) private view returns (uint) {
        return IsFHM(sFHM).gonsForBalance(balance);
    }

    function claim(uint _claimPageSize) external nonReentrant {
        doClaim(msg.sender, _claimPageSize);
    }

    //
    // Claim unprocessed rewards to belong to userInfo staking amount with possibility to choose _claimPageSize
    //
    function doClaim(address _user, uint _claimPageSize) private {
        checkBefore(false);

        // clock new tick
        IRewardsHolder(rewardsHolder).newTick();

        UserInfo storage info = userInfo[msg.sender];

        uint lastClaimIndex = info.lastClaimIndex;
        // last item already claimed
        if (lastClaimIndex == rewardSamples.length - 1) return;

        // start claiming with gons staking previously
        uint gonsStaked = info.gonsStaked;
        uint sfhmStaked = info.sfhmStaked;
        uint allGonsClaimed = 0;
        uint allSfhmClaimed = 0;
        uint startIndex = lastClaimIndex + 1;

        // new user considered as claimed last sample
        if (info.lastStakeBlockNumber == 0) {
            lastClaimIndex = rewardSamples.length - 1;
        } else {
            // page size is either _claimPageSize or the rest
            uint endIndex = Math.min(lastClaimIndex + _claimPageSize, rewardSamples.length - 1);

            for (uint i = startIndex; i <= endIndex; i++) {
                lastClaimIndex = i;

                // compute share from current TVL, which means not yet claimed rewards are _counted_ to the APY
                if (gonsStaked > 0) {
                    uint gonsClaimed = 0;
                    uint sfhmClaimed = 0;
                    if (rewardSamples[i].gonsTvl > 0) {
                        // 40 * 10 / 20000
                        (uint gonsShare, uint sfhmShare) = gonsAdd(gonsStaked, allGonsClaimed);
                        (uint gons, uint sfhm) = gonsMul(rewardSamples[i].totalGonsRewarded, gonsShare);
                        (gonsClaimed, sfhmClaimed) = gonsDiv(gons, rewardSamples[i].gonsTvl);
                    }

                    (allGonsClaimed, allSfhmClaimed) = gonsAdd(allGonsClaimed, gonsClaimed);
                }
            }
        }

        // persist it
        (gonsStaked, sfhmStaked) = gonsAdd(gonsStaked, allGonsClaimed);
        info.gonsStaked = gonsStaked;
        info.sfhmStaked = sfhmStaked;
        info.lastClaimIndex = lastClaimIndex;

        (totalGonsStaking, totalSfhmStaking) = gonsAdd(totalGonsStaking, allGonsClaimed);
        // remove it from total balance if is not last one
        if (totalGonsPendingClaim >= allGonsClaimed) {
            (totalGonsPendingClaim, totalSfhmPendingClaim) = gonsSub(totalGonsPendingClaim, allGonsClaimed);
        } else {
            // sfhm balance of last one is the same, so gons should be rounded
            require(balanceForGons(totalGonsPendingClaim) == allSfhmClaimed, "Last user claiming needs balance");
            (totalGonsPendingClaim, totalSfhmPendingClaim) = (0, 0);
        }

        // and record in history
        emit RewardClaimed(msg.sender, startIndex, lastClaimIndex, allGonsClaimed, allSfhmClaimed);
    }

    //
    // Unstake _amount from staking pool. Automatically call claim.
    //
    function unstake(uint _amount) external nonReentrant {
        // auto claim before unstake
        doClaim(msg.sender, claimPageSize);

        UserInfo storage info = userInfo[msg.sender];

        // unsure that user claim everything before unstaking
        require(info.lastClaimIndex == rewardSamples.length - 1, "Cannot unstake if not claimed everything");

        // count amount to withdraw from staked gons except borrowed gons
        (uint gonsToUnstake, uint sfhmToUnstake) = (0, 0);
        if (info.gonsStaked >= info.gonsBorrowed) {
            (gonsToUnstake, sfhmToUnstake) = gonsSub(info.gonsStaked, info.gonsBorrowed);
        } else {
            // sfhm balance of last one is the same, so gons should be rounded
            require(balanceForGons(info.gonsStaked) == balanceForGons(info.gonsBorrowed), "Staked less than borrowed against");
            (gonsToUnstake, sfhmToUnstake) = (0, 0);
        }

        (uint gonsTransferring, uint sfhmTransferring) = getWithdrawableBalance(info.lastStakeBlockNumber, gonsToUnstake);
        // cannot unstake what is not mine
        require(gonsToUnstake <= info.gonsStaked, "Not enough tokens to unstake");
        // and more than we have
        require(gonsTransferring <= totalGonsStaking, "Unstaking more than in pool");

        (info.gonsStaked, info.sfhmStaked) = gonsSub(info.gonsStaked, gonsToUnstake);
        if (info.gonsStaked == 0) {
            // if unstaking everything just delete whole record
            delete userInfo[msg.sender];
        }

        // remove it from total balance
        if (totalGonsStaking >= gonsToUnstake) {
            (totalGonsStaking, totalSfhmStaking) = gonsSub(totalGonsStaking, gonsToUnstake);
        } else {
            // sfhm balance of last one is the same, so gons should be rounded
            require(balanceForGons(totalGonsStaking) == balanceForGons(gonsToUnstake), "Last user unstake needs balance");
            (totalGonsStaking, totalSfhmStaking) = (0, 0);
        }

        // actual erc20 transfer
        IERC20(sFHM).safeTransfer(msg.sender, sfhmTransferring);

        // and send fee to DAO
        (uint gonsFee,uint sfhmFee) = gonsSub(gonsToUnstake, gonsTransferring);
        IERC20(sFHM).safeTransfer(DAO, sfhmFee);

        // and record in history
        emit StakingWithdraw(msg.sender, gonsToUnstake, balanceForGons(gonsToUnstake), gonsTransferring, sfhmTransferring, block.number);
    }

    //
    // ----------- borrowing functions -----------
    //

    //
    // approve _spender to do anything with _amount of tokens for current caller user
    //
    function approve(address _spender, uint _amount) external {
        address user = msg.sender;
        UserInfo storage info = userInfo[user];
        info.allowances[_spender] = _amount;

        emit BorrowApproved(user, _spender, _amount);
    }

    //
    // check approve result, how much is approved for _owner and arbitrary _spender
    //
    function allowance(address _owner, address _spender) public view returns (uint) {
        UserInfo storage info = userInfo[_owner];
        return info.allowances[_spender];
    }

    //
    // allow to borrow asset against sFHM collateral which are staking in this pool.
    // You are able to borrow up to usd worth of staked + claimed tokens
    //
    function borrow(address _user, uint _amount) external {
        require(hasRole(BORROWER_ROLE, msg.sender), "Caller needs to have borrower role");

        // temporary disable borrows, but allow to call returnBorrow
        require(!pauseNewStakes, "New borrowing is paused!");

        uint approved = allowance(_user, msg.sender);
        require(gonsForBalance(approved) >= gonsForBalance(_amount), "Not enough allowance");

        // auto claim before borrow
        // but don't enforce to be claimed all
        doClaim(_user, claimPageSize);

        UserInfo storage info = userInfo[_user];

        uint gonsToBorrow = gonsForBalance(_amount);
        (info.gonsBorrowed, info.sfhmBorrowed) = gonsAdd(info.gonsBorrowed, gonsToBorrow);

        // cannot borrow what is not mine
        require(info.gonsBorrowed <= info.gonsStaked, "Not enough tokens to borrow");
        // and more than we have staking or claimed
        (uint gonsAvailableToBorrow, uint sfhmAvailableToBorrow) = gonsSub(totalGonsStaking, totalGonsBorrowed);
        require(gonsToBorrow <= gonsAvailableToBorrow, "Borrowing more than in pool");

        // add it from total balance
        (totalGonsBorrowed, totalSfhmBorrowed) = gonsAdd(totalGonsBorrowed, gonsToBorrow);

        require(totalGonsBorrowed <= totalGonsStaking, "Borrowing more than in pool");

        // erc20 transfer of staked tokens
        IERC20(sFHM).safeTransfer(msg.sender, _amount);

        // and record in history
        emit Borrowed(_user, msg.sender, gonsToBorrow, balanceForGons(gonsToBorrow), block.number);
    }

    //
    // return borrowed staked tokens
    //
    function returnBorrow(address _user, uint _amount) external {
        require(hasRole(BORROWER_ROLE, msg.sender), "Caller needs to have borrower role");

        // erc20 transfer of staked tokens
        IERC20(sFHM).safeTransferFrom(msg.sender, address(this), _amount);

        // auto claim returnBorrow borrow
        // but don't enforce to be claimed all
        doClaim(_user, claimPageSize);

        UserInfo storage info = userInfo[_user];

        uint gonsToReturn = gonsForBalance(_amount);
        // return less then borrow this turn
        if (info.gonsBorrowed >= gonsToReturn) {
            (info.gonsBorrowed, info.sfhmBorrowed) = gonsSub(info.gonsBorrowed, gonsToReturn);
        }
        // repay all plus give profit back
        else {
            (uint gonsToStake, uint sfhmToStake) = gonsSub(gonsToReturn, info.gonsBorrowed);
            (info.gonsStaked, info.sfhmStaked) = gonsAdd(info.gonsStaked, gonsToStake);
            (totalGonsStaking, totalSfhmStaking) = gonsAdd(totalGonsStaking, gonsToStake);
        }

        // subtract it from total balance
        if (totalGonsBorrowed > gonsToReturn) {
            (totalGonsBorrowed, totalSfhmBorrowed) = gonsSub(totalGonsBorrowed, gonsToReturn);
        } else {
            (totalGonsBorrowed, totalSfhmBorrowed) = (0, 0);
        }

        // and record in history
        emit BorrowReturned(_user, msg.sender, gonsToReturn, balanceForGons(gonsToReturn), block.number);
    }

    //
    // liquidation of borrowed staked tokens
    //
    function liquidateBorrow(address _user, uint _amount) external {
        require(hasRole(BORROWER_ROLE, msg.sender), "Caller needs to have borrower role");

        // auto claim returnBorrow borrow
        // but don't enforce to be claimed all
        doClaim(_user, claimPageSize);

        UserInfo storage info = userInfo[_user];

        uint gonsToLiquidate = gonsForBalance(_amount);
        // liquidate less or equal then borrow this turn
        if (info.gonsBorrowed >= gonsToLiquidate) {
            (info.gonsBorrowed, info.sfhmBorrowed) = gonsSub(info.gonsBorrowed, gonsToLiquidate);
        }
        // liquidate all plus take a loss
        else {
            (uint gonsToTakeLoss, uint sfhmToTakeLoss) = gonsSub(gonsToLiquidate, info.gonsBorrowed);
            if (info.gonsStaked > gonsToTakeLoss) {
                (info.gonsStaked, info.sfhmStaked) = gonsSub(info.gonsStaked, gonsToTakeLoss);
            } else {
                (info.gonsStaked, info.sfhmStaked) = (0, 0);
            }
            if (totalGonsStaking > gonsToTakeLoss) {
                (totalGonsStaking, totalSfhmStaking) = gonsSub(totalGonsStaking, gonsToTakeLoss);
            } else {
                (totalGonsStaking, totalSfhmStaking) = (0, 0);
            }
        }

        // subtract it from total balance
        if (totalGonsBorrowed > gonsToLiquidate) {
            (totalGonsBorrowed, totalSfhmBorrowed) = gonsSub(totalGonsBorrowed, gonsToLiquidate);
        } else {
            (totalGonsBorrowed, totalSfhmBorrowed) = (0, 0);
        }

        // and record in history
        emit BorrowLiquidated(_user, msg.sender, gonsToLiquidate, balanceForGons(gonsToLiquidate), block.number);
    }

    //
    // ----------- emergency functions -----------
    //

    //
    // emergency withdraw of user holding
    //
    function emergencyWithdraw() external {
        require(enableEmergencyWithdraw, "Emergency withdraw is not enabled");

        UserInfo storage info = userInfo[msg.sender];

        (uint gonsToWithdraw, uint sfhmToWithdraw) = gonsSub(info.gonsStaked, info.gonsBorrowed);

        // clear the data
        (info.gonsStaked, info.sfhmStaked) = (0, 0);

        // repair total values
        if (totalGonsStaking >= gonsToWithdraw) {
            (totalGonsStaking, totalSfhmStaking) = gonsSub(totalGonsStaking, gonsToWithdraw);
        } else {
            // sfhm balance of last one is the same, so gons should be rounded
            require(balanceForGons(totalGonsStaking) == balanceForGons(gonsToWithdraw), "Last user emergency withdraw needs balance");
            (totalGonsStaking, totalSfhmStaking) = (0, 0);
        }

        // erc20 transfer
        IERC20(sFHM).safeTransfer(msg.sender, sfhmToWithdraw);

        // and record in history
        emit StakingWithdraw(msg.sender, gonsToWithdraw, sfhmToWithdraw, gonsToWithdraw, sfhmToWithdraw, block.number);
    }

    function emergencyWithdrawRewards() external onlyOwner {
        require(enableEmergencyWithdraw, "Emergency withdraw is not enabled");

        // repair total values
        uint sfhmAmount = balanceForGons(totalGonsPendingClaim);
        totalGonsPendingClaim = 0;
        totalSfhmPendingClaim = 0;

        // erc20 transfer
        IERC20(sFHM).safeTransfer(DAO, sfhmAmount);

        emit EmergencyRewardsWithdraw(DAO, totalGonsPendingClaim, sfhmAmount);
    }

    //
    // Been able to recover any token which is sent to contract by mistake
    //
    function emergencyRecoverToken(address token) external virtual onlyOwner {
        require(token != sFHM);

        uint amount = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(DAO, amount);

        emit EmergencyTokenRecovered(token, DAO, amount);
    }

    //
    // Been able to recover any ftm/movr token sent to contract by mistake
    //
    function emergencyRecoverEth() external virtual onlyOwner {
        uint amount = address(this).balance;

        payable(DAO).transfer(amount);

        emit EmergencyEthRecovered(DAO, amount);
    }

}
