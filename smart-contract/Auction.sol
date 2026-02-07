// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NFTDutchAuction {
    uint256 public constant START_PRICE = 0.05 ether; 
    uint256 public constant FLOOR_PRICE = 0.02 ether; 
    uint256 public constant DISCOUNT_RATE = 0.0001 ether; 
    
    uint256 public startAt; 
    bool public ended;
    address public administrator;
    
    // Stores the link to your IPFS folder (e.g., "ipfs://QmXyZ.../")
    string public baseURI; 

    // Ledger of who owns what: ID 5 -> Alice's Address
    mapping(uint256 => address) public owners;

    constructor() {
        administrator = msg.sender;
    }

    // --- ADMIN TOOLS ---
    function startAuction() external {
        require(msg.sender == administrator, "Only Admin!");
        require(startAt == 0, "Already started!");
        startAt = block.timestamp;
    }

    function endAuction() external {
        require(msg.sender == administrator, "Only Admin!");
        ended = true;
    }

    // Set the folder where images live (The "Reveal")
    function setBaseURI(string memory _newURI) external {
        require(msg.sender == administrator, "Only Admin!");
        baseURI = _newURI;
    }

    function withdraw() external {
        require(msg.sender == administrator, "Only Admin!");
        (bool success, ) = payable(administrator).call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }

    // --- PUBLIC TOOLS ---
    function getPrice() public view returns (uint256) {
        if (startAt == 0) return START_PRICE;
        if (ended) return 0;

        uint256 timeElapsed = block.timestamp - startAt;
        uint256 discount = DISCOUNT_RATE * timeElapsed;
        uint256 currentPrice = START_PRICE > discount ? START_PRICE - discount : 0;
        return currentPrice < FLOOR_PRICE ? FLOOR_PRICE : currentPrice;
    }

    function buy(uint256 _id) external payable {
        require(startAt != 0, "Class hasn't started!");
        require(!ended, "Auction stopped!");
        require(_id < 100, "Invalid ID");
        require(owners[_id] == address(0), "Item sold");
        
        // REMOVED: Fairness limit. Whales can now sweep the floor.

        uint256 price = getPrice();
        require(msg.value >= price, "Bid too low");

        owners[_id] = msg.sender;

        uint256 refund = msg.value - price;
        if (refund > 0) {
            (bool success, ) = payable(msg.sender).call{value: refund}("");
            require(success, "Refund failed");
        }
    }

    function getOwner(uint256 _id) external view returns (address) {
        return owners[_id];
    }
}