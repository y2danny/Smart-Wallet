//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract Consumer{
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function deposit() public payable {}
}

contract SmartWallet{
    
    address payable public owner;

    mapping(address => uint) public allowance;
    mapping(address => bool) public IsAllowedToSend;
    mapping(address => bool) public guardians;
    address payable nextOwner;
    mapping(address => mapping(address => bool)) nextOwnerGuardianVotedBool;
    uint guardianResetCount;
    uint public constant confirmationsFromGuardiansForReset = 3;

    constructor () {
        owner = payable(msg.sender);
    }

    function setGuardian(address _guardian, bool _isGuardian) public{
        require(msg.sender == owner, "Owner not found, ejecting");
        guardians[_guardian] = _isGuardian;
    }

    function proposeNewOwner(address payable _newOwner) public{
        require(guardians[msg.sender], "Guardian not found, ejecting");
        require(nextOwnerGuardianVotedBool[_newOwner][msg.sender] = false, "You already voted, ejecting");
        if(_newOwner != nextOwner) {
            nextOwner = _newOwner;
            guardianResetCount = 0;
        }
        guardianResetCount++;

        if (guardianResetCount >= confirmationsFromGuardiansForReset) {
            owner = nextOwner;
            nextOwner = payable(address (0));
        }
    }

    function setAllowance (address _for, uint _amount) public {
        require(msg.sender == owner, "Owner not found, ejecting");
        allowance[_for] = _amount;

        if(_amount > 0) {
            IsAllowedToSend[_for] = true;
        } else{
            IsAllowedToSend[_for] = false;
        }
    }

    function transfer(address payable _to, uint _amount, bytes memory _payload) public returns(bytes memory){
        //require(msg.sender == owner, "Owner not found, ejecting");
        if(msg.sender != owner) {
            require(IsAllowedToSend[msg.sender], 'Smart contract not allowed to send anything, ejecting');
            require(allowance[msg.sender ] >= _amount, 'Trying to send more than allowed, ejecting');

            allowance[msg.sender] -= _amount;
        }

        (bool success, bytes memory returnData) = _to.call{value: _amount}(_payload);
        require(success, "Ejecting, call unsuccessful");
        return returnData;

    }


    receive() external payable {}



    }