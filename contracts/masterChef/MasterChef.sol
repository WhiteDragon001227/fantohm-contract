// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;
pragma abicoder v2;

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

interface IFHUDMinter {
    function getMarketPrice() external view returns (uint);
}

interface IMintable {
    function mint(address to, uint256 amount) external;
}

interface IBurnable {
    function burn(uint256 amount) external;
}

struct JoinPoolRequest {
    address[] assets;
    uint256[] maxAmountsIn;
    bytes userData;
    bool fromInternalBalance;
}

struct ExitPoolRequest {
    address[] assets;
    uint256[] minAmountsOut;
    bytes userData;
    bool toInternalBalance;
}

interface IVault {

    /**
     * @dev Called by users to join a Pool, which transfers tokens from `sender` into the Pool's balance. This will
     * trigger custom Pool behavior, which will typically grant something in return to `recipient` - often tokenized
     * Pool shares.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `assets` and `maxAmountsIn` arrays must have the same length, and each entry indicates the maximum amount
     * to send for each asset. The amounts to send are decided by the Pool and not the Vault: it just enforces
     * these maximums.
     *
     * If joining a Pool that holds WETH, it is possible to send ETH directly: the Vault will do the wrapping. To enable
     * this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead of the
     * WETH address. Note that it is not possible to combine ETH and WETH in the same join. Any excess ETH will be sent
     * back to the caller (not the sender, which is important for relayers).
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If sending ETH however, the array must be
     * sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the final
     * `assets` array might not be sorted. Pools with no registered tokens cannot be joined.
     *
     * If `fromInternalBalance` is true, the caller's Internal Balance will be preferred: ERC20 transfers will only
     * be made for the difference between the requested amount and Internal Balance (if any). Note that ETH cannot be
     * withdrawn from Internal Balance: attempting to do so will trigger a revert.
     *
     * This causes the Vault to call the `IBasePool.onJoinPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares). This can be encoded in the `userData` argument, which is ignored by the Vault and passed
     * directly to the Pool's contract, as is `recipient`.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    /**
     * @dev Called by users to exit a Pool, which transfers tokens from the Pool's balance to `recipient`. This will
     * trigger custom Pool behavior, which will typically ask for something in return from `sender` - often tokenized
     * Pool shares. The amount of tokens that can be withdrawn is limited by the Pool's `cash` balance (see
     * `getPoolTokenInfo`).
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `tokens` and `minAmountsOut` arrays must have the same length, and each entry in these indicates the minimum
     * token amount to receive for each token contract. The amounts to send are decided by the Pool and not the Vault:
     * it just enforces these minimums.
     *
     * If exiting a Pool that holds WETH, it is possible to receive ETH directly: the Vault will do the unwrapping. To
     * enable this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead
     * of the WETH address. Note that it is not possible to combine ETH and WETH in the same exit.
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If receiving ETH however, the array must
     * be sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the
     * final `assets` array might not be sorted. Pools with no registered tokens cannot be exited.
     *
     * If `toInternalBalance` is true, the tokens will be deposited to `recipient`'s Internal Balance. Otherwise,
     * an ERC20 transfer will be performed. Note that ETH cannot be deposited to Internal Balance: attempting to
     * do so will trigger a revert.
     *
     * `minAmountsOut` is the minimum amount of tokens the user expects to get out of the Pool, for each token in the
     * `tokens` array. This array must match the Pool's registered tokens.
     *
     * This causes the Vault to call the `IBasePool.onExitPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares to return). This can be encoded in the `userData` argument, which is ignored by the Vault and
     * passed directly to the Pool's contract.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;


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
    // Dev address.
    address public devaddr;
    // LQDR tokens created per block.
    uint public fhmPerBlock;
    // Bonus muliplier for early FHM makers.
    uint public constant BONUS_MULTIPLIER = 1;
    // Deposit Fee address
    address public feeAddress;

    address public immutable fhud; // FIXME init
    address public immutable treasury; // FIXME init
    address public immutable fhudMinter; // FIXME init
    address public immutable balancerVault; // FIXME init

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
    event SetDevAddress(address indexed user, address indexed newAddress);
    event UpdateEmissionRate(address indexed user, uint fhmPerBlock);

    constructor(
        IERC20 _fhm,
        address _devaddr,
        address _feeAddress,
        uint _fhmPerBlock,
        uint _startBlock
    ) public {
        fhm = _fhm;
        devaddr = _devaddr;
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

    // Update the given pool's LQDR allocation point and deposit fee. Can only be called by the owner.
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
    function pendingLqdr(uint _pid, address _user) external view returns (uint) {
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
        // FIMXE mint with treasury
        fhm.mint(devaddr, fhmReward.div(12));
        fhm.mint(address(this), fhmReward);
        pool.accFhmPerShare = pool.accFhmPerShare.add(fhmReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for FHM allocation.
    function deposit(uint _pid, uint _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
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
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint _pid, uint _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
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
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
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

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
        emit SetDevAddress(msg.sender, _devaddr);
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

    /// @notice https://medium.com/coinmonks/sorting-in-solidity-without-comparison-4eb47e04ff0d
    function insertSort(address[] memory data) internal pure {
        uint length = data.length;
        for (uint i = 1; i < length; i++) {
            uint key = data[i];
            uint j = i - 1;
            while ((int(j) >= 0) && (data[j] > key)) {
                data[j + 1] = data[j];
                j--;
            }
            data[j + 1] = key;
        }
    }

    function getMarketPrice() public view returns (uint _marketPrice) {
        _marketPrice = IFHUDMinter(fhudMinter).getMarketPrice();
    }

    function joinPool(uint _pid, address _lpToken, address _principle, uint _amount) external nonReentrant returns (uint _lpTokenAmount) {
        // FIXME transferFrom msg.sender amount of token to this contract, so its here
        require(_amount > 0.01 ether, "MIN_TOKENS");

        // FIXME fhud mint should go to the bond source code
        uint fhmValue = _amount.mul(10**2).div(getMarketPrice());
        ITreasury(treasury).mintRewards(address(this), fhmValue);
        IMintable(fhud).mint(address(this), _amount);
        IBurnable(fhm).burn(fhmValue);

        IERC20(fhud).safeApprove(balancerVault, _amount);
        IERC20(_principle).safeApprove(balancerVault, _amount);

        // https://dev.balancer.fi/resources/joins-and-exits/pool-joins
        address[] memory tokens = [fhud, _principle];
        insertSort(tokens);
        uint[] calldata rawAmounts = [_amount, _amount];
        bytes calldata userDataEncoded = abi.encode(1 /* EXACT_TOKENS_IN_FOR_BPT_OUT */, rawAmounts, 0);

        JoinPoolRequest calldata request = JoinPoolRequest({
            assets: tokens,
            maxAmountsIn: userDataEncoded,
            userData: userDataEncoded,
            fromInternalBalance: false
        });

        uint tokensBefore = IERC20(_lpToken).balanceOf(address(this));
        IVault(balancerVault).joinPool(_pid, address(this), address(this), request);
        uint tokensAfter = IERC20(_lpToken).balanceOf(address(this));

        _lpTokenAmount = tokensAfter.sub(tokensBefore);
    }

    function exitPool(uint _pid, address _lpToken, address _principle, uint _amount) external nonReentrant returns (uint _fhudAmount, uint _principleAmount) {
        IERC20(_lpToken).safeApprove(balancerVault, _amount);

        // https://dev.balancer.fi/resources/joins-and-exits/pool-exits
        address[] memory tokens = [fhud, _principle];
        insertSort(tokens);

        bytes calldata userDataEncoded = abi.encode(1 /* EXACT_BPT_IN_FOR_TOKENS_OUT */, _amount);

        ExitPoolRequest calldata request = ExitPoolRequest({
            assets: tokens,
            minAmountsOut: [0, 0],
            userData: userDataEncoded,
            toInternalBalance: false
        });

        uint fhudBefore = IERC20(fhud).balanceOf(address(this));
        uint principleBefore = IERC20(_principle).balanceOf(address(this));
        IVault(balancerVault).exitPool(_pid, address(this), address(this), request);
        uint fhudAfter = IERC20(fhud).balanceOf(address(this));
        uint principleAfter = IERC20(_principle).balanceOf(address(this));

        _fhudAmount = fhudAfter.sub(fhudBefore);
        _principleAmount = principleAfter.sub(principleBefore);
    }
}