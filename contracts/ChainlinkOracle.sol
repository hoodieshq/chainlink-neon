// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./libraries/Utils.sol";

contract ChainlinkOracle is AggregatorV3Interface {
    uint8 public decimals;
    uint256 public feedAddress;
    string public description;
    uint256 public version;
    uint32 private historicalLength;

    constructor(bytes32 _feedAddress) {
        feedAddress = uint256(_feedAddress);

        Utils.Header memory header = Utils.getHeader(feedAddress);
        version = header.version;
        description = header.description;
        decimals = header.decimals;
        // Save historical ringbuffer length for future use.
        historicalLength = Utils.getHistoricalLength(feedAddress, header.liveLength);
    }

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        Utils.Round memory round = Utils.getRoundbyId(feedAddress, uint32(_roundId), historicalLength);

        return (
            round.roundId,
            round.answer,
            round.timestamp,
            round.timestamp,
            round.roundId
        );
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        Utils.Round memory round = Utils.getLatestRound(feedAddress);

        return (
            round.roundId,
            round.answer,
            round.timestamp,
            round.timestamp,
            round.roundId
        );
    }
}
