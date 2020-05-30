pragma solidity ^0.6.0;

interface RCTransfer {
    function transfer(address from, uint256 value) external;

    function transferFrom(address from, uint256 value) external;

    function approve(address from, uint256 value) external;

    function increaseAllowance(address from, uint256 addedValue) external;

    function decreaseAllowance(address from, uint256 subtractedValue) external;
}