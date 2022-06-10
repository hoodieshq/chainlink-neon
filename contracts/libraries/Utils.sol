// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "solidity-bytes-utils/contracts/BytesLib.sol";
import "./external/QueryAccount.sol";

library Utils {
    using BytesLib for bytes;

    struct Round {
        uint80 roundId;
        int128 answer;
        uint32 timestamp;
    }

    /*
        https://github.com/smartcontractkit/chainlink-solana/blob/466d7d1795ac665c02cb382ae2a42c3951c7b40c/contracts/programs/store/src/state.rs#L25-L32

        pub struct Transmission {
            pub slot: u64,                  8
            pub timestamp: u32,             4
            pub _padding0: u32,             4
            pub answer: i128,               16
            pub _padding1: u64,             8
            pub _padding2: u64,             8
        }
    */
    uint8 private constant transmissionSize = 48;
    uint8 private constant transmissionTimestampOffset = 8;
    uint8 private constant transmissionAnswerOffset = 16;

    // For publicly exposed fields data types are preserved according to the AggregatorV3Interface signature. The rest
    // are kept the same as in Transmissions struct for simplicity.
    struct Header {
        // Publicly exposed
        uint8 decimals;
        string description;
        uint256 version;
        uint80 latestRoundId;
        // Internal
        uint32 liveLength;
        uint32 liveCursor;
    }

    uint8 private constant descriminatorSize = 8;
    // https://github.com/smartcontractkit/chainlink-solana/blob/466d7d1795ac665c02cb382ae2a42c3951c7b40c/contracts/programs/store/src/state.rs#L5
    uint8 private constant headerSize = 192;

    /*
        https://github.com/smartcontractkit/chainlink-solana/blob/466d7d1795ac665c02cb382ae2a42c3951c7b40c/contracts/programs/store/src/state.rs#L47-L62

        pub struct Transmissions {
            pub version: u8,                1
            pub state: u8,                  1
            pub owner: Pubkey,              32
            pub proposed_owner: Pubkey,     32
            pub writer: Pubkey,             32
            /// Raw UTF-8 byte string
            pub description: [u8; 32],      32
            pub decimals: u8,               1
            pub flagging_threshold: u32,    4
            pub latest_round_id: u32,       4
            pub granularity: u8,            1
            pub live_length: u32,           4
            live_cursor: u32,               4
            historical_cursor: u32,         4
        }
    */
    uint8 private constant headerVersionOffset = 0;
    uint8 private constant headerDescriptionOffset = 98;
    uint8 private constant headerDescriptionLength = 32;
    uint8 private constant headerDecimalsOffset = 130;
    uint8 private constant headerLatestRoundIdOffset = 135;
    uint8 private constant headerLiveLength = 140;
    uint8 private constant headerLiveCursor = 144;

    function getHeader(bytes32 _feedAddress) public view returns (Header memory) {
        uint256 feedAddress = uint256(_feedAddress);

        require(QueryAccount.cache(feedAddress, descriminatorSize, headerSize), "failed to update cache");

        (bool success, bytes memory rawTransmissions) = QueryAccount.data(feedAddress, descriminatorSize, headerSize);
        require(success, "failed to query account data");

        return extractHeader(rawTransmissions);
    }

    function getLatestRound(bytes32 _feedAddress) public view returns (Round memory) {
        uint256 feedAddress = uint256(_feedAddress);
        Header memory header = getHeader(_feedAddress);

        // Latest round is the previous one before the live cursor. Handle ringbuffer wraparound.
        uint32 latestRoundCursor = leftShiftRingbufferCursor(header.liveCursor, 1, header.liveLength);
        uint32 latestRoundOffset = descriminatorSize + headerSize + transmissionSize * latestRoundCursor;

        require(QueryAccount.cache(feedAddress, latestRoundOffset, transmissionSize), "failed to update cache");

        (bool success, bytes memory rawTransmission) = QueryAccount.data(feedAddress, latestRoundOffset, transmissionSize);
        require(success, "failed to query account data");

        return extractRound(header.latestRoundId, rawTransmission);
    }

    // Ringbuffer helpers

    function leftShiftRingbufferCursor(uint32 currentCursor, uint32 leftShiftItems, uint32 length) public pure returns (uint32) {
        require(currentCursor < length, "currentCursor is out of bounds");
        require(leftShiftItems < length, "left shift is out of bounds");

        return (currentCursor + length - leftShiftItems ) % length;
    }

    // Data extraction helpers

    function extractRound(uint80 roundId, bytes memory rawTransmission) public pure returns (Round memory) {
        uint32 timestamp = readLittleEndianUnsigned32(rawTransmission.toUint32(transmissionTimestampOffset));
        int128 answer = readLittleEndianSigned128(rawTransmission.toUint128(transmissionAnswerOffset));
        return Round(roundId, answer, timestamp);
    }

    function extractHeader(bytes memory rawTransmissions) public pure returns (Header memory) {
        return Header(
            rawTransmissions.toUint8(headerDecimalsOffset), // uint8 is identical in little and big endians
            bytesToString(rawTransmissions.slice(headerDescriptionOffset,headerDescriptionLength)),
            rawTransmissions.toUint8(headerVersionOffset),  // uint8 is identical in little and big endians
            readLittleEndianUnsigned32(rawTransmissions.toUint32(headerLatestRoundIdOffset)),
            readLittleEndianUnsigned32(rawTransmissions.toUint32(headerLiveLength)),
            readLittleEndianUnsigned32(rawTransmissions.toUint32(headerLiveCursor))
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
