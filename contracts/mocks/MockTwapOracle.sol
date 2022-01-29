// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";

contract MockTwapOracle is Ownable {

    uint public amountOut;

    function setAmountOut(uint _amountOut) external onlyOwner {
        amountOut = _amountOut;
    }

    function consult(address _pair, address _token, uint _amountIn) external view returns (uint _amountOut) {
        _amountOut = amountOut;
    }
}
