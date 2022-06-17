const ChainlinkOracle = artifacts.require("ChainlinkOracle");
const Utils = artifacts.require("Utils");


module.exports = function(deployer, network) {
  if (network === 'test') return
  if (!process.env.FEED_ADDRESS) throw(new Error('FEED_ADDRESS is not set'));

  deployer.deploy(Utils);
  deployer.link(Utils, ChainlinkOracle);
  deployer.deploy(ChainlinkOracle, process.env.FEED_ADDRESS);
};
