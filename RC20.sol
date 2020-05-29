pragma solidity ^0.6.0;

import "./IRC20.sol";
import "./RCTransfer.sol";
import "./RCPlayer.sol";


contract RC20 is IRC20, RCPlayer  {

    string public name;                   //fancy name: eg Simon Bucks
    string public symbol;                 //An identifier: eg SBX
    uint8 public decimals;                //How many decimals to show.

    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _lockBalances;
    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;
    uint256 private _cap;

    constructor () public {
        name = "RealCoin";
        symbol = "RC";
        decimals = 2;
        _cap = 100000000 * (10 ** decimals);
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public override view returns (uint256) {
        return _balances[owner];
    }

    function transfer(address to, uint256 value) public override returns (bool) {
        require(value <= _balances[msg.sender]);
        require(to != address(0));

        _balances[msg.sender] = _balances[msg.sender] - value;
        _balances[to] = _balances[to] + value;

        if (isContract(to)) {
            RCTransfer(to).transfer(msg.sender, value);
        }
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowed[owner][spender];
    }

    function approve(address spender, uint256 value) public override returns (bool) {
        require(spender != address(0));
        require(value <= _balances[msg.sender]);
        require(value > 0);

        _lockBalances[msg.sender] = _lockBalances[msg.sender] + (value - _allowed[msg.sender][spender]);
        _balances[msg.sender] = _balances[msg.sender] - (value - _allowed[msg.sender][spender]);

        _allowed[msg.sender][spender] = value;

        if (isContract(spender)) {
            RCTransfer(spender).approve(msg.sender, value);
        }
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        require(value <= _lockBalances[from]);
        require(value <= _allowed[from][msg.sender]);
        require(value > 0);
        require(to != address(0));

        _lockBalances[from] = _lockBalances[from] - value;
        _balances[to] = _balances[to] + value;
        _allowed[from][msg.sender] = _allowed[from][msg.sender] - value;

        if (isContract(to)) {
            RCTransfer(to).transferFrom(from, value);
        }

        emit Transfer(from, to, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));
        require(addedValue > 0);
        require(addedValue <= _balances[msg.sender]);

        _lockBalances[msg.sender] = _lockBalances[msg.sender] + addedValue;
        _balances[msg.sender] = _balances[msg.sender] - addedValue;

        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender] + addedValue);

        if (isContract(spender)) {
            RCTransfer(spender).increaseAllowance(msg.sender, addedValue);
        }

        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));
        require(subtractedValue > 0);
        require(subtractedValue <= _allowed[msg.sender][spender]);

        _lockBalances[msg.sender] = _lockBalances[msg.sender] - subtractedValue;
        _balances[msg.sender] = _balances[msg.sender] + subtractedValue;

        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender] - subtractedValue);

        if (isContract(spender)) {
            RCTransfer(spender).decreaseAllowance(msg.sender, subtractedValue);
        }

        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0));
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
    function giveRC() public payable {
        uint256 msgValue = msg.value / (10 ** 18 - decimals);
        uint256 amount = msgValue / 2;
        _mint(msg.sender, amount);
    }

    function isContract(address addr) private view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function setBalances() public accountCheck {
        _balances[msg.sender] += 10000;
    }

}