const Utils = artifacts.require("Utils");

contract("Utils", () => {
  let utils;

  before(async () => {
    utils = await Utils.new();
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

    it('should extract cursor of the historical ring buffer from header struct data', async () => {
      let { historicalCursor } = await utils.extractHeader(header);

      assert.equal(historicalCursor, 54604);
    });

    it('should extract granularity of the historical ring buffer from header struct data', async () => {
      let { granularity } = await utils.extractHeader(header);

      assert.equal(granularity, 30);
    });
  });

  describe(".leftShiftRingbufferCursor", () => {
    const length = 1024;

    it('left shifts cursor by the number of steps', async () => {
      let cursor = await utils.leftShiftRingbufferCursor(100, 1, length);

      assert.equal(cursor, 99);
    });

    it('takes into account ringbuffer wraparound', async () => {
      let cursor = await utils.leftShiftRingbufferCursor(0, 1, length);

      assert.equal(cursor, 1023);
    });
  })

  describe(".locateRound", () => {

    // Transmissions layout
    // 0   1   2   3   4   5   6   7   8   9   10  11  12  13  14
    // | Live            | Historical
    // 0   1   2   3   4 | 0   1   2   3   4   5   6   7   8   9
    // 36  37  38  34  35| 33  36  9   12  15  18  21  24  27  30
    //             ^               ^
    //             liveCursor      historicalCursor

    const liveCursor = 3
    const liveLength = 5
    const latestRoundId = 38
    const historicalCursor = 2
    const historicalLength = 10
    const granularity = 3

    async function locate(roundId) {
      return utils.locateRound(
        roundId,
        liveCursor,
        liveLength,
        latestRoundId,
        historicalCursor,
        historicalLength,
        granularity
      );
    }

    describe('when round is out of range', async () => {
      it('reverts', async () => {
        try {
          await locate(42);
          throw null;
        }
        catch (error) {
          assert(error, "Expected an error but did not get one");
          assert(error.message.endsWith("No data present"));
        }
      });
    })

    describe('when round is within the live range', async () => {
      it('finds position to the left of the live cursor', async () => {
        const { position, correctedRoundId } = await locate(36);

        assert.equal(correctedRoundId, 36);
        assert.equal(position, 0);
      });

      it('finds position of the latest round', async () => {
        const { position, correctedRoundId } = await locate(38);

        assert.equal(correctedRoundId, 38);
        assert.equal(position, 2);
      });

      it('finds position to the right of the live cursor', async () => {
        const { position, correctedRoundId } = await locate(35);

        assert.equal(correctedRoundId, 35);
        assert.equal(position, 4);
      });
    })

    describe('when round is within the historical range', async () => {
      it('finds position to the left of the historical cursor', async () => {
        const { position, correctedRoundId } = await locate(33);

        assert.equal(correctedRoundId, 33);
        assert.equal(position, 5);
      });

      it('finds position to the right of the historical cursor', async () => {
        const { position, correctedRoundId } = await locate(15);

        assert.equal(correctedRoundId, 15);
        assert.equal(position, 9);
      });

      it('finds position and corrects round id according to granularity', async () => {
        const { position, correctedRoundId } = await locate(17);

        assert.equal(correctedRoundId, 15);
        assert.equal(position, 9);
      });

      it('finds position when historical cursor points to the round', async () => {
        const { position, correctedRoundId } = await locate(9);

        assert.equal(correctedRoundId, 9);
        assert.equal(position, 7);
      });
    })
  })
});
