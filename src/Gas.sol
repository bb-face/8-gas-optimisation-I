// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

error a(); // "Error in Gas contract - onlyAdminOrOwner modifier : revert happened because the originator of the transaction was not the admin, and furthermore he wasn't the owner of the contract, so he cannot run this function";
error c(); // "Gas Contract - Update Payment function - ID must be greater than 0"
error d(); // "Gas Contract - Update Payment function - Amount must be greater than 0"
error e(); // "Gas Contract - Update Payment function - Administrator must have a valid non zero address"
error a1(); // "Gas Contract - getPayments function - User must have a valid non zero address"
error a2(); // "Contract hacked, imposible, call help"
error a3(); // "Gas Contract - addToWhitelist function -  tier level should not be greater than 255"
error a4(); // "Gas Contract - whiteTransfers function - Sender has insufficient Balance"
error a5(); // "Gas Contract - whiteTransfers function - amount to send have to be bigger than 3"
error a6(); // "Gas Contract CheckIfWhiteListed modifier : revert happened because the originator of the transaction was not the sender"
error a7(); // "Gas Contract CheckIfWhiteListed modifier : revert happened because the user is not whitelisted"
error a8(); // "Gas Contract CheckIfWhiteListed modifier : revert happened because the user's tier is incorrect, it cannot be over 4 as the only tier we have are: 1, 2, 3; therfore 4 is an invalid tier for the whitlist of this contract. make sure whitlist tiers were set correctly"
error a9(); // "Gas Contract - Transfer function - Sender has insufficient Balance"
error b1(); // "Gas Contract - Transfer function -  The recipient name is too long, there is a max length of 8 characters"

contract GasContract {
    uint256 public totalSupply = 0; // cannot be updated
    uint256 public paymentCounter = 0;
    address public immutable contractOwner;

    mapping(address => uint256) public isOddWhitelistUser;
    mapping(address => uint256) public balances;
    mapping(address => Payment[]) public payments;
    mapping(address => uint256) public whitelist;

    address[5] public administrators;

    enum PaymentType {
        Unknown,
        BasicPayment,
        Refund,
        Dividend,
        GroupPayment
    }

    History[] public paymentHistory; // when a payment was updated

    struct Payment {
        PaymentType paymentType;
        uint256 paymentID;
        bool adminUpdated;
        string recipientName; // max 8 characters
        address recipient;
        address admin; // administrators address
        uint256 amount;
    }

    struct History {
        uint256 lastUpdate;
        address updatedBy;
        uint256 blockNumber;
    }

    struct ImportantStruct {
        uint256 amount;
        uint256 valueA; // max 3 digits
        uint256 bigValue;
        uint256 valueB; // max 3 digits
        bool paymentStatus;
        address sender;
    }
    mapping(address => ImportantStruct) public whiteListStruct;

    event AddedToWhitelist(address userAddress, uint256 tier);

    modifier onlyAdminOrOwner() {
        if (checkForAdmin(msg.sender) || (msg.sender == contractOwner)) {
            _;
        } else {
            revert a();
        }
    }

    modifier checkIfWhiteListed() {
        if (whitelist[msg.sender] <= 0) revert a7();
        if (whitelist[msg.sender] >= 4) revert a8();

        _;
    }

    event supplyChanged(address indexed, uint256 indexed);
    event Transfer(address recipient, uint256 amount);
    event PaymentUpdated(
        address admin,
        uint256 ID,
        uint256 amount,
        string recipient
    );
    event WhiteListTransfer(address indexed);

    constructor(address[] memory _admins, uint256 _totalSupply) {
        contractOwner = msg.sender;
        totalSupply = _totalSupply;

        for (uint256 ii = 0; ii < administrators.length; ii++) {
            if (_admins[ii] != address(0)) {
                administrators[ii] = _admins[ii];
                if (_admins[ii] == contractOwner) {
                    balances[contractOwner] = totalSupply;
                } else {
                    balances[_admins[ii]] = 0;
                }
                if (_admins[ii] == contractOwner) {
                    emit supplyChanged(_admins[ii], totalSupply);
                } else if (_admins[ii] != contractOwner) {
                    emit supplyChanged(_admins[ii], 0);
                }
            }
        }
    }

    function checkForAdmin(address _user) public view returns (bool) {
        for (uint256 i = 0; i < administrators.length; i++) {
            if (administrators[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function balanceOf(address _user) public view returns (uint256) {
        return balances[_user];
    }

    function addHistory(address _updateAddress) public returns (bool status_) {
        History memory history;
        history.blockNumber = block.number;
        history.lastUpdate = block.timestamp;
        history.updatedBy = _updateAddress;
        paymentHistory.push(history);

        return true;
    }

    function getPayments(
        address _user
    ) public view returns (Payment[] memory payments_) {
        if (_user == address(0)) revert a1();

        return payments[_user];
    }

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) public returns (bool status_) {
        if (balances[msg.sender] < _amount) revert a9();
        if (bytes(_name).length > 8) revert b1();

        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;

        emit Transfer(_recipient, _amount);

        return true;
    }

    function updatePayment(
        address _user,
        uint256 _ID,
        uint256 _amount,
        PaymentType _type
    ) public onlyAdminOrOwner {
        if (_ID < 0) revert c();
        if (_amount < 0) revert d();
        if (_user == address(0)) revert e();

        for (uint256 ii = 0; ii < payments[_user].length; ii++) {
            Payment storage payment = payments[_user][ii];

            if (payment.paymentID == _ID) {
                payment.adminUpdated = true;
                payment.admin = _user;
                payment.paymentType = _type;
                payment.amount = _amount;
                addHistory(_user);
                emit PaymentUpdated(
                    msg.sender,
                    _ID,
                    _amount,
                    payment.recipientName
                );
            }
        }
    }

    function addToWhitelist(
        address _userAddrs,
        uint256 _tier
    ) public onlyAdminOrOwner {
        if (_tier > 255) revert a3();

        if (_tier > 3) {
            whitelist[_userAddrs] = 3;
        } else if (_tier == 1) {
            whitelist[_userAddrs] = 1;
        } else if (_tier > 0) {
            whitelist[_userAddrs] = 2;
        }

        isOddWhitelistUser[_userAddrs] = 1;

        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(
        address _recipient,
        uint256 _amount
    ) public checkIfWhiteListed {
        whiteListStruct[msg.sender] = ImportantStruct(
            _amount,
            0,
            0,
            0,
            true,
            msg.sender
        );

        if (_amount < 3) revert a4();
        if (balances[msg.sender] < _amount) revert a5();

        balances[msg.sender] =
            balances[msg.sender] +
            whitelist[msg.sender] -
            _amount;

        balances[_recipient] =
            balances[_recipient] +
            _amount -
            whitelist[msg.sender];

        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(
        address sender
    ) public view returns (bool, uint256) {
        return (
            whiteListStruct[sender].paymentStatus,
            whiteListStruct[sender].amount
        );
    }
}
