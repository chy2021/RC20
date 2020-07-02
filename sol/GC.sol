pragma solidity ^0.6.0;

import './RC20Code.sol';

contract GC is RC20 {
    struct ExchangeRecord {
        address fromAccount;
        address toAccount;
        uint256 amount;
        uint256 time;
        string transactionHash;
        uint8 exchangeRecordType; // 1 fc2gc, 2 gc2fc
        bool exist;
    }

    mapping(uint256 => ExchangeRecord) exchangeRecordFlow;
    mapping(string => uint256) checkExchangeRecord;
    uint256 exchangeRecordIdIndex;
    mapping(address => uint256[]) selfExchangeRecordMap;

    event ExchangeRecordEvent(address toAddress, uint256 amount, uint256 exchangeRecordId, uint8 exchangeRecordType);

    IRC20 _irc20;

    constructor (IRC20 irc20) public {
        name = "GameCoin";
        symbol = "GC";
        decimals = 0;
        _irc20 = irc20;
    }


    // 空投筹码，，，fc兑换gc
    function airdrop(address toAddress, uint amount, string memory transactionHash) public onlyAdmin {

        require(checkExchangeRecord[transactionHash] == 0, "record is exist");
        exchangeRecordIdIndex = exchangeRecordIdIndex + 1;
        checkExchangeRecord[transactionHash] = exchangeRecordIdIndex;

        _mint(toAddress, amount);

        ExchangeRecord memory exchangeRecord;
        exchangeRecord.exist = true;
        exchangeRecord.fromAccount = msg.sender;
        exchangeRecord.toAccount = toAddress;
        exchangeRecord.amount = amount;
        exchangeRecord.transactionHash = transactionHash;
        exchangeRecord.time = now;
        exchangeRecord.exchangeRecordType = 1;

        exchangeRecordFlow[exchangeRecordIdIndex] = exchangeRecord;
        selfExchangeRecordMap[msg.sender].push(exchangeRecordIdIndex);

        emit ExchangeRecordEvent(toAddress, amount, exchangeRecordIdIndex, 1);
    }


    // 提现  gc兑换fc
    function withdrawal(uint amount) public {

        _burn(msg.sender, amount);

        _irc20.transfer(msg.sender, amount);

        ExchangeRecord memory exchangeRecord;
        exchangeRecord.exist = true;
        exchangeRecord.fromAccount = msg.sender;
        exchangeRecord.toAccount = address(0);
        exchangeRecord.amount = amount;
        exchangeRecord.time = now;
        exchangeRecord.exchangeRecordType = 2;

        exchangeRecordFlow[++exchangeRecordIdIndex] = exchangeRecord;
        selfExchangeRecordMap[msg.sender].push(exchangeRecordIdIndex);

        emit ExchangeRecordEvent(msg.sender, amount, exchangeRecordIdIndex, 2);
    }

    // 根据兑换信息的id获取兑换的信息
    function getExchangeRecord(uint256 exchangeRecordId) public view returns(
        address fromAccount,
        address toAccount,
        uint256 amount,
        uint256 time,
        string memory transactionHash,
        uint8 exchangeRecordType, // 1 fc2gc, 2 gc2fc
        bool exist) {

        ExchangeRecord memory exchangeRecord = exchangeRecordFlow[exchangeRecordId];

        fromAccount = exchangeRecord.fromAccount;
        toAccount = exchangeRecord.toAccount;
        amount = exchangeRecord.amount;
        time = exchangeRecord.time;
        transactionHash = exchangeRecord.transactionHash;
        exchangeRecordType = exchangeRecord.exchangeRecordType;
        exist = exchangeRecord.exist;
    }

    // 根据fc兑换gc的hash获取对应的兑换信息。
    function getExchangeRecord(string memory _transactionHash) public view returns(
        address fromAccount,
        address toAccount,
        uint256 amount,
        uint256 time,
        string memory transactionHash,
        uint8 exchangeRecordType, // 1 fc2gc, 2 gc2fc
        bool exist) {

        uint256 exchangeRecordId = checkExchangeRecord[_transactionHash];

        return getExchangeRecord(exchangeRecordId);
    }

    // 获取兑换列表
    function getSelfExchangeRecordList(address account) public view returns(uint256[] memory) {
        return selfExchangeRecordMap[account];
    }


    bool downWinnerStatus;
    // 管理员设置开始下注对决盘
    function startDownWinner() public onlyAdmin {
        downWinnerStatus = true;
    }
    // 管理员设置停止下注对决盘
    function stopDownWinner() public onlyAdmin {
        downWinnerStatus = false;
    }
    // 获取对决盘下注状态 true可以下注
    function getDownWinnerStatus() public view  returns(bool){
        return downWinnerStatus;
    }

    bool down8strongStatus;
    // 管理员设置开始下注8强盘
    function startDown8strong() public onlyAdmin {
        down8strongStatus = true;
    }
    // 管理员设置停止下注8强盘
    function stopDown8strong() public onlyAdmin {
        down8strongStatus = false;
    }
    // 获取8强盘下注状态 true可以下注
    function getDown8strongStatus() public view  returns(bool){
        return down8strongStatus;
    }

    struct StrongInfo {
        uint256 strongNo;

        address strongAccount;

        string strongDesc;
    }

    StrongInfo[8] strongInfoList;

    function setStrongInfo(uint256 strongNo, address strongAccount, string memory strongDesc) public {
        strongInfoList[strongNo] ;
    }

    struct DownChipInfo {
        address account;
        uint256 amount;
    }
    struct DownChipList {
        mapping(address => uint256) accountIndexMap;
        DownChipInfo[] downChipInfoList;
        uint256 totalDownChip;
    }

    mapping(uint256 => DownChipList) down8strongChipListMap;

    mapping(uint256 => DownChipList) downWinnerChipListMap;

    uint256[2] duelTeams;

    // 进行押注8强队伍胜利
    function down8strong(uint256 strongNo, uint256 amount) public {
        require(down8strongStatus, "8 strong no start");
        require(strongNo >= 0 && strongNo < 8, "strongNo is fail");
        require(amount < balanceOf(msg.sender), "amount is fail");

        DownChipList storage downChipList = down8strongChipListMap[strongNo];
        uint256 downChipInfoListIndex = downChipList.accountIndexMap[msg.sender];
        if (downChipInfoListIndex == 0) {
            DownChipInfo memory downChipInfo = DownChipInfo(msg.sender, amount);
            downChipList.accountIndexMap[msg.sender] = downChipList.downChipInfoList.length;
            downChipList.downChipInfoList.push(downChipInfo);

        } else {
            DownChipInfo storage downChipInfo = downChipList.downChipInfoList[downChipInfoListIndex - 1];
            downChipInfo.amount = downChipInfo.amount + amount;
        }
        downChipList.totalDownChip = downChipList.totalDownChip + amount;

        _burn(msg.sender, amount);


    }

    // 获取8强的冠军我押注的信息。
    function getSelfDown8strongChip(address self) public view returns(uint256[8] memory) {
        uint256[8] memory selfDown8strongAmount;
        for (uint256 i = 1; i <= 8; i++) {
            uint256 index = down8strongChipListMap[i].accountIndexMap[self];
            if (index == 0) {
                selfDown8strongAmount[i] = 0;
            } else {
                selfDown8strongAmount[i] = down8strongChipListMap[i].downChipInfoList[index -1].amount;
            }
        }
        return selfDown8strongAmount;
    }

    // 管理员进行设置对决的两只队伍
    function setDuelTeam(uint256 duelTeam1, uint256 duelTeam2) public onlyAdmin {
        duelTeams[0] = duelTeam1;
        duelTeams[1] = duelTeam2;
    }

    // 下注对决押注
    function downWinner(uint256 strongNo, uint256 amount) public {
        require(downWinnerStatus, "8 strong no start");
        require(strongNo == duelTeams[0] || strongNo == duelTeams[1], "strongNo is fail");
        require(amount < balanceOf(msg.sender), "amount is fail");

        DownChipList storage downChipList = downWinnerChipListMap[strongNo];
        uint256 downChipInfoListIndex = downChipList.accountIndexMap[msg.sender];
        if (downChipInfoListIndex == 0) {
            DownChipInfo memory downChipInfo = DownChipInfo(msg.sender, amount);
            downChipList.accountIndexMap[msg.sender] = downChipList.downChipInfoList.length;
            downChipList.downChipInfoList.push(downChipInfo);

        } else {
            DownChipInfo storage downChipInfo = downChipList.downChipInfoList[downChipInfoListIndex - 1];
            downChipInfo.amount = downChipInfo.amount + amount;
        }
        downChipList.totalDownChip = downChipList.totalDownChip + amount;

        _burn(msg.sender, amount);

    }

    // 获取对决押注信息。
    function getSelfDownWinnerChip(address self) public view returns(uint256[2] memory, uint256[2] memory) {
        uint256[2] memory selfDownWinnerAmount;
        for (uint256 i1 = 0; i1 < 2; i1++) {
            uint i = duelTeams[i1];
            uint256 index = downWinnerChipListMap[i].accountIndexMap[self];
            if (index == 0) {
                selfDownWinnerAmount[i] = 0;
            } else {
                selfDownWinnerAmount[i] = downWinnerChipListMap[i].downChipInfoList[index -1].amount;
            }
        }
        return (duelTeams, selfDownWinnerAmount);
    }

    // 获取当前的对决队伍编号
    function getCurrentDuelTeam() public view returns (uint256[2] memory) {
        return duelTeams;
    }


}