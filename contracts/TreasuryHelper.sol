// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFHMCirculatingSupply {
    function OHMCirculatingSupply() external view returns ( uint );
}
contract TreasuryHelper is Ownable, AccessControl {

    using SafeMath for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    address public immutable fhmCirculatingSupply; // FHM circulating supply
    
    uint public treasuryValue;
    constructor( address _fhmCirculatingSupply) {
        require( _fhmCirculatingSupply != address(0) );
        fhmCirculatingSupply = _fhmCirculatingSupply;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
    }
    /**
        @notice set treasury Value in 18 decimals usd value
        @param _treasuryValue uint
     */
    function setTreasuryValue(uint _treasuryValue) external  {
        require(hasRole(ADMIN_ROLE, msg.sender), "Must have a admin role");
        treasuryValue = _treasuryValue;
    }
    function bookValue() external view returns(uint){
        return treasuryValue.div(IFHMCirculatingSupply(fhmCirculatingSupply).OHMCirculatingSupply());
    }
      /// @notice grants WhitelistCall role to given _account
    /// @param _account WhitelistCall contract
    function grantRoleWhitelistWithdraw(address _account) onlyOwner external {
        grantRole(ADMIN_ROLE, _account);
    }

    /// @notice revoke WhitelistCall role to given _account
    /// @param _account WhitelistCall contract
    function revokeRoleWhitelistWithdraw(address _account) onlyOwner external {
        revokeRole(ADMIN_ROLE, _account);
    }
    
}
