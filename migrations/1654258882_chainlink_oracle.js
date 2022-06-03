var ChainlinkOracle = artifacts.require("ChainlinkOracle");

module.exports = function(deployer) {
  deployer.deploy(ChainlinkOracle);
};
