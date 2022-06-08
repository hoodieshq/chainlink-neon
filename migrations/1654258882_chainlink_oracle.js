const ChainlinkOracle = artifacts.require("ChainlinkOracle");

const feedAddress = process.env.FEED_ADDRESS || "0xb22f4bfe7b663a29da31c40b32ab0b6f96c8ab1946c517b2c056710a352719ad"

module.exports = function(deployer) {
  deployer.deploy(ChainlinkOracle, feedAddress);
};
