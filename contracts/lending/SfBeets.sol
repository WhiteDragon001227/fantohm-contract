// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import "@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol";

/// @notice recipe for staked fBeets in FantOHM's lending pool
/// @author pwntr0n
contract SfBeets is ERC20PresetMinterPauser, Ownable {

    using SafeMath for uint;
    using SafeERC20 for IERC20;

    constructor() ERC20PresetMinterPauser("Staked FreshBeets", "sfBeets") {
        // no code
    }

    /// @notice grants minter role to given _account
    /// @param _account minter contract
    function grantRoleMinter(address _account) external {
        grantRole(MINTER_ROLE, _account);
    }

    /// @notice revoke minter role to given _account
    /// @param _account minter contract
    function revokeRoleMinter(address _account) external {
        revokeRole(MINTER_ROLE, _account);
    }
}