// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IMintable {
    function mint(address to, uint amount) external;
}

interface IBurnable {
    function burnFrom(address account, uint amount) external;
}

interface IBeetsMasterChef {
    function harvest(uint _pid, address _to) external;

    function deposit(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) external;

    function withdrawAndHarvest(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) external;
}

/// @notice Manager of sfBeets
/// @author pwntr0n
/// FIXME add b1 optional zap from beets or ftm
/// FIXME page size and stack rewards for some time
contract SfBeetsManager is Ownable, ReentrancyGuard {

    using SafeMath for uint;
    using SafeERC20 for IERC20;

    address public immutable beets;
    address public immutable fBeets;
    address public immutable sfBeets;
    address public immutable multisig;
    address public immutable beetsMasterChef;

    uint public pid; // mastechef pool id
    uint public fee; // service fee, 5% is 500
    bool public enableEmergencyWithdraw;

    /// @notice data structure holding info about all rewards gathered during time
    struct SampleInfo {
        uint blockNumber; // time of newSample tick
        uint timestamp; // time of newSample tick as unix timestamp

        uint totalRewarded; // absolute number of Beets transferred during newSample

        uint tvl; // sfBeets supply staking contract is holding from which rewards will be dispersed
    }

    SampleInfo[] public rewardSamples;

    struct UserInfo {
        uint staked; // absolute number of fBeets user deposited

        uint lastClaimIndex; // index in rewardSamples last claimed
    }

    mapping(address => UserInfo) public userInfo;

    /* ///////////////////////////////////////////////////////////////
                                EVENTS
    ////////////////////////////////////////////////////////////// */

    /// @notice deposit event
    /// @param _user user who triggered the deposit
    /// @param _value deposited wsFHM value
    event StakingDeposited(address indexed _user, uint _value);

    /// @notice withdraw event
    /// @param _user user who received the withdrawn tokens
    /// @param _value amount in fBeets token to be withdrawn
    /// @param _unstakeBlock block number of event generated
    event StakingWithdraw(address indexed _user, uint _value, uint _unstakeBlock);

    /// @notice new rewards were sampled and prepared for claim
    /// @param _blockNumber  block number of event generated
    /// @param _blockTimestamp  block timestamp of event generated
    /// @param _rewarded  block timestamp of event generated
    /// @param _tvl  sfBeets supply in the time of sample
    event RewardSampled(uint _blockNumber, uint _blockTimestamp, uint _rewarded, uint _tvl);

    /// @notice reward claimed during one claim() method
    /// @param _wallet  user who triggered the claim
    /// @param _startClaimIndex first rewards which were claimed
    /// @param _lastClaimIndex last rewards which were claimed
    /// @param _claimed how many wsFHM claimed
    event RewardClaimed(address indexed _wallet, uint indexed _startClaimIndex, uint indexed _lastClaimIndex, uint _claimed);

    /// @notice emergency token transferred
    /// @param _token ERC20 token
    /// @param _recipient recipient of transaction
    /// @param _amount token amount
    event EmergencyTokenRecovered(address indexed _token, address indexed _recipient, uint _amount);

    /// @notice emergency withdraw of unclaimed rewards
    /// @param _recipient recipient of transaction
    /// @param _rewarded beets amount of unclaimed rewards transferred
    event EmergencyRewardsWithdraw(address indexed _recipient, uint _rewarded);

    // @notice emergency withdraw of ETH
    /// @param _recipient recipient of transaction
    /// @param _amount ether value of transaction
    event EmergencyEthRecovered(address indexed _recipient, uint _amount);

    constructor(address _beets, address _fBeets, address _sfBeets, address _multisig, address _beetsMasterChef) {
        require(_beets != address(0));
        beets = _beets;
        require(_fBeets != address(0));
        fBeets = _fBeets;
        require(_sfBeets != address(0));
        sfBeets = _sfBeets;
        require(_multisig != address(0));
        multisig = _multisig;
        require(_beetsMasterChef != address(0));
        beetsMasterChef = _beetsMasterChef;
    }

    function setup(uint _pid, uint _fee, bool _enableEmergencyWithdraw) external onlyOwner {
        pid = _pid;
        fee = _fee;
        enableEmergencyWithdraw = _enableEmergencyWithdraw;
    }

    /// @notice deposit fBeets into SC to get sfBeets and beeing able to claim rewards
    /// @param _amount fBeets amount
    function deposit(uint _amount) external {
        // try claim anything
        doClaim();

        // add to staking amount
        UserInfo storage info = userInfo[msg.sender];
        info.staked = info.staked.add(_amount);

        if (_amount > 0) {
            // burn/mint if can
            IERC20(fBeets).safeTransferFrom(msg.sender, address(this), _amount);
            IMintable(sfBeets).mint(msg.sender, _amount);

            // deposit into masterchef
            // https://ftmscan.com/tx/0x44a223cc525fa2433e9021894f84e12fa2c267174e831ce6880c817044304e2c
            IERC20(fBeets).approve(beetsMasterChef, _amount);
            IBeetsMasterChef(beetsMasterChef).deposit(pid, _amount, address(this));
        }

        // and persist in history
        emit StakingDeposited(msg.sender, _amount);
    }

    /// @notice claim beets rewards from our fBeets pool in masterchef and send service fee to multisig
    function claimUpstream() public nonReentrant {
        doClaimUpstream();
    }

    function doClaimUpstream() private {
        uint beetsBefore = IERC20(beets).balanceOf(address(this));
        IBeetsMasterChef(beetsMasterChef).harvest(pid, address(this));
        uint beetsAfter = IERC20(beets).balanceOf(address(this));

        uint harvested = beetsAfter.sub(beetsBefore);
        if (harvested > 0) {
            uint serviceFeeAmount = harvested.mul(fee).div(10000);
            IERC20(beets).safeTransfer(multisig, serviceFeeAmount);

            uint totalRewarded = harvested.sub(serviceFeeAmount);
            uint tvl = IERC20(sfBeets).totalSupply();

            rewardSamples.push(SampleInfo({
            blockNumber : block.number,
            timestamp : block.timestamp,
            totalRewarded : totalRewarded,
            tvl : tvl
            }));

            emit RewardSampled(block.number, block.timestamp, totalRewarded, tvl);
        }
    }

    /// @notice claim/harvest rewards for given user
    /// @dev https://ftmscan.com/tx/0x2ceed357d8dd5ab713d404c4c4d2428c93d7a708ef38732d8a0b689dc2a11684
    function claim() external nonReentrant {
        doClaim();
    }

    function doClaim() private {
        // claim pending rewards
        doClaimUpstream();

        UserInfo storage info = userInfo[msg.sender];
        // already claimed last sample
        if (info.lastClaimIndex == rewardSamples.length - 1) return;

        // count from last claim to present
        uint amount = claimable(msg.sender);
        uint indexStart = info.lastClaimIndex;
        info.lastClaimIndex = rewardSamples.length - 1;

        // sent only if have something
        if (amount > 0) {
            IERC20(beets).safeTransfer(msg.sender, amount);
        }

        // and persist in history
        emit RewardClaimed(msg.sender, indexStart, rewardSamples.length - 1, amount);
    }

    function claimable(address _user) public view returns (uint _amount){
        UserInfo memory info = userInfo[_user];
        // already claimed last sample
        if (info.lastClaimIndex == rewardSamples.length - 1 || info.staked == 0) return 0;

        for (uint i = info.lastClaimIndex; i < rewardSamples.length; i++) {
            SampleInfo memory sample = rewardSamples[i];
            uint part = sample.totalRewarded.mul(info.staked).div(sample.tvl);
            _amount = _amount.add(part);
        }

        return _amount;
    }

    /// @notice withdraw fBeets and burn sfBeets
    /// @param _amount sfBeets amount
    /// @param _force if true do not harvest rewards, just withdraw it now
    function withdraw(uint _amount, bool _force) external nonReentrant {
        if (!_force) doClaim();

        // subtract from deposited amount
        UserInfo storage info = userInfo[msg.sender];
        if (_amount < info.staked) {
            info.staked = info.staked.sub(_amount);
        } else {
            info.staked = 0;
        }

        if (_amount > 0) {
            // withdraw from master chef
            IBeetsMasterChef(beetsMasterChef).withdrawAndHarvest(pid, _amount, address(this));

            // mint/burn if can do it
            IBurnable(sfBeets).burnFrom(msg.sender, _amount);
            IERC20(fBeets).safeTransferFrom(address(this), msg.sender, _amount);
        }

        // and persist in the history
        emit StakingWithdraw(msg.sender, _amount, block.number);
    }

    /* ///////////////////////////////////////////////////////////////
                               EMERGENCY FUNCTIONS
        ////////////////////////////////////////////////////////////// */

    /// @notice emergency withdraw of user holding
    function emergencyWithdraw() external {
        require(enableEmergencyWithdraw, "EMERGENCY_WITHDRAW_NOT_ENABLED");

        UserInfo storage info = userInfo[msg.sender];

        uint toWithdraw = info.staked;

        // clear the data
        info.staked = info.staked.sub(toWithdraw);

        // withdraw from master chef
        IBeetsMasterChef(beetsMasterChef).withdrawAndHarvest(pid, toWithdraw, address(this));

        // mint/burn if can do it
        IBurnable(sfBeets).burnFrom(msg.sender, toWithdraw);
        IERC20(fBeets).safeTransferFrom(address(this), msg.sender, toWithdraw);

        // and record in history
        emit StakingWithdraw(msg.sender, toWithdraw, block.number);
    }


    /// @dev Once called, any user who not claimed cannot claim/withdraw, should be used only in emergency.
    function emergencyWithdrawRewards() external onlyOwner {
        require(enableEmergencyWithdraw, "EMERGENCY_WITHDRAW_NOT_ENABLED");

        uint amount = IERC20(beets).balanceOf(address(this));

        // erc20 transfer
        IERC20(beets).safeTransfer(multisig, amount);

        emit EmergencyRewardsWithdraw(multisig, amount);
    }

    /// @notice Been able to recover any token which is sent to contract by mistake
    /// @param token erc20 token
    function emergencyRecoverToken(address token) external virtual onlyOwner {
        require(token != beets);

        uint amount = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(multisig, amount);

        emit EmergencyTokenRecovered(token, multisig, amount);
    }

    /// @notice Been able to recover any ftm/movr token sent to contract by mistake
    function emergencyRecoverEth() external virtual onlyOwner {
        uint amount = address(this).balance;

        payable(multisig).transfer(amount);

        emit EmergencyEthRecovered(multisig, amount);
    }

    /* ///////////////////////////////////////////////////////////////
                           RECEIVE ETHER LOGIC
   ////////////////////////////////////////////////////////////// */

    /// @dev Required for the Vault to receive unwrapped ETH.
    receive() external payable {}
}