pragma solidity ^0.6.0;

import "./IRC20.sol";

abstract contract RCTransfer {
    function transfer(address from, uint256 value) external virtual;

    function transferFrom(address from, uint256 value) external virtual;

    function approve(address from, uint256 value) external virtual;

    function increaseAllowance(address from, uint256 addedValue) external virtual;

    function decreaseAllowance(address from, uint256 subtractedValue) external virtual;

    function registerRC(IRC20 tarAddress) public {
        tarAddress.registerContract();
    }
}