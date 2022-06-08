const ChainlinkOracle = artifacts.require("ChainlinkOracle");

contract("ChainlinkOracle", () => {
  it('should set feed address from the contract', async () => {
    contract = await ChainlinkOracle.new("0xb22f4bfe7b663a29da31c40b32ab0b6f96c8ab1946c517b2c056710a352719ad")

    let feedAddress = await contract.feedAddress();
    assert.equal(feedAddress, "0xb22f4bfe7b663a29da31c40b32ab0b6f96c8ab1946c517b2c056710a352719ad")
  });
});
