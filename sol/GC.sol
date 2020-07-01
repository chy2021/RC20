pragma solidity ^0.6.0;

import './RC20Code.sol';

contract GC20 is RC20 {

    struct ExchangeRecord {
        address fromAccount;
        address toAccount;
        uint256 amount;
        uint256 time;
        string transactionHash;
        bool exist;
    }

    mapping(string => ExchangeRecord) exchangeRecordFlow;

    event ExchangeRecordEvent(address fromAddress, address toAddress, uint256 amount);


    constructor () public {
        name = "GameCoin";
        symbol = "GC";
        decimals = 0;
        cap = 100000000 * (10 ** decimals);
    }


    function airdrop(address toAddress, uint amount, string memory transactionHash) public onlyAdmin {
        ExchangeRecord memory exchangeRecord = exchangeRecordFlow[transactionHash];
        require(!exchangeRecord.exist, "record is exist");

        _mint(toAddress, amount);

        exchangeRecord.exist = true;
        exchangeRecord.fromAccount = msg.sender;
        exchangeRecord.toAccount = toAddress;
        exchangeRecord.amount = amount;
        exchangeRecord.transactionHash = transactionHash;
        exchangeRecord.time = now;

        emit ExchangeRecordEvent(msg.sender, toAddress, amount);
    }




}