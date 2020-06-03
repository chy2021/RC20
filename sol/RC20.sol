pragma solidity ^0.6.0;

import "./IRC20.sol";
import "./RCTransfer.sol";
import "./RCPlayer.sol";
import './RCRoles.sol';


contract RC20 is IRC20, RCPlayer {

    string public name;
    string public symbol;
    uint256 public decimals;

    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _lockBalances;
    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;
    uint256 private _cap;

    uint256 private _likeSupply;
    uint256 private _likeCap;
    mapping (address => uint256) private _likeTime;

    mapping (address => bool) private recoverys;
    mapping (address => bool) private _accountCheck;
    address[] private _accountList;
    mapping (address => bool) private _constracts;


    constructor () public {
        name = "RealCoin";
        symbol = "RC";
        decimals = 2;
        _cap = 100000000 * (10 ** decimals);
        _likeCap = 5000000 * (10 ** decimals);
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public override view returns (uint256) {
        return _balances[owner];
    }

    function transfer(address to, uint256 value) public override isTransferOpen returns (bool) {
        require(value <= _balances[msg.sender]);
        require(to != address(0));

        _balances[msg.sender] = _balances[msg.sender] - value;
        _balances[to] = _balances[to] + value;

        if (_constracts[to]) {
            RCTransfer(to).transfer(msg.sender, value);
        }
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function allowance(address owner, address spender) public override isTransferOpen view returns (uint256) {
        return _allowed[owner][spender];
    }

    function approve(address spender, uint256 value) public override isTransferOpen returns (bool) {
        require(spender != address(0));
        require(value <= _balances[msg.sender]);
        require(value > 0);

        _lockBalances[msg.sender] = _lockBalances[msg.sender] + (value - _allowed[msg.sender][spender]);
        _balances[msg.sender] = _balances[msg.sender] - (value - _allowed[msg.sender][spender]);

        _allowed[msg.sender][spender] = value;

        if (_constracts[spender]) {
            RCTransfer(spender).approve(msg.sender, value);
        }
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public override isTransferOpen returns (bool) {
        require(value <= _lockBalances[from]);
        require(value <= _allowed[from][msg.sender]);
        require(value > 0);
        require(to != address(0));

        _lockBalances[from] = _lockBalances[from] - value;
        _balances[to] = _balances[to] + value;
        _allowed[from][msg.sender] = _allowed[from][msg.sender] - value;

        if (_constracts[to]) {
            RCTransfer(to).transferFrom(from, value);
        }

        emit Transfer(from, to, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public isTransferOpen returns (bool) {
        require(spender != address(0));
        require(addedValue > 0);
        require(addedValue <= _balances[msg.sender]);

        _lockBalances[msg.sender] = _lockBalances[msg.sender] + addedValue;
        _balances[msg.sender] = _balances[msg.sender] - addedValue;

        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender] + addedValue);

        if (_constracts[spender]) {
            RCTransfer(spender).increaseAllowance(msg.sender, addedValue);
        }

        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public isTransferOpen returns (bool) {
        require(spender != address(0));
        require(subtractedValue > 0);
        require(subtractedValue <= _allowed[msg.sender][spender]);

        _lockBalances[msg.sender] = _lockBalances[msg.sender] - subtractedValue;
        _balances[msg.sender] = _balances[msg.sender] + subtractedValue;

        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender] - subtractedValue);

        if (_constracts[spender]) {
            RCTransfer(spender).decreaseAllowance(msg.sender, subtractedValue);
        }

        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0));
        require(_cap >= _totalSupply + amount);

        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0));
        require(amount <= _balances[account]);

        _totalSupply = _totalSupply - amount;
        _balances[account] = _balances[account] - amount;
        emit Transfer(account, address(0), amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        require(amount <= _allowed[account][msg.sender]);

        _allowed[account][msg.sender] = _allowed[account][msg.sender] - amount;
        _burn(account, amount);
    }

    // ------ RC features
    receive() external payable isTransferOpen {
        uint256 amount = msg.value / (10 ** 18);
        require(amount >= 1);

        if (!_accountCheck[msg.sender]) {
            _accountCheck[msg.sender] = true;
            _accountList.push(msg.sender);
        }

        _mint(msg.sender, amount);
    }

    function registerContract() external override {
        require(isContract(msg.sender), "Must be a contract");

        _constracts[msg.sender] = true;
    }

    function totalBalanceOf(address account) public view returns(uint256) {
        return _balances[account] + _lockBalances[account];
    }

    function lockBalanceOf(address account) public view returns(uint256) {
        return _lockBalances[account];
    }

    function isContract(address addr) private view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    // --------- like
    function like() public isTransferOpen{
        require(now - _likeTime[msg.sender] >= 24 * 60 * 60);

        _likeTime[msg.sender] = now;
        if (!_accountCheck[msg.sender]) {
            _accountCheck[msg.sender] = true;
            _accountList.push(msg.sender);
        }

        uint256 amount = 5 * 100;

        require(_likeCap >= _likeSupply + amount);

        _likeSupply = _likeSupply + amount;
        _mint(msg.sender, amount);
    }

    function likeSupply() public view returns(uint256) {
        return _likeSupply;
    }

    // ----------------- recovery
    function accountTotal() public view  returns (uint256) {
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

    function recovery(address account, uint256 amount) public onlyAdmin isTransferDown {
        require(!recoverys[account]);
        recoverys[account] = true;

        if (!_accountCheck[msg.sender]) {
            _accountCheck[msg.sender] = true;
            _accountList.push(msg.sender);
        }

        _mint(account, amount);
    }

}