// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { Utils } from "./libraries/Utils.sol";

contract ChainlinkOracle is AggregatorV3Interface {
    bytes32 public feedAddress;
    uint256 public version;
    string public description;
    uint8 public decimals;

    constructor(bytes32 _feedAddress, bool isOnNeonEVM) {
        feedAddress = _feedAddress;

        if (isOnNeonEVM) {
            Utils.Header memory header = Utils.getHeader(feedAddress);
            version = header.version;
            description = header.description;
            decimals = header.decimals;
        }
    }

    function getRoundData(uint80)
        external
        pure
        returns (
            uint80,
            int256,
            uint256,
            uint256,
            uint80
        )
    {
        revert("getRoundData() not implemented");
    }

    function latestRoundData()
        external
        pure
        returns (
            uint80,
            int256,
            uint256,
            uint256,
            uint80
        )
    {
        revert("latestRoundData() not implemented");
    }
}
