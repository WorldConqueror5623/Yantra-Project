// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NFTDutchAuction {
    uint256 public constant START_PRICE = 0.05 ether; 
    uint256 public constant FLOOR_PRICE = 0.02 ether; 
    uint256 public constant DISCOUNT_RATE = 0.0001 ether; 
    
    uint256 public startAt; 
    bool public ended;
    address public administrator;

    mapping(uint256 => address) public owners;
    // NEW: Track who has already bought one
    mapping(address => bool) public hasBought; 

    constructor() {
        administrator = msg.sender;
    }

    function startAuction() external {
        require(msg.sender == administrator, "Only Admin can start!");
        require(startAt == 0, "Already started!");
        startAt = block.timestamp;
    }

    function endAuction() external {
        require(msg.sender == administrator, "Only Admin can end!");
        ended = true;
    }

    function getPrice() public view returns (uint256) {
        if (startAt == 0) return START_PRICE;
        if (ended) return 0;

        uint256 timeElapsed = block.timestamp - startAt;
        uint256 discount = DISCOUNT_RATE * timeElapsed;
        uint256 currentPrice = START_PRICE > discount ? START_PRICE - discount : 0;
        return currentPrice < FLOOR_PRICE ? FLOOR_PRICE : currentPrice;
    }

    function buy(uint256 _id) external payable {
        require(startAt != 0, "Not started yet!");
        require(!ended, "Auction stopped!");
        require(_id < 100, "Invalid ID");
        require(owners[_id] == address(0), "Item sold");
        
        // NEW: FAIRNESS CHECK
        require(!hasBought[msg.sender], "Limit 1 per wallet!"); 

        uint256 price = getPrice();
        require(msg.value >= price, "Bid too low");

        owners[_id] = msg.sender;
        hasBought[msg.sender] = true; // Mark them as having bought

        uint256 refund = msg.value - price;
        if (refund > 0) {
            payable(msg.sender).call{value: refund}("");
        }
    }

    // NEW: WITHDRAW FUNCTION (Get your money!)
    function withdraw() external {
        require(msg.sender == administrator, "Only Admin can withdraw");
        payable(administrator).transfer(address(this).balance);
    }

    function getOwner(uint256 _id) external view returns (address) {
        return owners[_id];
    }
}