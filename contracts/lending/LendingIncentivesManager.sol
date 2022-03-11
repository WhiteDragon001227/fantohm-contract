// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

contract LendingIncentivesManager is Ownable {

    using SafeMath for uint;
    using SafeERC20 for IERC20;

    address public immutable FHM;
    address public immutable votingHelper;

    uint public fhmPerBlock;
    // Bonus multiplier for early FHM makers.
    uint public constant BONUS_MULTIPLIER = 1;

    constructor(address _FHM, address _votingHelper) {
        require(_FHM != address(0));
        FHM = _FHM;
        require(_votingHelper != address(0));
        votingHelper = _votingHelper;
    }

    /// @dev borrowers obtain FHM incentives ranging from 0-25% of the borrowed value, depending on balanceOf(sFHM).
    /// Formula for borrow apr: borrow apr (%) =min(25%, balanceOf(sFHM) * price of FHM / sum(borrowed amount) * 5)
    /// example: User has borrowed $100 of USDB. User also has a balance $1 of sFHM, this entitles him to 5% of his borrowed amount in rewards (ie $5 of FHM over the course of a year) User now instead has a balance of $3 of sFHM, this entitles him to 15% of his borrowed amount in rewards (ie $15 of FHM over the course of a year) for every 1% of borrowed amount staked as sFHM, user gets 5% of borrowed amount as a reward (up to a max of 25%)
    function claimable(address _user) external {

    }

}