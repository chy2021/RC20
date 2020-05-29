pragma solidity ^0.6.0;

import './RCRoles.sol';

contract RCPlayer is RCRoles {
    bool private _transferSwitch;

    constructor () public {
        _transferSwitch = false;
    }

    function transferOpen() public onlyAdmin{
        _transferSwitch = true;
    }

    function transferDown() public onlyAdmin {
        _transferSwitch = false;
    }

    modifier isTransferOpen {
        require(_transferPaused, "Transfer down");
        _;
    }

    modifier isTransferDown {
        require(_transferPaused, "Transfer open");
        _;
    }

}