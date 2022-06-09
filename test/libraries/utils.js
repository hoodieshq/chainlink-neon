const Utils = artifacts.require("Utils");

contract("Utils", () => {
  let utils;

  beforeEach(async () => {
    utils = await Utils.deployed();
  });

  describe(".extractRound", () => {
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
      "00000000000000000000000000000000";

    const _roundId = 31337;

    it('should set round id', async () => {
      let { roundId } = await utils.extractRound(_roundId, transmission);

      assert.equal(roundId, _roundId);
    });

    it('should extract timestamp of a round from transmission struct data', async () => {
      let { timestamp } = await utils.extractRound(_roundId, transmission);

      assert.equal(timestamp, 1654260800);
    });

    it('should extract answer of a round from transmission struct data', async () => {
      let { answer } = await utils.extractRound(_roundId, transmission);

      assert.equal(answer, 176139103829);
    });
  });

  describe(".extractRound", () => {
    /*
      Raw Header data sample:

      version: u8 = 2
      state: u8 = 1
      owner: Pubkey
      proposed_owner: Pubkey
      writer: Pubkey
      description: [u8; 32] = "ETH / USD"
      decimals: u8 = 8
      flagging_threshold: u32
      latest_round_id: u32 = 1638131
      granularity: u8 = 30
      live_length: u32 = 1024
      live_cursor: u32 = 755
      historical_cursor: u32 = 54604
    */
    const header = "0x" +
      "020111d3be3f3544f970bd6fd0d49cc6" +
      "9cd3ea549b220b34c874ede871afe057" +
      "550f0000000000000000000000000000" +
      "00000000000000000000000000000000" +
      "00006c6670e4187ad830d9c44710b498" +
      "044edee2e3d2c1512d030b73cebdc092" +
      "fc3e455448202f205553440000000000" +
      "00000000000000000000000000000000" +
      "00000800000000f3fe18001e00040000" +
      "f30200004cd500000000000000000000" +
      "00000000000000000000000000000000" +
      "00000000000000000000000000000000"

    it('should extract version of a feed from header struct data', async () => {
      let { version } = await utils.extractHeader(header);

      assert.equal(version, 2);
    });

    it('should extract description of a feed from header struct data', async () => {
      let { description } = await utils.extractHeader(header);

      assert.equal(description, "ETH / USD");
    });

    it('should extract decimals of a feed from header struct data', async () => {
      let { decimals } = await utils.extractHeader(header);

      assert.equal(decimals, 8);
    });

    it('should extract latest round id from header struct data', async () => {
      let { latestRoundId } = await utils.extractHeader(header);

      assert.equal(latestRoundId, 1638131);
    });

    it('should extract length of the live ring buffer from header struct data', async () => {
      let { liveLength } = await utils.extractHeader(header);

      assert.equal(liveLength, 1024);
    });

    it('should extract cursor of the live ring buffer from header struct data', async () => {
      let { liveCursor } = await utils.extractHeader(header);

      assert.equal(liveCursor, 755);
    });
  });
});
