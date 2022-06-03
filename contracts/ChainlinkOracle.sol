// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "solidity-bytes-utils/contracts/BytesLib.sol";

contract ChainlinkOracle {
    using BytesLib for bytes;

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
    uint private constant transmissionTimestampOffset = 8;  // slot:8
    uint private constant transmissionAnswerOffset  = 16;   // slot:8 + timestamp:4 + _padding0:4

    function getRoundData(bytes memory transmission) public pure returns (uint32 timestamp, int128 answer) {
        timestamp = readLittleEndianUnsigned32(transmission.toUint32(transmissionTimestampOffset));
        answer = readLittleEndianSigned128(transmission.toUint128(transmissionAnswerOffset));
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
