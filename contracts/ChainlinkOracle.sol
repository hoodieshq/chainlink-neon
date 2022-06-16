// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./libraries/Utils.sol";

contract ChainlinkOracle is AggregatorV3Interface {
    bytes32 public feedAddress;
    uint256 public version;
    string public description;
    uint8 public decimals;

    constructor(bytes32 _feedAddress) {
        feedAddress = _feedAddress;

        Utils.Header memory header = Utils.getHeader(feedAddress);
        version = header.version;
        description = header.description;
        decimals = header.decimals;
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
        Utils.Round memory round = Utils.getRoundbyId(feedAddress, _roundId);

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
