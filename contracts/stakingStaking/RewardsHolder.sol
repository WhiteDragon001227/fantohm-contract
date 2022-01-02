// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IsFHM {
    function balanceForGons(uint gons) external view returns (uint);

    function gonsForBalance(uint amount) external view returns (uint);
}

interface IStaking {
    function stake(uint _amount, address _recipient) external returns (bool);

    function claim(address _recipient) external;
}

interface IStakingStaking {
    function newSample(uint _balance) external;
}

contract RewardsHolder is Ownable, ReentrancyGuard {
    using SafeMath for uint;

    address public immutable FHM;
    address public immutable sFHM;
    address public immutable staking;
    address public stakingStaking;

    // when was last sample transfer of rewards
    uint public lastSampleBlockNumber;
    // once for how many blocks is next sample made
    uint public blocksPerSample;

    event RewardSample(uint timestamp, uint blockNumber, uint gonsRewards, uint sfhmRewards);

    constructor(address _FHM, address _sFHM, address _staking) {
        FHM = _FHM;
        sFHM = _sFHM;
        staking = _staking;
    }

    function init(address _stakingStaking, uint _blocksPerSample) external onlyOwner {
        stakingStaking = _stakingStaking;
        blocksPerSample = _blocksPerSample;
    }

    function stake() private {
        // claim previous round from warmup
        IStaking(staking).claim(address(this));

        uint fhmRewards = IERC20(FHM).balanceOf(address(this));
        if (fhmRewards == 0) return;

        // stake new round for warmup
        IERC20(FHM).approve(staking, fhmRewards);
        IStaking(staking).stake(fhmRewards, address(this));
        // try to claim if using warmup period 0
        IStaking(staking).claim(address(this));
    }

    function newTick() public {
        stake();

        // not doing anything, waiting and gathering rewards
        if (lastSampleBlockNumber.add(blocksPerSample) > block.number) return;

        // perform new sample, remember staking pool supply back then

        // call new sample to transfer rewards
        uint sfhmRewards = IERC20(sFHM).balanceOf(address(this));
        uint gonsRewards = IsFHM(sFHM).gonsForBalance(sfhmRewards);
        IERC20(sFHM).approve(stakingStaking, sfhmRewards);
        IStakingStaking(stakingStaking).newSample(sfhmRewards);

        // remember last sample block
        lastSampleBlockNumber = block.number;

        // and record in history
        emit RewardSample(block.timestamp, block.number, gonsRewards, sfhmRewards);
    }
}
