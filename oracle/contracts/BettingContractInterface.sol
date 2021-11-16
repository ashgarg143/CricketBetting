pragma solidity 0.5.0;

contract BettingContractInterface {
    function callback(uint256 result, address user, uint256 id) public;
}
