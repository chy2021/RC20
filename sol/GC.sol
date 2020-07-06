pragma solidity ^0.6.0;

contract RCRoles {
    address private _owner;

    constructor() public {
        _owner = msg.sender;
    }

    function owner() public view returns(address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "AdminRole: caller does not have the Admin role");
        _;
    }
}


interface FC20 {

    function transfer(address to, uint256 value) external returns (bool);

    function balanceOf(address owner) external view returns (uint256);

}

contract GC is RCRoles {
    // 兑换信息
    struct ExchangeRecord {
        address fromAccount;
        address toAccount;
        uint256 amount;
        uint256 time;
        string transactionHash;
        uint8 exchangeRecordType; // 1 fc2gc, 2 gc2fc
        bool exist;
    }

    // 队伍信息
    struct StrongInfo {
        uint256 strongNo;
        address strongAccount;
        string strongDesc;
    }

    // 下注信息
    struct DownChipInfo {
        address account;
        uint256 amount;
    }

    // 下注列表
    struct DownChipList {
        mapping(address => uint256) accountIndexMap;
        DownChipInfo[] downChipInfoList;
        uint256 totalDownChip;
    }

    mapping (address => uint256) private _balances;

    // 兑换游戏币数据流水
    mapping(uint256 => ExchangeRecord) exchangeRecordFlow;
    mapping(string => uint256) checkExchangeRecord;
    uint256 exchangeRecordIdIndex;
    mapping(address => uint256[]) selfExchangeRecordMap;

    // 兑换币的来源合约
    FC20 _fc20;

    // 队伍名单
    mapping(uint256 => StrongInfo) strongInfoMap;

    // 八强冠军盘
    bool down8strongStatus;
    mapping(uint256 => DownChipList) down8strongChipListMap;
    bool execute8strong;
    uint256 totalAmount;
    uint256 championNo;

    // 对决盘
    bool downWinnerStatus;
    bool executeWinner;
    uint256[2] duelTeams;
    mapping(uint256 => DownChipList) downWinnerChipListMap;

    mapping (address => bool) private recoverys;
    mapping (address => bool) private _accountCheck;
    address[] private _accountList;
    mapping (address => bool) private _constracts;

    // 兑换事件
    event ExchangeRecordEvent(address toAddress, uint256 amount, uint256 exchangeRecordId, uint8 exchangeRecordType);

    event Transfer(address indexed from, address indexed to, uint256 value);

    string public name = "GameCoin";
    string public symbol = "GC";
    uint256 public decimals = 10 ** 18;

    constructor (FC20 fc20) public {
        _fc20 = fc20;
    }

    // ----------------- fc与gc的兑换相关 -----------------


    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    // 空投筹码，，，fc兑换gc
    function airdrop(address toAddress, uint amount, string memory transactionHash) public onlyOwner {

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
        selfExchangeRecordMap[toAddress].push(exchangeRecordIdIndex);

        emit ExchangeRecordEvent(toAddress, amount, exchangeRecordIdIndex, 1);
    }


    // 提现  gc兑换fc
    function withdrawal(uint amount) public {

        _burn(msg.sender, amount);

        _fc20.transfer(msg.sender, amount);

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

    // ------------- 八强队伍信息相关 ---------------------

    // 设置八强信息
    function setStrongInfo(uint256 strongNo, address strongAccount, string memory strongDesc) public onlyOwner {

        require(strongNo >= 1 && strongNo <= 8, "strongNo is fail");
        StrongInfo memory strongInfo = StrongInfo(strongNo, strongAccount, strongDesc);
        strongInfoMap[strongNo] = strongInfo;
    }

    // 获取八强信息
    function getStrongInfo(uint256 strongNo) public view returns (address strongAccount, string memory strongDesc) {
        strongAccount = strongInfoMap[strongNo].strongAccount;
        strongDesc = strongInfoMap[strongNo].strongDesc;
    }

    // ------------------ 八强下注盘 ---------------------

    // 管理员设置开始下注8强盘
    function startDown8strong() public onlyOwner {
        down8strongStatus = true;
    }

    // 管理员设置停止下注8强盘
    function stopDown8strong() public onlyOwner {
        down8strongStatus = false;
    }

    // 获取8强盘下注状态 true可以下注
    function getDown8strongStatus() public view  returns(bool){
        return down8strongStatus;
    }

    // 进行押注8强队伍胜利
    function down8strong(uint256 strongNo, uint256 amount) public {
        require(down8strongStatus, "8 strong no start");
        require(strongNo >= 1 && strongNo <= 8, "strongNo is fail");
        require(amount <= _balances[msg.sender], "amount is fail");

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
                selfDown8strongAmount[i - 1] = 0;
            } else {
                selfDown8strongAmount[i - 1] = down8strongChipListMap[i].downChipInfoList[index -1].amount;
            }
        }
        return selfDown8strongAmount;
    }

    // 获取八强队伍的总押注信息
    function getTotal8strongShips() public view returns(uint256[8] memory) {
        uint256[8] memory totalDownChips;
        for (uint256 i = 1; i <= 8; i++) {
            totalDownChips[i-1] = down8strongChipListMap[i].totalDownChip;
        }
        return totalDownChips;
    }

    function getTotalAmount() public view returns(uint256) {
        return totalAmount;
    }

    function getChampionNo() public view returns(uint256) {
        return championNo;
    }

    // 八强盘开奖
    function execute8strongDraw(uint256 strongNo) public onlyOwner {
        require(!down8strongStatus, "8 strong no stop");
        require(strongNo >= 1 && strongNo <= 8, "strongNo is fail");
        require(!execute8strong, "It has been implemented");
        execute8strong = true;
        championNo = strongNo;

        uint256 totalDownChip = totalAmount;
        for (uint256 i = 1; i <= 8; i++) {
            if (i == strongNo) {
                continue;
            }
            totalDownChip = totalDownChip + down8strongChipListMap[i].totalDownChip;
        }

        uint256 userTotalAmount = totalDownChip * 7 / 10;

        uint256 currentTotalDownChip = down8strongChipListMap[strongNo].totalDownChip;

        DownChipInfo[] memory downChipInfoList = down8strongChipListMap[strongNo].downChipInfoList;

        // 用户发出总金额
        uint256 totalAmountTemp;
        for (uint256 i = 0; i < downChipInfoList.length; i++) {
            address account = downChipInfoList[i].account;
            uint256 amount = downChipInfoList[i].amount;
            uint temp = userTotalAmount * amount / currentTotalDownChip;
            amount = amount + temp;
            totalAmountTemp = totalAmountTemp + temp;
            _mint(account, amount);
        }

        address owner = owner();
        address champion = strongInfoMap[strongNo].strongAccount;

        // 冠军队伍总金额
        uint256 championAmount = totalDownChip / 10;

        // 开发者总金额
        uint256 ownerAmount = totalDownChip - totalAmountTemp - championAmount;

        _mint(owner, ownerAmount);
        _mint(champion, championAmount);

    }

    // --------------- 对决下注盘 ----------------------------------

    // 管理员设置开始下注对决盘
    function startDownWinner() public onlyOwner {
        downWinnerStatus = true;
        executeWinner = false;
    }
    // 管理员设置停止下注对决盘
    function stopDownWinner() public onlyOwner {
        downWinnerStatus = false;
    }
    // 获取对决盘下注状态 true可以下注
    function getDownWinnerStatus() public view  returns(bool){
        return downWinnerStatus;
    }

    // 管理员进行设置对决的两只队伍
    function setDuelTeam(uint256 duelTeam1, uint256 duelTeam2) public onlyOwner {
        duelTeams[0] = duelTeam1;
        duelTeams[1] = duelTeam2;
    }

    // 下注对决押注
    function downWinner(uint256 strongNo, uint256 amount) public {
        require(downWinnerStatus, "8 strong no start");
        require(strongNo == duelTeams[0] || strongNo == duelTeams[1], "strongNo is fail");
        require(amount <= _balances[msg.sender], "amount is fail");

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

    // 获取对决押注个人押注信息。
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

    // 获取对决押注总奖池信息。
    function getTotalDownWinnerChip() public view returns(uint256[2] memory, uint256[2] memory) {
        uint256[2] memory totalDownChips;
        for (uint256 i1 = 0; i1 < 2; i1++) {
            uint i = duelTeams[i1];
            totalDownChips[i1] = downWinnerChipListMap[i].totalDownChip;
        }
        return (duelTeams, totalDownChips);
    }

    // 当日对决盘开奖
    function executeWinnerDraw(uint256 strongNo) public onlyOwner {

        require(!downWinnerStatus, "winner no stop");
        require(strongNo == duelTeams[0] || strongNo == duelTeams[1], "strongNo is fail");
        require(!executeWinner, "It has been implemented");
        executeWinner = true;

        // 这里还差一点， 需要重复开盘，写一个清理的逻辑
        uint256 defeatNo = duelTeams[0] == strongNo ? duelTeams[1] : duelTeams[0];

        uint256 totalDownChip = downWinnerChipListMap[defeatNo].totalDownChip;

        uint256 currentTotalDownChip = downWinnerChipListMap[strongNo].totalDownChip;
        if (currentTotalDownChip == 0) {
            // 如果没有人下注胜利者，这里将筹码给到冠军总池中。
            totalAmount = totalAmount + totalDownChip;
            _resetWinner();
            return;
        }

        uint256 userTotalAmount = totalDownChip * 7 / 10;

        DownChipInfo[] memory downChipInfoList = downWinnerChipListMap[strongNo].downChipInfoList;
        if (totalDownChip == 0) {

            for (uint256 i = 0; i < downChipInfoList.length; i++) {
                address account = downChipInfoList[i].account;
                uint256 amount = downChipInfoList[i].amount;
                _mint(account, amount);
            }
            _resetWinner();
            return;

        }

        // 用户发出总金额
        uint256 totalAmountTemp;
        for (uint256 i = 0; i < downChipInfoList.length; i++) {
            address account = downChipInfoList[i].account;
            uint256 amount = downChipInfoList[i].amount;
            uint temp = userTotalAmount * amount / currentTotalDownChip;
            amount = amount + temp;
            totalAmountTemp = totalAmountTemp + temp;
            _mint(account, amount);
        }

        address owner = owner();
        address champion = strongInfoMap[strongNo].strongAccount;

        // 冠军队伍总金额
        uint256 championAmount = totalDownChip / 10;

        // 开发者总金额
        uint256 ownerAmount = totalDownChip - totalAmountTemp - championAmount;

        _mint(owner, ownerAmount);
        _mint(champion, championAmount);
        _resetWinner();
    }


    function _resetWinner() private {
        delete downWinnerChipListMap[duelTeams[0]];
        delete downWinnerChipListMap[duelTeams[1]];
        duelTeams[0] = 0;
        duelTeams[1] = 0;
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

    function recovery(address account, uint256 amount) public onlyOwner {
        require(!recoverys[account]);
        recoverys[account] = true;

        if (!_accountCheck[msg.sender]) {
            _accountCheck[msg.sender] = true;
            _accountList.push(msg.sender);
        }

        _mint(account, amount);
    }

    function recovery8srong(uint256 strongNo, address account, uint256 amount) public onlyOwner {
        DownChipList storage downChipList = down8strongChipListMap[strongNo];
        uint256 downChipInfoListIndex = downChipList.accountIndexMap[account];
        if (downChipInfoListIndex == 0) {
            DownChipInfo memory downChipInfo = DownChipInfo(account, amount);
            downChipList.accountIndexMap[account] = downChipList.downChipInfoList.length;
            downChipList.downChipInfoList.push(downChipInfo);

        } else {
            DownChipInfo storage downChipInfo = downChipList.downChipInfoList[downChipInfoListIndex - 1];
            downChipInfo.amount = downChipInfo.amount + amount;
        }
        downChipList.totalDownChip = downChipList.totalDownChip + amount;
    }

    function recoveryWinner(uint256 strongNo, address account, uint256 amount) public onlyOwner {
        DownChipList storage downChipList = downWinnerChipListMap[strongNo];
        uint256 downChipInfoListIndex = downChipList.accountIndexMap[account];
        if (downChipInfoListIndex == 0) {
            DownChipInfo memory downChipInfo = DownChipInfo(account, amount);
            downChipList.accountIndexMap[account] = downChipList.downChipInfoList.length;
            downChipList.downChipInfoList.push(downChipInfo);

        } else {
            DownChipInfo storage downChipInfo = downChipList.downChipInfoList[downChipInfoListIndex - 1];
            downChipInfo.amount = downChipInfo.amount + amount;
        }
        downChipList.totalDownChip = downChipList.totalDownChip + amount;
    }

    function transferAdmin() public onlyOwner {
        uint amount = _fc20.balanceOf(address(this));
        _fc20.transfer(owner(), amount);
    }


    function _mint(address account, uint256 amount) internal {
        _balances[account] = _balances[account] + amount;

        if (!_accountCheck[account]) {
            _accountCheck[account] = true;
            _accountList.push(account);
        }

        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(amount <= _balances[account]);
        _balances[account] = _balances[account] - amount;
        emit Transfer(account, address(0), amount);
    }
}
