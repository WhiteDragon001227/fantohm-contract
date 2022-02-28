// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface ITreasury {
    function deposit( uint _amount, address _token, uint _profit ) external returns ( uint send_ );
    function valueOf( address _token, uint _amount ) external view returns ( uint value_ );
    function mintRewards( address _recipient, uint _amount ) external;
}

// MasterChef is the master of FHM. He can make FHM and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once FHM is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChefV2 is Ownable, ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint amount;         // How many LP tokens the user has provided.
        uint rewardDebt;     // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of FHMs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accFhmPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accFhmPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint allocPoint;       // How many allocation points assigned to this pool. FHMs to distribute per block.
        uint lastRewardBlock;  // Last block number that FHMs distribution occurs.
        uint accFhmPerShare;   // Accumulated FHMs per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
    }

    // The FHM TOKEN!
    IERC20 public fhm;
    // Treasury address.
    address public treasuryAddress;
    // Fhm tokens created per block.
    uint public fhmPerBlock;
    // Bonus muliplier for early FHM makers.
    uint public constant BONUS_MULTIPLIER = 1;
    // Deposit Fee address
    address public feeAddress;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint public totalAllocPoint = 0;
    // The block number when FHM mining starts.
    uint public startBlock;

    event Deposit(address indexed user, uint indexed pid, uint amount);
    event Withdraw(address indexed user, uint indexed pid, uint amount);
    event EmergencyWithdraw(address indexed user, uint indexed pid, uint amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event SetTreasuryAddress( address indexed oldAddress, address indexed newAddress);
    event UpdateEmissionRate(address indexed user, uint fhmPerBlock);

    constructor(
        IERC20 _fhm,
        address _treasuryAddress,
        address _feeAddress,
        uint _fhmPerBlock,
        uint _startBlock
    ) public {
        fhm = _fhm;
        treasuryAddress = _treasuryAddress;
        feeAddress = _feeAddress;
        fhmPerBlock = _fhmPerBlock;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint) {
        return poolInfo.length;
    }

    mapping(IERC20 => bool) public poolExistence;
    modifier nonDuplicated(IERC20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint _allocPoint, IERC20 _lpToken, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner nonDuplicated(_lpToken) {
        require(_depositFeeBP <= 10000, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExistence[_lpToken] = true;
        poolInfo.push(PoolInfo({
        lpToken : _lpToken,
        allocPoint : _allocPoint,
        lastRewardBlock : lastRewardBlock,
        accFhmPerShare : 0,
        depositFeeBP : _depositFeeBP
        }));
    }

    // Update the given pool's Fhm allocation point and deposit fee. Can only be called by the owner.
    function set(uint _pid, uint _allocPoint, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= 10000, "set: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint _from, uint _to) public view returns (uint) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending FHMs on frontend.
    function pendingFhm(uint _pid, address _user) external view returns (uint) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint accFhmPerShare = pool.accFhmPerShare;
        uint lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint fhmReward = multiplier.mul(fhmPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accFhmPerShare = accFhmPerShare.add(fhmReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accFhmPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint length = poolInfo.length;
        for (uint pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint fhmReward = multiplier.mul(fhmPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
       //Mint Fhm rewards.
        ITreasury( treasuryAddress ).mintRewards( treasuryAddress, fhmReward.div(12) );
        ITreasury( treasuryAddress ).mintRewards( address(this), fhmReward );
        pool.accFhmPerShare = pool.accFhmPerShare.add(fhmReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for FHM allocation.
    function deposit(uint _pid, uint _amount, address _user) public onlyOwner nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        updatePool(_pid);
        if (user.amount > 0) {
            uint pending = user.amount.mul(pool.accFhmPerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                safeFhmTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            if (pool.depositFeeBP > 0) {
                uint depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
            } else {
                user.amount = user.amount.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accFhmPerShare).div(1e12);
        emit Deposit(_user, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint _pid, uint _amount, address _user) public onlyOwner nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint pending = user.amount.mul(pool.accFhmPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            safeFhmTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accFhmPerShare).div(1e12);
        emit Withdraw(_user, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint _pid, address _user) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(_user , _pid, amount);
    }

    // Safe FHM transfer function, just in case if rounding error causes pool to not have enough FHMs.
    function safeFhmTransfer(address _to, uint _amount) internal {
        uint fhmBal = fhm.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > fhmBal) {
            transferSuccess = fhm.transfer(_to, fhmBal);
        } else {
            transferSuccess = fhm.transfer(_to, _amount);
        }
        require(transferSuccess, "safeFHMTransfer: transfer failed");
    }

    // Update treasury address by the owner.
    function treasury(address _treasuryAddress) public onlyOwner {
        treasuryAddress = _treasuryAddress;
        emit SetTreasuryAddress(treasuryAddress, _treasuryAddress);
    }

    function setFeeAddress(address _feeAddress) public {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }

    //Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint _fhmPerBlock) public onlyOwner {
        massUpdatePools();
        fhmPerBlock = _fhmPerBlock;
        emit UpdateEmissionRate(msg.sender, _fhmPerBlock);
    }

}