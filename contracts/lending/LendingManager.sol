// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

interface IMintable {
    function mint(address to, uint256 amount) external;
}

interface IBurnable {
    function burnFrom(address account, uint256 amount) external;
}

contract LendingManager is Ownable {

    using SafeMath for uint;
    using SafeERC20 for IERC20;

    address public immutable multisig;
    address public immutable fBeets;
    address public immutable sfBeets;

    constructor(address _multisig, address _fBeets, address _sfBeets) {
        require(_multisig != address (0));
        multisig = _multisig;
        require(_fBeets != address (0));
        fBeets = _fBeets;
        require(_sfBeets != address (0));
        sfBeets = _sfBeets;
    }

    function deposit(uint _amount) external {
        IERC20(fBeets).safeTransferFrom(msg.sender, multisig, _amount);
        IMintable(sfBeets).mint(msg.sender, _amount);
    }

    function harvest() external {
        IERC20(sfBeets).balanceOf(msg.sender);
    }

    function withdraw(uint _amount) external {
        IBurnable(sfBeets).burnFrom(msg.sender, _amount);
        IERC20(fBeets).safeTransferFrom(multisig, msg.sender, _amount);
    }
}