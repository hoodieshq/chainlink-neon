// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "solidity-bytes-utils/contracts/BytesLib.sol";
import "./external/QueryAccount.sol";

library Utils {
    using BytesLib for bytes;

    struct Round {
        uint32 roundId;
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
    uint8 private constant TRANSMISSION_SIZE = 48;
    uint8 private constant TRANSMISSION_TIMESTAMP_OFFSET = 8;
    uint8 private constant TRANSMISSION_ANSWER_OFFSET = 16;

    struct Header {
        uint8 decimals;
        string description;
        uint8 version;
        uint32 latestRoundId;
        uint32 liveLength;
        uint32 liveCursor;
        uint32 historicalCursor;
        uint8 granularity;
    }

    uint8 private constant DISCRIMINATOR_SIZE = 8;
    // https://github.com/smartcontractkit/chainlink-solana/blob/466d7d1795ac665c02cb382ae2a42c3951c7b40c/contracts/programs/store/src/state.rs#L5
    uint8 private constant HEADER_SIZE = 192;

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
    uint8 private constant HEADER_VERSION_OFFSET = 0;
    uint8 private constant HEADER_DESCRIPTION_OFFSET = 98;
    uint8 private constant HEADER_DESCRIPTION_LENGTH = 32;
    uint8 private constant HEADER_DECIMALS_OFFSET = 130;
    uint8 private constant HEADER_LATEST_ROUND_ID_OFFSET = 135;
    uint8 private constant HEADER_GRANULARITY_OFFSET = 139;
    uint8 private constant HEADER_LIVE_LENGTH_OFFSET = 140;
    uint8 private constant HEADER_LIVE_CURSOR_OFFSET = 144;
    uint8 private constant HEADER_HISTORICAL_CURSOR_OFFSET = 148;

    function getHeader(uint256 feedAddress) public view returns (Header memory) {
        require(QueryAccount.cache(feedAddress, DISCRIMINATOR_SIZE, HEADER_SIZE), "failed to update cache");

        (bool success, bytes memory rawTransmissions) = QueryAccount.data(feedAddress, DISCRIMINATOR_SIZE, HEADER_SIZE);
        require(success, "failed to query account data");

        return extractHeader(rawTransmissions);
    }

    function getLatestRound(uint256 feedAddress) public view returns (Round memory) {
        Header memory header = getHeader(feedAddress);

        // Latest round is the previous one before the live cursor. Handle ringbuffer wraparound.
        uint32 latestRoundCursor = leftShiftRingbufferCursor(header.liveCursor, 1, header.liveLength);
        uint32 latestRoundOffset = DISCRIMINATOR_SIZE + HEADER_SIZE + TRANSMISSION_SIZE * latestRoundCursor;

        return getRound(feedAddress, latestRoundOffset, header.latestRoundId);
    }

    function getRoundbyId(uint256 feedAddress, uint32 _roundId, uint32 historicalLength) public view returns (Round memory) {
        Header memory header = getHeader(feedAddress);
        (uint32 roundPosition, uint32 roundId) = locateRound(
            _roundId,
            header.liveCursor,
            header.liveLength,
            header.latestRoundId,
            header.historicalCursor,
            historicalLength,
            header.granularity
        );
        uint32 roundOffset = DISCRIMINATOR_SIZE + HEADER_SIZE + TRANSMISSION_SIZE * roundPosition;

        return getRound(feedAddress, roundOffset, roundId);
    }

    function locateRound(
        uint32 roundId,
        uint32 liveCursor,
        uint32 liveLength,
        uint32 latestRoundId,
        uint32 historicalCursor,
        uint32 historicalLength,
        uint8 granularity
    )
        public
        pure
        returns (
            uint32 position,
            uint32 correctedRoundId
        )
    {
        uint32 liveStartRoundId = saturatingSub(latestRoundId, liveLength - 1);
        uint32 historicalEndRoundId = latestRoundId - (latestRoundId % granularity);
        uint32 historicalStartRoundId = saturatingSub(historicalEndRoundId, granularity * saturatingSub(historicalLength, 1));

        // If withing the live range, fetch from it. Otherwise, fetch from the closest previous in history.
        if (roundId >= liveStartRoundId && roundId <= latestRoundId) {
            correctedRoundId = roundId;
            // + 1 because we're looking for the element before the cursor
            uint32 offset = latestRoundId - correctedRoundId + 1;

            position = leftShiftRingbufferCursor(liveCursor, offset, liveLength);
        } else if (roundId >= historicalStartRoundId && roundId <= historicalEndRoundId) {
            // Find the closest previous round
            correctedRoundId = roundId - (roundId % granularity);
            // + 1 because we're looking for the element before the cursor
            uint32 offset = (historicalEndRoundId - correctedRoundId) / granularity + 1;

            position = liveLength + leftShiftRingbufferCursor(historicalCursor, offset, historicalLength);
        } else {
            revert("No data present");
        }
    }

    function getHistoricalLength(uint256 feedAddress, uint32 liveLength) public view returns (uint32) {
        // `QueryAccount.length` requires preliminary caching of account data no matter of the cache lenght.
        require(QueryAccount.cache(feedAddress, 0, 1), "failed to update cache");

        (bool success, uint256 feedDataLength) = QueryAccount.length(feedAddress);
        require(success, "failed to query account length");

        return uint32(feedDataLength - DISCRIMINATOR_SIZE - HEADER_SIZE) / TRANSMISSION_SIZE - liveLength;
    }

    // Ringbuffer helpers

    function leftShiftRingbufferCursor(uint32 currentCursor, uint32 leftShiftItems, uint32 length) public pure returns (uint32) {
        require(currentCursor < length, "currentCursor is out of bounds");
        require(leftShiftItems <= length, "left shift is out of bounds");

        return (currentCursor + length - leftShiftItems ) % length;
    }

    // Data extraction helpers

    function getRound(uint256 feedAddress, uint32 offset, uint32 roundId) private view returns (Round memory) {
        require(QueryAccount.cache(feedAddress, offset, TRANSMISSION_SIZE), "failed to update cache");

        (bool success, bytes memory rawTransmission) = QueryAccount.data(feedAddress, offset, TRANSMISSION_SIZE);
        require(success, "failed to query account data");

        return extractRound(roundId, rawTransmission);
    }

    function extractRound(uint32 roundId, bytes memory rawTransmission) public pure returns (Round memory) {
        uint32 timestamp = readLittleEndianUnsigned32(rawTransmission.toUint32(TRANSMISSION_TIMESTAMP_OFFSET));

        // Ported behaviour
        // https://github.com/smartcontractkit/chainlink/blob/026e9a69dbcb057123264392e1e5a0c2c03e96f0/contracts/src/v0.6/AggregatorFacade.sol#L203
        require(timestamp > 0, "No data present");

        int128 answer = readLittleEndianSigned128(rawTransmission.toUint128(TRANSMISSION_ANSWER_OFFSET));
        return Round(roundId, answer, timestamp);
    }

    function extractHeader(bytes memory rawTransmissions) public pure returns (Header memory) {
        return Header(
            rawTransmissions.toUint8(HEADER_DECIMALS_OFFSET),     // uint8 is identical in little and big endians
            bytesToString(rawTransmissions.slice(HEADER_DESCRIPTION_OFFSET, HEADER_DESCRIPTION_LENGTH)),
            rawTransmissions.toUint8(HEADER_VERSION_OFFSET),      // uint8 is identical in little and big endians
            readLittleEndianUnsigned32(rawTransmissions.toUint32(HEADER_LATEST_ROUND_ID_OFFSET)),
            readLittleEndianUnsigned32(rawTransmissions.toUint32(HEADER_LIVE_LENGTH_OFFSET)),
            readLittleEndianUnsigned32(rawTransmissions.toUint32(HEADER_LIVE_CURSOR_OFFSET)),
            readLittleEndianUnsigned32(rawTransmissions.toUint32(HEADER_HISTORICAL_CURSOR_OFFSET)),
            rawTransmissions.toUint8(HEADER_GRANULARITY_OFFSET)   // uint8 is identical in little and big endians
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

    // Saturating substraction helpers

    function saturatingSub(uint32 a, uint32 b) private pure returns (uint32) {
        if (a <= b) {
            return 0; // type(uint32).min
        }
        else {
            return a - b;
        }
    }
}
