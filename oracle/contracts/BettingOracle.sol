pragma solidity 0.5.0;

import "./BettingContractInterface.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";

contract BettingOracle is Ownable {
    mapping(uint256 => bool) pendingRequests;
    event GetBetResultEvent(address callerAddress, uint256 id, uint result);
    event SetBetResultEvent(uint256 result, address callerAddress);

    uint256 nounce = 0;
    uint256 modulus = 2;

    function getRandomNumber() private returns (uint256) {
        nounce++;
        return uint256(keccak256(abi.encodePacked(now, msg.sender, nounce)));
    }

    function getBetResult() public returns (uint256) {
        uint256 randomNumber = getRandomNumber();
        uint256 result = randomNumber % modulus;
        pendingRequests[randomNumber] = true;
        emit GetBetResultEvent(msg.sender, randomNumber, result);
        return randomNumber;
    }

    function setBetResult(
        uint256 _result,
        address _callerAddress,
        uint256 _id
    ) public onlyOwner {
        require(
            pendingRequests[_id],
            "This request is not in my pending list."
        );
        delete pendingRequests[_id];
        BettingContractInterface bettingContractInstance;
        bettingContractInstance = BettingContractInterface(_callerAddress);
        bettingContractInstance.callback(_result, msg.sender, _id);
        emit SetBetResultEvent(_result, _callerAddress);
    }
}
