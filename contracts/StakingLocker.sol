// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

interface IStaking {
    function stake( uint _amount, address _recipient ) external returns ( bool );

    function claim( address _recipient ) external;

    function giveLockBonus(uint _amount) external;

    function returnLockBonus(uint _amount) external;

}

contract StakingLocker is Ownable, AccessControl {

    using SafeERC20 for IERC20;

    bytes32 public constant REWARD_MANAGER = keccak256("REWARD_MANAGER");

    address public immutable FHM;
    address public immutable sFHM;
    address public immutable staking;

    constructor (address _FHM, address _sFHM, address _staking) {
        require(_FHM != address(0));
        FHM = _FHM;
        require(_sFHM != address(0));
        sFHM = _sFHM;
        require(_staking != address(0));
        staking = _staking;
    }

    function giveLockBonus(uint _amount) external {
        require(hasRole(REWARD_MANAGER, msg.sender), "Caller needs to have reward manager role");

        IStaking(staking).giveLockBonus(_amount);
        IERC20(sFHM).safeTransfer(msg.sender, _amount);
    }

    function returnLockBonus(uint _amount) external {
        require(hasRole(REWARD_MANAGER, msg.sender), "Caller needs to have reward manager role");

        IERC20(sFHM).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(sFHM).approve(staking, _amount);
        IStaking(staking).returnLockBonus(_amount);
    }

    //
    // ability to stake immediately
    //
    function stake(uint _amount, address _recipient) external {
        require(hasRole(REWARD_MANAGER, msg.sender), "Caller needs to have reward manager role");

        // claim any previous staking warmup
        IStaking(staking).claim(address(this));

        // transfer from caller and stake it with warmup period
        IERC20(FHM).safeTransferFrom(_recipient, address(this), _amount);
        IStaking(staking).stake(_amount, address(this));

        // give caller borrowed staked tokens immediately
        IStaking(staking).giveLockBonus(_amount);
        IERC20(sFHM).safeTransfer(_recipient, _amount);

        // return anything claimed back to the staking contract
        uint balance = IERC20(sFHM).balanceOf(address(this));
        IERC20(sFHM).approve(staking, balance);
        IStaking(staking).returnLockBonus(balance);
    }

    function claim( address _recipient ) external {
        require(hasRole(REWARD_MANAGER, msg.sender), "Caller needs to have reward manager role");

        // claim any previous staking warmup
        IStaking(staking).claim(address(this));

        // return anything claimed back to the staking contract
        uint balance = IERC20(sFHM).balanceOf(address(this));
        IERC20(sFHM).approve(staking, balance);
        IStaking(staking).returnLockBonus(balance);
    }
}
