// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import '@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/Initializable.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import "@openzeppelin/contracts/math/SafeMath.sol";
import './XERC20Upgradeable.sol';
import './Whitelist.sol';

library Math {
    uint256 public constant WAD = 10**18;

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    //rounds to zero if x*y < WAD / 2
    function wmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return ((x * y) + (WAD / 2)) / WAD;
    }
}

interface IXFhm is IXERC20 {
    function isUser(address _addr) external view returns (bool);

    function deposit(uint256 _amount) external;

    function claim() external;

    function withdraw(uint256 _amount) external;

    function getStakedFhm(address _addr) external view returns (uint256);

    function getVotes(address _account) external view returns (uint256);
}

interface IVotingEscrow {
    function balanceOfVotingToken(address _owner) external view returns (uint);
}

/// @title XFhm
/// @notice Fhm Venom: the staking contract for Fhm, as well as the token used for governance.
/// Note Venom does not seem to hurt the Fhm, it only makes it stronger.
/// Allows depositing/withdraw of fhm
/// Here are the rules of the game:
/// If you stake fhm, you generate xfhm at the current `generationRate` until you reach `maxCap`
/// If you unstake any amount of fhm, you loose all of your xfhm
/// Note that it's ownable and the owner wields tremendous power. The ownership
/// will be transferred to a governance smart contract once Fhm is sufficiently
/// distributed and the community can show to govern itself.
contract XFhm is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    XERC20Upgradeable,
    IXFhm,
    IVotingEscrow
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount; // FHM staked by user
        uint256 lastRelease; // time of last XFHM claim or first deposit if user has not claimed yet
    }

    /// @notice the fhm token
    IERC20 public fhm;

    /// @notice max xFhm to staked Fhm ratio
    /// Note if user has 10 fhm staked, they can only have a max of 10 * maxCap xFhm in balance
    uint256 public maxCap;

    /// @notice the rate of xFhm generated per second, per fhm staked
    uint256 public generationRate;

    /// @notice invVvoteThreshold threshold.
    /// @notice voteThreshold is the tercentage of cap from which votes starts to count for governance proposals.
    /// @dev inverse of the threshold to apply.
    /// Example: th = 5% => (1/5) * 100 => invVoteThreshold = 20
    /// Example 2: th = 3.03% => (1/3.03) * 100 => invVoteThreshold = 33
    /// Formula is invVoteThreshold = (1 / th) * 100
    uint256 public invVoteThreshold;

    /// @notice whitelist wallet checker
    /// @dev contract addresses are by default unable to stake fhm, they must be previously whitelisted to stake fhm
    Whitelist public whitelist;

    /// @notice user info mapping
    mapping(address => UserInfo) public users;

    /// @notice events describing staking, unstaking and claiming
    event Staked(address indexed user, uint256 indexed amount);
    event Unstaked(address indexed user, uint256 indexed amount);
    event Claimed(address indexed user, uint256 indexed amount);

    function initialize(
        IERC20 _fhm
    ) public initializer {
        require(address(_fhm) != address(0), 'zero address');

        // Initialize XFhm
        __ERC20_init('Fantohm Venom', 'XFhm');
        __Ownable_init();
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();

        // set generationRate (XFhm per sec per Fhm staked)
        generationRate = 100000;

        // set maxCap
        maxCap = 100;

        // set inv vote threshold
        // invVoteThreshold = 20 => th = 5
        invVoteThreshold = 20;

        // set Fhm
        fhm = _fhm;

    }

    /**
     * @dev pause pool, restricting certain operations
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev unpause pool, enabling certain operations
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice sets whitelist address
    /// @param _whitelist the new whitelist address
    function setWhitelist(Whitelist _whitelist) external onlyOwner {
        require(address(_whitelist) != address(0), 'zero address');
        whitelist = _whitelist;
    }

    /// @notice sets maxCap
    /// @param _maxCap the new max ratio
    function setMaxCap(uint256 _maxCap) external onlyOwner {
        require(_maxCap != 0, 'max cap cannot be zero');
        maxCap = _maxCap;
    }

    /// @notice sets generation rate
    /// @param _generationRate the new max ratio
    function setGenerationRate(uint256 _generationRate) external onlyOwner {
        require(_generationRate != 0, 'generation rate cannot be zero');
        generationRate = _generationRate;
    }

    /// @notice sets invVoteThreshold
    /// @param _invVoteThreshold the new var
    /// Formula is invVoteThreshold = (1 / th) * 100
    function setInvVoteThreshold(uint256 _invVoteThreshold) external onlyOwner {
        // onwner should set a high value if we do not want to implement an important threshold
        require(_invVoteThreshold != 0, 'invVoteThreshold cannot be zero');
        invVoteThreshold = _invVoteThreshold;
    }

    /// @notice checks wether user _addr has fhm staked
    /// @param _addr the user address to check
    /// @return true if the user has fhm in stake, false otherwise
    function isUser(address _addr) public view override returns (bool) {
        return users[_addr].amount > 0;
    }

    /// @notice returns staked amount of fhm for user
    /// @param _addr the user address to check
    /// @return staked amount of fhm
    function getStakedFhm(address _addr) external view override returns (uint256) {
        return users[_addr].amount;
    }

    /// @dev explicity override multiple inheritance
    function totalSupply() public view override(XERC20Upgradeable, IXERC20) returns (uint256) {
        return super.totalSupply();
    }

    /// @dev explicity override multiple inheritance
    function balanceOf(address account) public view override(XERC20Upgradeable, IXERC20) returns (uint256) {
        return super.balanceOf(account);
    }

    /// @notice deposits fhm into contract
    /// @param _amount the amount of fhm to deposit
    function deposit(uint256 _amount) external override nonReentrant whenNotPaused {
        require(_amount > 0, 'amount to deposit cannot be zero');

        // assert call is not coming from a smart contract
        // unless it is whitelisted
        _assertNotContract(msg.sender);

        if (isUser(msg.sender)) {
            // if user exists, first, claim his XFhm
            _claim(msg.sender);
            // then, increment his holdings
            users[msg.sender].amount = users[msg.sender].amount.add(_amount);
        } else {
            // add new user to mapping
            users[msg.sender].lastRelease = block.timestamp;
            users[msg.sender].amount = _amount;
        }

        // Request Fhm from user
        fhm.safeTransferFrom(msg.sender, address(this), _amount);

        emit Staked(msg.sender, _amount);
    }

    /// @notice asserts address in param is not a smart contract.
    /// @notice if it is a smart contract, check that it is whitelisted
    /// @param _addr the address to check
    function _assertNotContract(address _addr) private view {
        if (_addr != tx.origin) {
            require(
                address(whitelist) != address(0) && whitelist.check(_addr),
                'Smart contract depositors not allowed'
            );
        }
    }

    /// @notice claims accumulated xFhm
    function claim() external override nonReentrant whenNotPaused {
        require(isUser(msg.sender), 'user has no stake');
        _claim(msg.sender);
    }

    /// @dev private claim function
    /// @param _addr the address of the user to claim from
    function _claim(address _addr) private {
        uint256 amount = _claimable(_addr);

        // update last release time
        users[_addr].lastRelease = block.timestamp;

        if (amount > 0) {
            emit Claimed(_addr, amount);
            _mint(_addr, amount);
        }
    }

    /// @notice Calculate the amount of xFhm that can be claimed by user
    /// @param _addr the address to check
    /// @return amount of xFhm that can be claimed by user
    function claimable(address _addr) external view returns (uint256) {
        require(_addr != address(0), 'zero address');
        return _claimable(_addr);
    }

    /// @dev private claim function
    /// @param _addr the address of the user to claim from
    function _claimable(address _addr) private view returns (uint256) {
        UserInfo storage user = users[_addr];

        // get seconds elapsed since last claim
        uint256 secondsElapsed = block.timestamp - user.lastRelease;

        // calculate pending amount
        // Math.mwmul used to multiply wad numbers
        uint256 pending = Math.wmul(user.amount, secondsElapsed * generationRate);

        // get user's XFhm balance
        uint256 userXFhmBalance = balanceOf(_addr);

        // user XFhm balance cannot go above user.amount * maxCap
        uint256 maxXFhmCap = user.amount.mul(maxCap);

        // first, check that user hasn't reached the max limit yet
        if (userXFhmBalance < maxXFhmCap) {
            // then, check if pending amount will make user balance overpass maximum amount
            if ((userXFhmBalance.add(pending)) > maxXFhmCap) {
                return maxXFhmCap.sub(userXFhmBalance);
            } else {
                return pending;
            }
        }
        return 0;
    }

    /// @notice withdraws staked Fhm
    /// @param _amount the amount of Fhm to unstake
    /// Note Beware! you will loose all of your XFhm if you unstake any amount of Fhm!
    function withdraw(uint256 _amount) external override nonReentrant whenNotPaused {
        require(_amount > 0, 'amount to withdraw cannot be zero');
        require(users[msg.sender].amount >= _amount, 'not enough balance');

        // reset last Release timestamp
        users[msg.sender].lastRelease = block.timestamp;

        // update his balance before burning or sending back Fhm
        users[msg.sender].amount = users[msg.sender].amount.sub(_amount);

        // get user XFhm balance that must be burned
        uint256 userXFhmBalance = balanceOf(msg.sender);

        _burn(msg.sender, userXFhmBalance);

        // send back the staked fhm
        fhm.safeTransfer(msg.sender, _amount);

        emit Unstaked(msg.sender, _amount);
    }

    /// @notice get votes for xFhm
    /// @dev votes should only count if account has > threshold% of current cap reached
    /// @dev invVoteThreshold = (1/threshold%)*100
    /// @return the valid votes
    function getVotes(address _account) public view virtual override returns (uint256) {
        uint256 xFhmBalance = balanceOf(_account);

        // check that user has more than voting treshold of maxCap and has fhm in stake
        if (xFhmBalance.mul(invVoteThreshold) > users[_account].amount.mul(maxCap) && isUser(_account)) {
            return xFhmBalance;
        } else {
            return 0;
        }
    }

    function balanceOfVotingToken(address _account) external virtual override view returns (uint) {
        return getVotes(_account);
    }
}