// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

interface IMintable {
    function mint(address to, uint256 amount) external;
}

interface IBurnable {
    function burnFrom(address account, uint256 amount) external;
}

contract synUSDB is ERC20Burnable, AccessControl {

    using SafeERC20 for IERC20;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    address public USDB;

    constructor(address _USDB) ERC20("synUSDB", "synUSDB") {
        require( _USDB != address(0) );
        USDB = _USDB;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    // 1. this will be called from your bridge first
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "MINTER_ROLE_MISSING");
        _mint(to, amount);
    }

    // 2. this will be called to complete bridge - burn synUSDB to mint USDB
    function downstream(address account, uint256 amount) external virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "MINTER_ROLE_MISSING");

        burnFrom(account, amount);
        IMintable(USDB).mint(account, amount);
    }

    // 3. this will be called to complete bridge to the other way - burn USDB to mint synUSDB to be bridged away
    function upstream(address account, uint256 amount) external virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "MINTER_ROLE_MISSING");

        IBurnable(USDB).burnFrom(account, amount);
        mint(account, amount);
    }
}