// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

interface IStaking {

    function stake(uint _amount, address _recipient) external returns (bool);

    function claim(address _recipient) external;

    function rebase() external;

    function epoch() external view returns (uint,uint,uint,uint);

    function warmupPeriod() external view returns (uint);
}

interface IsFHM {
    function rebase(uint256 ohmProfit_, uint epoch_) external returns (uint256);

    function circulatingSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function gonsForBalance(uint amount) external view returns (uint);

    function balanceForGons(uint gons) external view returns (uint);

    function index() external view returns (uint);
}


/// @notice each % warmup period one executor is actually doing stakes and claims, others are waiting for warmupPeriod time to be able to claim,
/// @dev how to split % warmup period is not its responsibility, nor sending tokens to staking
contract StakingWarmupExecutor is Ownable, AccessControl {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 public constant STAKER_ROLE = keccak256("STAKER_ROLE");

    address public FHM;
    address public sFHM;
    address public staking;
    address public manager;

    uint public lastStakedEpochNumber;

    struct Claim {
        uint deposit;
        uint gons;
        uint expiry;
    }

    // here should be warmupPeriod times warmupInfos for each modulo
    mapping(address => Claim) public warmupInfos;

    event Staked(address _user, uint deposit, uint _gons, uint _expiry, uint _epoch);
    event Claimed(address _user, uint deposit, uint _gons, uint _expiry, uint _epoch);

    constructor(address _FHM, address _sFHM, address _staking, address _manager) {
        require(_FHM != address(0));
        FHM = _FHM;
        require(_sFHM != address(0));
        sFHM = _sFHM;
        require(_staking != address(0));
        staking = _staking;
        require(_manager != address(0));
        manager = _manager;

        _setupRole(STAKER_ROLE, msg.sender);
        _setupRole(STAKER_ROLE, manager);
    }

    function checkBefore(uint _amount, address _recipient) private view {
        require(hasRole(STAKER_ROLE, _msgSender()), "Must have staker role to stake or claim");
        require(_recipient != address(0));
        require(_amount != 0);
    }

    /// @notice stake for given original _recipient and claim rewards for former epoch
    /// @param _amount native token amount to stake
    /// @param _recipient original recipient, not a manager
    /// @return true
    function stake(uint _amount, address _recipient) external returns (bool) {
        checkBefore(_amount, _recipient);

        Claim storage info = warmupInfos[_recipient];

        uint epochNumber = getEpochNumber();
        // if can claim previous epoch do it now
        if (epochNumber <= info.expiry) claim(_recipient);

        // remember last stake for claim
        lastStakedEpochNumber = epochNumber;

        // persist original _recipient
        info.deposit = info.deposit.add(_amount);
        info.gons = info.gons.add(IsFHM(sFHM).gonsForBalance(_amount));
        info.expiry = epochNumber.add(IStaking(staking).warmupPeriod());

        IERC20(FHM).approve(staking, _amount);

        emit Staked(_recipient, info.deposit, info.gons, info.expiry, epochNumber);

        return IStaking(staking).stake(_amount, address(this));
    }

    /// @notice claim for original recipient
    /// @param _recipient original recipient, not a manager
    function claim(address _recipient) public {
        checkBefore(1, _recipient);

        uint epochNumber = getEpochNumber();
        uint warmupPeriod = IStaking(staking).warmupPeriod();

        // really can call claim which does something, claiming for everyone else
        if (epochNumber >= lastStakedEpochNumber.add(warmupPeriod)) {
            IStaking(staking).claim(address(this));
        }

        Claim storage info = warmupInfos[_recipient];

        // nothing to send or warmup expiring next turn not this turn
        if (info.gons == 0 || info.expiry > epochNumber) return;

        // delete info as it will already handled
        delete warmupInfos[_recipient];

        emit Claimed(_recipient, IsFHM(sFHM).balanceForGons(info.gons), info.gons, info.expiry, epochNumber);

        // transfer staked tokens to originating _recipient
        IERC20(sFHM).safeTransfer(_recipient, IsFHM(sFHM).balanceForGons(info.gons));
    }

    function getEpochNumber() public view returns (uint _epoch) {
        (,_epoch,,) = IStaking(staking).epoch();
    }

    /// @notice grants staker role to given _account
    /// @param _account staker contract
    function grantRoleStaker(address _account) external {
        grantRole(STAKER_ROLE, _account);
    }

    /// @notice revoke staker role to given _account
    /// @param _account staker contract
    function revokeRoleStaker(address _account) external {
        revokeRole(STAKER_ROLE, _account);
    }

}
