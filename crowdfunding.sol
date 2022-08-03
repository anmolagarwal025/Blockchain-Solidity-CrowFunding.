//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract crowfunding
{
    mapping(address=>uint) public contributors;
    address public manager;
    uint public minimumContribution;
    uint public deadline;
    uint public target;
    uint public raisedAmount;
    uint public noOfContibutors;

    constructor(uint _target, uint _deadline){
        target = _target;
        deadline = block.timestamp + _deadline;
        minimumContribution = 100 wei;
        manager = msg.sender;
    }

    function sendEth() public payable{
        require(block.timestamp < deadline, "Deadline has passed ");
        require(msg.value >= minimumContribution, "minimum contribution is 100 wei ");

        if(contributors[msg.sender] == 0){
            noOfContibutors++;
        }
        contributors[msg.sender]+=msg.value;
        raisedAmount+=msg.value;
    }

    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }

    function refund() public{
        require(block.timestamp > deadline, "Deadline is not reached");
        require(raisedAmount < target, "Amount has reached to it's target.");
        require(contributors[msg.sender] > 0);
        address payable user = payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender] = 0;
    }

    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address=>bool) voters;
    }
    mapping(uint=>Request) public requests;
    uint public numRequests;

    modifier onlyManager(){
        require(msg.sender == manager, "Only manager can call this function");
        _;
    }

    function createRequest(string memory _description, address payable _recipient, uint _value) public onlyManager{
        Request storage newRequest = requests[numRequests];
        numRequests++;
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;
    }

    function voteRequest(uint _requestno) public{
        require(contributors[msg.sender] > 0, "You must be a contributor first.");
        Request storage thisRequest = requests[_requestno];
        require(thisRequest.voters[msg.sender] == false, "You have already voted..");
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;
    }

    function MakePayment(uint _requestno) public onlyManager{
        require(raisedAmount >= target, "Target is not reached till yet..");
        Request storage thisRequest = requests[_requestno];
        require(thisRequest.completed == false , "This Request already completed.");
        require(thisRequest.noOfVoters > noOfContibutors/2, "Majority of contributors are not in your favour..");
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;
    }
}
