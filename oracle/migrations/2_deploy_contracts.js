const BettingOracle = artifacts.require("BettingOracle");

module.exports = function (deployer) {
  deployer.deploy(BettingOracle);
};
