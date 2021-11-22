// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;


interface IERC20 {
    function decimals() external view returns (uint8);
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IOwnable {
    function manager() external view returns (address);

    function renounceManagement() external;

    function pushManagement( address newOwner_ ) external;

    function pullManagement() external;
}

contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed( address(0), _owner );
    }

    function manager() public view override returns (address) {
        return _owner;
    }

    modifier onlyManager() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    function renounceManagement() public virtual override onlyManager() {
        emit OwnershipPushed( _owner, address(0) );
        _owner = address(0);
    }

    function pushManagement( address newOwner_ ) public virtual override onlyManager() {
        require( newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipPushed( _owner, newOwner_ );
        _newOwner = newOwner_;
    }

    function pullManagement() public virtual override {
        require( msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled( _owner, _newOwner );
        _owner = _newOwner;
    }
}

interface ITreasury {
    function deposit( uint _amount, address _token, uint _profit ) external returns ( bool );
    function valueOf( address _token, uint _amount ) external view returns ( uint value_ );
    function mintRewards( address _recipient, uint _amount ) external;
}

interface IFHM {
    function burnFrom(address account_, uint256 amount_) external ;
}

contract FantohmOmniBridge is Ownable {

    address public immutable treasury;
    address public immutable nativeFHM;
    address[] public bridgesFHM;

    constructor ( address _treasury, address _nativeFHM ) {
        require( _treasury != address(0) );
        treasury = _treasury;

        require( _nativeFHM != address(0) );
        nativeFHM = _nativeFHM;
    }

    function addBridgeContract( address _bridgeFHM ) external onlyManager {
        require( _bridgeFHM != address(0) );
        bridgesFHM.push( _bridgeFHM );
    }

    function removeBridgeContract( uint _index ) external onlyManager {
        bridgesFHM[ _index ] = address(0);
    }

    function isBridgeContract( address _bridgeFHM ) private view returns (bool) {
        for( uint i = 0; i < bridgesFHM.length; i++ ) {
            if ( bridgesFHM[i] != address(0) ) {
                if ( bridgesFHM[i] == _bridgeFHM ) return true;
            }
        }
        return false;
    }

    function downstream( address _bridgeFHM, uint _amount ) external {
        require( isBridgeContract(_bridgeFHM) , "Token is not whitelisted");

        IERC20( _bridgeFHM ).transferFrom( msg.sender, address(this), _amount );

        ITreasury( treasury ).mintRewards(msg.sender, _amount);
    }

    function upstream( address _bridgeFHM, uint _amount ) external {
        require( isBridgeContract(_bridgeFHM) , "Token is not whitelisted");
        require( IERC20( _bridgeFHM ).balanceOf(address(this)) > _amount , "Insufficient bridge token amount");

        IFHM( nativeFHM ).burnFrom( msg.sender, _amount );

        IERC20( _bridgeFHM ).transfer( msg.sender, _amount );
    }

    function recoverLostToken( address _token ) external onlyManager {
        require( _token != nativeFHM );
        IERC20( _token ).transfer( msg.sender, IERC20( _token ).balanceOf( address(this) ) );
    }
}