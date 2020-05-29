pragma solidity ^0.6.0;

contract RCPlayer {
    mapping (address => bool) private _accountCheck;
    address[] private _accountList;

    bool private _transferSwitch;

    constructor () public {
        _transferSwitch = false;
    }

    modifier isTransferPaused {
        require(!_transferPaused, "Pausable: Transfer paused");
        _;
    }

    modifier accountCheck() {
        if (!_accountCheck[msg.sender]) {
            _accountCheck[msg.sender] = true;
            _accountList.push(msg.sender);
        }
        _;
    }

    function accountTotal() public view returns (uint256) {
        return _accountList.length;
    }

    function accountList(uint256 begin, uint256 size) public view returns (address[] memory) {
        require(begin >= 0 && begin < _accountList.length, "FC: accountList out of range");
        address[] memory res = new address[](size);
        uint256 range = _accountList.length < begin + size ? _accountList.length : begin + size;
        for (uint256 i = begin; i < range; i++) {
            res[i-begin] = _accountList[i];
        }
        return res;
    }

}