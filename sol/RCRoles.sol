pragma solidity ^0.6.0;

contract RCRoles {
    address private _owner;
    mapping(address => bool) private _admins;

    constructor() public {
        _owner = msg.sender;
    }

    function addAdmin(address admin) public onlyOwner {
        _admins[admin] = true;
    }
    function removeAdmin(address admin) public onlyOwner {
        _admins[admin] = false;
    }
    function owner() public view returns(address) {
        return _owner;
    }

    modifier onlyAdmin() {
        require(_admins[msg.sender] || msg.sender == _owner, "AdminRole: caller does not have the Admin role");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "AdminRole: caller does not have the Admin role");
        _;
    }
}