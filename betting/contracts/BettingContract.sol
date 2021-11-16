// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity 0.5.0;

import "./BettingOracleInterface.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";

contract BettingContract is Ownable {
    event ResultUpdatedEvent(string result);
    event ReceivedCheckResultEvent(uint256 id);
    BettingOracleInterface private oracleInstance;
    address private oracleAddress;

    mapping(uint256 => bool) myRequests;
    mapping(address => Bet) userToBets;
    mapping(uint256 => uint256) betsToCount;
    Bet[] bets;
    uint256 result = 3; // result has not been declared
    struct Bet {
        address user;
        uint256 bet;
        uint256 amount;
    }

    function setOracleInstanceAddress(address _oracleInstanceAddress)
        public
        onlyOwner
    {
        oracleAddress = _oracleInstanceAddress;
        oracleInstance = BettingOracleInterface(oracleAddress);
    }

    function userExists(address _user) private view returns (bool) {
        for (uint256 i = 0; i < bets.length; i++) {
            if (bets[i].user == _user) {
                return true;
            }
        }
        return false;
    }

    modifier isBetValid(address _user, uint256 bet) {
        require(!userExists(_user), "User already has a bet");
        require(bet == 0 || bet == 1, "Choose bet from 0 or 1");
        _;
    }

    function placeBet(uint256 _bet)
        external
        payable
        isBetValid(msg.sender, _bet)
    {
        require(msg.value > 0, "Place a bet with valid amount");
        Bet memory bet = Bet(msg.sender, _bet, msg.value);
        bets.push(bet);
        userToBets[msg.sender] = bet;
        betsToCount[_bet]++;
    }

    function getBetForUser() public view returns (Bet memory) {
        require(userExists(msg.sender), "User has not placed any bet");
        return userToBets[msg.sender];
    }

    function getAllBets() public view onlyOwner returns (Bet[] memory) {
        return bets;
    }

    function callback(uint256 _result, address _user ,uint256 _id) public onlyOracle {
        require(myRequests[_id], "This request is not in my pending list.");
        result = _result;
        delete myRequests[_id];

        calculateWinnings();
        if (userToBets[_user].bet == result) {
            emit ResultUpdatedEvent("You have won the bet");
        } else {
            emit ResultUpdatedEvent("You have lose the bet");
        }
    }

    modifier onlyOracle() {
        require(
            msg.sender == oracleAddress,
            "You are not authorized to call this function."
        );
        _;
    }

    function checkResult() public {
        //require(userExists(msg.sender), "User has not placed any bet");
        if (result == 3) {
            uint256 id = oracleInstance.getBetResult();
            myRequests[id] = true;
            emit ReceivedCheckResultEvent(id);
        }

        // calculateWinnings();
        // if(userToBets[msg.sender].bet == result){
        //   return 'You have won the bet';

        // }else {
        //   return 'You have lose the bet';
        // }
    }

    function calculateWinnings() private {
        uint256 totalLosingAmount = 0;
        for (uint256 i = 0; i < bets.length; i++) {
            if (bets[i].bet != result) {
                totalLosingAmount += bets[i].amount;
            }
        }

        uint256 losingCount = bets.length - betsToCount[result];
        uint256 additionAmount = totalLosingAmount / losingCount;

        for (uint256 i = 0; i < bets.length; i++) {
            if (bets[i].bet == result) {
                uint256 finalAmount = bets[i].amount + additionAmount;
                payOutWinnings(bets[i].user, finalAmount);
            }
        }
    }

    function payOutWinnings(address _user, uint256 _amount) private {
        address payable addr = address(uint160(_user));
        addr.transfer(_amount);
    }
}
