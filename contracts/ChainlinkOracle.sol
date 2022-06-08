// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "solidity-bytes-utils/contracts/BytesLib.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ChainlinkOracle is AggregatorV3Interface {
    using BytesLib for bytes;

    struct Round {
        uint80 roundId;
        int128 answer;
        uint32 timestamp;
    }

    struct Header {
        uint8 decimals;
        string description;
        uint256 version;
    }

    bytes32 public feedAddress;

    /*
        pub struct Transmission {
            pub slot: u64,
            pub timestamp: u32,
            pub _padding0: u32,
            pub answer: i128,
            pub _padding1: u64,
            pub _padding2: u64,
        }
    */
    uint8 private constant transmissionTimestampOffset = 8;  // slot:8
    uint8 private constant transmissionAnswerOffset = 16;    // slot:8 + timestamp:4 + _padding0:4

    /*
        pub struct Transmissions {
            pub version: u8,
            pub state: u8,
            pub owner: Pubkey,
            pub proposed_owner: Pubkey,
            pub writer: Pubkey,
            /// Raw UTF-8 byte string
            pub description: [u8; 32],
            pub decimals: u8,
            pub flagging_threshold: u32,
            pub latest_round_id: u32,
            pub granularity: u8,
            pub live_length: u32,
            live_cursor: u32,
            historical_cursor: u32,
        }
    */
    uint8 private constant headerVersionOffset = 0;
    uint8 private constant headerDescriptionOffset = 98;    // version:1 + state:1 + owner:32 + proposed_owner:32 + writer:32
    uint8 private constant headerDescriptionLength = 32;
    uint8 private constant headerDecimalsOffset = 130;      // version:1 + state:1 + owner:32 + proposed_owner:32 + writer:32 + description:32

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

    // Data extraction helpers

    function extractRound(uint80 roundId, bytes memory rawTransmission) public pure returns (Round memory) {
        uint32 timestamp = readLittleEndianUnsigned32(rawTransmission.toUint32(transmissionTimestampOffset));
        int128 answer = readLittleEndianSigned128(rawTransmission.toUint128(transmissionAnswerOffset));
        return Round(roundId, answer, timestamp);
    }

    function extractHeader(bytes memory rawTransmissions) public pure returns (Header memory) {
        return Header(
            rawTransmissions.toUint8(headerDecimalsOffset),
            bytesToString(rawTransmissions.slice(headerDescriptionOffset,headerDescriptionLength)),
            rawTransmissions.toUint8(headerVersionOffset)
        );
    }

    function bytesToString(bytes memory _bytes) private pure returns (string memory) {
        uint8 length = 0;
        while(_bytes[length] != 0) {
            length++;
        }

        bytes memory bytesArray = new bytes(length);
        for (uint8 i = 0; i < length; i++) {
            bytesArray[i] = _bytes[i];
        }

        return string(bytesArray);
    }

    // Little endian helpers

    function readLittleEndianUnsigned32(uint32 input) private pure returns (uint32) {
        input = ((input & 0xFF00FF00) >> 8) | ((input & 0x00FF00FF) << 8);
        return uint32(input << 16) | (input >> 16);
    }

    function readLittleEndianSigned128(uint128 input) private pure returns (int128) {
        input = ((input << 8) & 0xFF00FF00FF00FF00FF00FF00FF00FF00) | ((input >> 8) & 0x00FF00FF00FF00FF00FF00FF00FF00FF);
        input = ((input << 16) & 0xFFFF0000FFFF0000FFFF0000FFFF0000) | ((input >> 16) & 0x0000FFFF0000FFFF0000FFFF0000FFFF);
        input = ((input << 32) & 0xFFFFFFFF00000000FFFFFFFF00000000) | ((input >> 32) & 0x00000000FFFFFFFF00000000FFFFFFFF);
        return int128((input << 64) | ((input >> 64) & 0xFFFFFFFFFFFFFFFF));
    }
}
