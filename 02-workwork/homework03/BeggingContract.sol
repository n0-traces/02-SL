// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract BeggingContract {
    // Owner of the contract
    address public owner;

    // Record of donations per donor address
    mapping(address => uint256) private addressToDonationAmount;

    // Donation event for logging
    event Donation(address indexed donor, uint256 amount);

    // Leaderboard storage for top 3 donors
    address[3] private topDonors;
    uint256[3] private topAmounts;

    // Time window controls: donations allowed only between startTime and endTime (inclusive)
    uint256 public startTime;
    uint256 public endTime;

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier withinDonationWindow() {
        // If startTime and endTime are zero, treat as always open
        if (startTime != 0 || endTime != 0) {
            require(block.timestamp >= startTime, "Donations not started");
            require(block.timestamp <= endTime, "Donations ended");
        }
        _;
    }

    constructor(uint256 _startTime, uint256 _endTime) {
        owner = msg.sender;
        startTime = _startTime;
        endTime = _endTime;
        require(_endTime == 0 || _endTime >= _startTime, "Invalid time window");
    }

    // Allow receiving plain ether transfers as donations as well
    receive() external payable {
        _donate();
    }

    fallback() external payable {
        if (msg.value > 0) {
            _donate();
        }
    }

    // Public donate function
    function donate() external payable withinDonationWindow {
        _donate();
    }

    function _donate() internal withinDonationWindow {
        require(msg.value > 0, "No ether");

        address donor = msg.sender;
        uint256 newAmount = addressToDonationAmount[donor] + msg.value;
        addressToDonationAmount[donor] = newAmount;

        _updateLeaderboard(donor, newAmount);
        emit Donation(donor, msg.value);
    }

    // Owner can withdraw all funds
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds");
        payable(owner).transfer(balance);
    }

    // Query a donor's total donation amount
    function getDonation(address donor) external view returns (uint256) {
        return addressToDonationAmount[donor];
    }

    // Get top 3 donors and amounts
    function getTopDonors() external view returns (address[3] memory, uint256[3] memory) {
        return (topDonors, topAmounts);
    }

    // Owner can update the donation window
    function setDonationWindow(uint256 _startTime, uint256 _endTime) external onlyOwner {
        require(_endTime == 0 || _endTime >= _startTime, "Invalid time window");
        startTime = _startTime;
        endTime = _endTime;
    }

    function _updateLeaderboard(address donor, uint256 totalAmount) private {
        // Check if donor is already in leaderboard and update amount
        for (uint256 i = 0; i < 3; i++) {
            if (topDonors[i] == donor) {
                topAmounts[i] = totalAmount;
                _reorderLeaderboard();
                return;
            }
        }

        // If not present, check if qualifies to be inserted
        for (uint256 i = 0; i < 3; i++) {
            if (totalAmount > topAmounts[i]) {
                // Insert at position i by shifting down
                for (uint256 j = 2; j > i; j--) {
                    topDonors[j] = topDonors[j - 1];
                    topAmounts[j] = topAmounts[j - 1];
                }
                topDonors[i] = donor;
                topAmounts[i] = totalAmount;
                return;
            }
        }
    }

    function _reorderLeaderboard() private {
        // Simple bubble-up since only 3 elements
        for (uint256 i = 0; i < 2; i++) {
            for (uint256 j = 0; j < 2 - i; j++) {
                if (topAmounts[j] < topAmounts[j + 1]) {
                    (topAmounts[j], topAmounts[j + 1]) = (topAmounts[j + 1], topAmounts[j]);
                    (topDonors[j], topDonors[j + 1]) = (topDonors[j + 1], topDonors[j]);
                }
            }
        }
    }
}

