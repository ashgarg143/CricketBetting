const BettingContract = artifacts.require("BettingContract");

module.exports = function (deployer) {
  deployer.deploy(BettingContract);
};
