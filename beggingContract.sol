// SPDX-License-Identifier: MIT
pragma solidity >=0.8.34;

contract BeggingContract {

    address public immutable owner;
    mapping(address => uint256) public donorRecord;
    bool private _locked;
    uint256 public constant DAY_START_HOUR = 6;
    uint256 public constant DAY_END_HOUR = 18;

    event Donate(address indexed donor,uint256 amount);
    event Withdraw(address indexed owner,uint256 amount);

    modifier onlyOwner(){
        require(msg.sender == owner, "BeggingContract: not owner");
        _;
    }
    modifier nonReentrant() {
        require(!_locked, "BeggingContract: reentrant call");
        _locked = true;
        _;
        _locked = false;
    }
    modifier onlyDayTime(){
        uint256 hourOfDay = (block.timestamp % 86400)/ 3600;
        require(hourOfDay>=DAY_START_HOUR && hourOfDay<=DAY_END_HOUR);
        _;
    }

    constructor(address _owner) {
        require(_owner != address(0), "BeggingContract: Invalid address");
        require(_owner != address(this), "BeggingContract: owner cannot be contract itself");

        owner = _owner;
    }

    function donate() external payable onlyDayTime{
        require(owner != msg.sender, "BeggingContract: Donor cannot be owner");
        require(msg.value>0, "BeggingContract: Amount must be positive");
        donorRecord[msg.sender]+=msg.value;

        emit Donate(msg.sender,msg.value);
    }

    function getDonation(address donor) public view returns (uint256){
        return donorRecord[donor];
    }

    function withdraw() public onlyOwner nonReentrant{
        uint256 amount = address(this).balance;
        require(amount > 0, "BeggingContract: nothing to withdraw");
        (bool success,) = owner.call{value: amount}("");
        require(success, "BeggingContract: withdrawal failed");
        emit Withdraw(owner,amount);
    }
}
