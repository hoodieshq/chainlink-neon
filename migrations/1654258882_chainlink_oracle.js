const ChainlinkOracle = artifacts.require("ChainlinkOracle");
const Utils = artifacts.require("Utils");

const feedAddress = process.env.FEED_ADDRESS || "0xb22f4bfe7b663a29da31c40b32ab0b6f96c8ab1946c517b2c056710a352719ad"

module.exports = function(deployer, network) {
  if (network === 'test') return

  deployer.deploy(Utils);
  deployer.link(Utils, ChainlinkOracle);
  deployer.deploy(ChainlinkOracle, feedAddress);
};
