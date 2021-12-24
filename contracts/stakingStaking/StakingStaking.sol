// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IOwnable {
    function policy() external view returns (address);

    function renounceManagement() external;

    function pushManagement(address newOwner_) external;

    function pullManagement() external;
}

contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed(address(0), _owner);
    }

    function policy() public view override returns (address) {
        return _owner;
    }

    modifier onlyPolicy() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceManagement() public virtual override onlyPolicy() {
        emit OwnershipPushed(_owner, address(0));
        _owner = address(0);
    }

    function pushManagement(address newOwner_) public virtual override onlyPolicy() {
        require(newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipPushed(_owner, newOwner_);
        _newOwner = newOwner_;
    }

    function pullManagement() public virtual override {
        require(msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled(_owner, _newOwner);
        _owner = _newOwner;
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}


library Address {

    function isContract(address account) internal view returns (bool) {

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {size := extcodesize(account)}
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value : value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function addressToString(address _address) internal pure returns (string memory) {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _addr = new bytes(42);

        _addr[0] = '0';
        _addr[1] = 'x';

        for (uint256 i = 0; i < 20; i++) {
            _addr[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _addr[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }

        return string(_addr);

    }
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract ERC20 is IERC20 {

    using SafeMath for uint256;

    // TODO comment actual hash value.
    bytes32 constant private ERC20TOKEN_ERC1820_INTERFACE_ID = keccak256("ERC20Token");

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _totalSupply;

    string internal _name;

    string internal _symbol;

    uint8 internal _decimals;

    constructor (string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account_, uint256 ammount_) internal virtual {
        require(account_ != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(this), account_, ammount_);
        _totalSupply = _totalSupply.add(ammount_);
        _balances[account_] = _balances[account_].add(ammount_);
        emit Transfer(address(this), account_, ammount_);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from_, address to_, uint256 amount_) internal virtual {}
}

interface IERC2612Permit {

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);
}

library Counters {
    using SafeMath for uint256;

    struct Counter {

        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

abstract contract ERC20Permit is ERC20, IERC2612Permit {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    bytes32 public DOMAIN_SEPARATOR;

    constructor() {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name())),
                keccak256(bytes("1")), // Version
                chainID,
                address(this)
            )
        );
    }

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "Permit: expired deadline");

        bytes32 hashStruct =
        keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, _nonces[owner].current(), deadline));

        bytes32 _hash = keccak256(abi.encodePacked(uint16(0x1901), DOMAIN_SEPARATOR, hashStruct));

        address signer = ecrecover(_hash, v, r, s);
        require(signer != address(0) && signer == owner, "ZeroSwapPermit: Invalid signature");

        _nonces[owner].increment();
        _approve(owner, spender, amount);
    }

    function nonces(address owner) public view override returns (uint256) {
        return _nonces[owner].current();
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {

        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library FullMath {
    function fullMul(uint256 x, uint256 y) private pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, uint256(- 1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & - d;
        d /= pow2;
        l /= pow2;
        l += h * ((- pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);
        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;
        require(h < d, 'FullMath::mulDiv: overflow');
        return fullDiv(l, h, d);
    }
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IsFHM {
    function balanceForGons(uint gons) external view returns (uint);

    function gonsForBalance(uint amount) external view returns (uint);
}

interface IRewardsHolder {
    function newTick() external;
}

// FIXME voting token
contract StakingStaking is Ownable, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using SafeMath for uint;

    address public immutable sFHM;
    address public rewardsHolder;
    uint public noFeeBlocks; // 30 days in blocks
    uint public unstakeFee; // 100 means 1%
    uint public claimPageSize; // maximum iteration threshold

    // actual number of gons staking, which is user staking pool
    uint public gonsStaking;
    // staked token mapping in time of gons write
    uint public sfhmStaking;
    // actual number of gons transferred during sample ticks which were not claimed to any user, which is rewards pool
    uint public gonsPendingClaim;
    // staked token mapping in time of gons write
    uint public sfhmPendingClaim;

    bool public disableContracts;
    bool public pauseNewStakes;
    bool public useWhitelist;
    bool public enableEmergencyWithdraw;
    bool private initCalled;

    // data structure holding info about all stakers
    struct UserInfo {
        uint gonsStaked; // absolute number of gons user is staking or rewarded
        uint sfhmStaked; // staked tokens mapping in time of gons write

        uint lastStakeBlockNumber; // time of last stake from which is counting noFeeDuration
        uint lastClaimIndex; // index in rewardSamples last claimed
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
    event EmergencyTokenRecovered(address indexed token, address indexed recipient, uint amount);
    event EmergencyRewardsWithdraw(address indexed recipient, uint gonsRewarded, uint sfhmRewarded);
    event EmergencyEthRecovered(address indexed recipient, uint amount);

    constructor(address _sFHM) {
        sFHM = _sFHM;
        initCalled = false;
    }

    function init(address _rewardsHolder, uint _noFeeBlocks, uint _unstakeFee, uint _claimPageSize, bool _disableContracts, bool _useWhitelist, bool _pauseNewStakes, bool _enableEmergencyWithdraw) public onlyPolicy {
        rewardsHolder = _rewardsHolder;
        noFeeBlocks = _noFeeBlocks;
        unstakeFee = _unstakeFee;
        claimPageSize = _claimPageSize;
        disableContracts = _disableContracts;
        useWhitelist = _useWhitelist;
        pauseNewStakes = _pauseNewStakes;
        enableEmergencyWithdraw = _enableEmergencyWithdraw;

//        if (!initCalled) {
//            newSample(0);
//            initCalled = true;
//        }
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
    // Insert _amount to the pool, add to your share, need to claim everything before new stake
    //
    function stake(uint _amount) external nonReentrant {
        doClaim(claimPageSize);

        // unsure that user claim everything before stake again
        require(userInfo[msg.sender].lastClaimIndex == rewardSamples.length - 1, "Cannot stake if not claimed everything");

        // erc20 transfer of staked tokens
        IERC20(sFHM).safeTransferFrom(msg.sender, address(this), _amount);
        uint gonsToStake = gonsForBalance(_amount);
        uint sfhmToStake = balanceForGons(gonsToStake);

        uint gonsStaked = userInfo[msg.sender].gonsStaked.add(gonsToStake);
        uint sfhmStaked = balanceForGons(gonsStaked);

        // persist it
        userInfo[msg.sender] = UserInfo({
        gonsStaked : gonsStaked,
        sfhmStaked : sfhmStaked,
        lastStakeBlockNumber : block.number,

        // don't touch the rest
        lastClaimIndex : userInfo[msg.sender].lastClaimIndex
        });
        gonsStaking = gonsStaking.add(gonsToStake);
        sfhmStaking = sfhmStaking.add(sfhmToStake);

        // and record in history
        emit StakingDeposited(msg.sender,
            userInfo[msg.sender].gonsStaked,
            userInfo[msg.sender].sfhmStaked,
            userInfo[msg.sender].lastStakeBlockNumber);
    }

    //
    // Return current TVL of staking contract
    //
    function getTvl() public view returns (uint, uint) {
        return (gonsStaking.add(gonsPendingClaim), sfhmStaking.add(sfhmPendingClaim));
    }

    //
    // Return user balance
    // 1 - gonsStaked, 2 - sfhmStaked, 3 - gonsWithdrawable, 4 - sfhmWithdrawable
    //
    function getBalance(address _user) public view returns (uint, uint, uint, uint) {
        UserInfo storage info = userInfo[_user];

        uint gonsWithdrawable = getWithdrawableBalance(_user, info.lastStakeBlockNumber, info.gonsStaked);
        uint sfhmWithdrawable = balanceForGons(gonsWithdrawable);

        return (info.gonsStaked, info.sfhmStaked, gonsWithdrawable, sfhmWithdrawable);
    }


    function getWithdrawableBalance(address _user, uint lastStakeBlockNumber, uint _gons) private view returns (uint) {
        uint gonsWithdrawable = _gons;
        if (block.number < lastStakeBlockNumber.add(noFeeBlocks)) {
            uint fee = _gons.mul(unstakeFee).div(10 ** 5);
            gonsWithdrawable = gonsWithdrawable.sub(fee);
        }
        return gonsWithdrawable;
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

        // count current TVL
        (uint gonsTvl,uint sfhmTvl) = getTvl();

        rewardSamples.push(SampleInfo({
        // remember time data
        blockNumber : block.number,
        timestamp : block.timestamp,

        // rewards size
        totalGonsRewarded : gonsRewarded,
        totalSfhmRewarded : sfhmRewarded,

        // holders snapshot
        gonsTvl : gonsTvl,
        sfhmTvl : sfhmTvl
        }));

        // count total value to be claimed
        gonsPendingClaim = gonsPendingClaim.add(gonsRewarded);
        sfhmPendingClaim = balanceForGons(gonsPendingClaim);

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
        doClaim(_claimPageSize);
    }

    //
    // Claim unprocessed rewards to belong to userInfo staking amount with possibility to choose _claimPageSize
    //
    function doClaim(uint _claimPageSize) private {
        checkBefore(false);

        // clock new tick
//        IRewardsHolder(rewardsHolder).newTick();

        // new user cannot claim anything
        if (userInfo[msg.sender].lastClaimIndex == 0 || userInfo[msg.sender].gonsStaked == 0) return;

        uint indexStart = userInfo[msg.sender].lastClaimIndex;
        require(indexStart < rewardSamples.length, "Start index is not valid");
        // last item already claimed
        if (indexStart == rewardSamples.length - 1) return;

        // page size is either _claimPageSize or the rest
        uint length = Math.min(_claimPageSize, rewardSamples.length - indexStart);

        // count what to claim this batch
        uint gonsBefore = userInfo[msg.sender].gonsStaked;
        uint totalClaimed = 0;
        uint lastClaimIndex = indexStart;
        for (uint i = indexStart; i < length; i++) {
            uint currentGons = gonsBefore.add(totalClaimed);
            uint csGons = rewardSamples[i].gonsTvl;
            uint realShare = Math.min(currentGons, csGons);
            totalClaimed = totalClaimed.add(csGons.div(realShare));
            lastClaimIndex = i;
        }

        // persist it
        uint gonsStaked = userInfo[msg.sender].gonsStaked.add(totalClaimed);
        userInfo[msg.sender] = UserInfo({
        lastClaimIndex : lastClaimIndex,
        gonsStaked : gonsStaked,
        sfhmStaked : balanceForGons(gonsStaked),
        lastStakeBlockNumber : userInfo[msg.sender].lastStakeBlockNumber
        });

        // remove it from total balance
        gonsPendingClaim = gonsPendingClaim.sub(totalClaimed);
        sfhmPendingClaim = balanceForGons(gonsPendingClaim);

        // and record in history
        emit RewardClaimed(msg.sender, indexStart, lastClaimIndex, totalClaimed, balanceForGons(totalClaimed));
    }

    //
    // Unstake _amount from staking pool. Automatically call claim.
    //
    function unstake(uint _amount) external nonReentrant {
        // auto claim before unstake
        doClaim(claimPageSize);

        // unsure that user claim everything before unstaking
        require(userInfo[msg.sender].lastClaimIndex == rewardSamples.length - 1, "Cannot unstake if not claimed everything");

        uint gonsToUnstake = gonsForBalance(_amount);
        uint gonsTransferring = getWithdrawableBalance(msg.sender, userInfo[msg.sender].lastStakeBlockNumber, gonsToUnstake);
        // cannot unstake what is not mine
        require(gonsToUnstake <= userInfo[msg.sender].gonsStaked, "Not enough tokens to unstake");
        // and more than we have
        require(gonsTransferring <= gonsStaking, "Unstaking more than in pool");

        userInfo[msg.sender].gonsStaked = userInfo[msg.sender].gonsStaked.sub(gonsToUnstake);
        if (userInfo[msg.sender].gonsStaked == 0) {
            // if unstaking everything just delete whole record
            delete userInfo[msg.sender];
        } else {
            // otherwise get info about staking tokens
            userInfo[msg.sender].sfhmStaked = balanceForGons(userInfo[msg.sender].gonsStaked);
        }

        // remove it from total balance
        gonsStaking = gonsStaking.sub(gonsTransferring);
        sfhmStaking = balanceForGons(gonsStaking);

        // actual erc20 transfer
        uint sfhmTransferring = balanceForGons(gonsTransferring);
        IERC20(sFHM).safeTransfer(msg.sender, sfhmTransferring);

        // and record in history
        emit StakingWithdraw(msg.sender, gonsToUnstake, balanceForGons(gonsToUnstake), gonsTransferring, sfhmTransferring, block.number);
    }

    //
    // ----------- emergency functions -----------
    //

    //
    // emergency withdraw of user holding
    //
    function emergencyWithdraw() external {
        require(enableEmergencyWithdraw, "Emergency withdraw is not enabled");

        uint gonsToWithdraw = userInfo[msg.sender].gonsStaked;
        uint amount = balanceForGons(gonsToWithdraw);
        require(amount > 0, "Cannot withdraw empty wallet");

        // clear the data
        delete userInfo[msg.sender];

        // repair total values
        gonsStaking = gonsStaking.sub(gonsToWithdraw);
        sfhmStaking = balanceForGons(gonsStaking);

        // erc20 transfer
        IERC20(sFHM).safeTransfer(msg.sender, amount);

        // and record in history
        emit StakingWithdraw(msg.sender, gonsToWithdraw, amount, gonsToWithdraw, amount, block.number);
    }

    function emergencyWithdrawRewards() external onlyPolicy {
        require(enableEmergencyWithdraw, "Emergency withdraw is not enabled");

        // repair total values
        uint sfhmAmount = balanceForGons(gonsPendingClaim);
        gonsPendingClaim = 0;
        sfhmPendingClaim = 0;

        // erc20 transfer
        address recipient = msg.sender;
        IERC20(sFHM).safeTransfer(recipient, sfhmAmount);

        emit EmergencyRewardsWithdraw(recipient, gonsPendingClaim, sfhmAmount);
    }

    //
    // Been able to recover any token which is sent to contract by mistake
    //
    function emergencyRecoverToken(address token) external virtual onlyPolicy {
        require(token != sFHM);

        address recipient = policy();
        uint amount = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(recipient, amount);

        emit EmergencyTokenRecovered(token, recipient, amount);
    }

    //
    // Been able to recover any ftm/movr token sent to contract by mistake
    //
    function emergencyRecoverEth() external virtual onlyPolicy {
        address recipient = policy();
        uint amount = address(this).balance;

        payable(recipient).transfer(amount);

        emit EmergencyEthRecovered(recipient, amount);
    }

}
