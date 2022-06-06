const ChainlinkOracle = artifacts.require("ChainlinkOracle");

contract("ChainlinkOracle", () => {
  let oracle

  beforeEach(async () => {
    oracle = await ChainlinkOracle.deployed();
  });

  describe(".getRoundData", function () {
    /*
      Raw Transmission data sample:

      slot: u64 = 138620452,
      timestamp: u32 = 1654260800,
      _padding0: u32 = 0,
      answer: i128 = 176139103829,
      _padding1: u64 = 0,
      _padding2: u64 = 0,
    */
    const transmission = "0x" +
      "242e43080000000040049a6200000000" +
      "556eb502290000000000000000000000" +
      "00000000000000000000000000000000"

    it('should extract timestamp of a round from transmission struct data', async () => {
      let { timestamp } = await oracle.getRoundData(transmission);

      assert.equal(timestamp, 1654260800);
    });

    it('should extract answer of a round from transmission struct data', async () => {
      let { answer } = await oracle.getRoundData(transmission);

      assert.equal(answer, 176139103829);
    });
  });
});
