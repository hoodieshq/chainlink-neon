// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./libraries/Utils.sol";

contract ChainlinkOracle is AggregatorV3Interface {
    bytes32 public feedAddress;

    constructor(bytes32 _feedAddress) {
        feedAddress = _feedAddress;
    }

    function decimals() external pure returns (uint8) {
        revert("decimals() not implemented");
    }

    function description() external pure returns (string memory) {
        revert("description() not implemented");
    }

    function version() external pure returns (uint256) {
        revert("version() not implemented");
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
