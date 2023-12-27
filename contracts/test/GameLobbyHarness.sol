// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {GameLobby} from "../src/GameLobby.sol";

contract GameLobbyHarness is GameLobby {
    uint256 public randomnessRequestCount;

    constructor(address _prank) GameLobby(_prank) {}

    function exposed_fulfillRandomness(bytes32 requestId, uint256 randomness) external {
        _fulfillRandomness(requestId, randomness);
    }

    function _getRandomSeed(uint256 tableId, RandomnessRequest memory request)
        internal
        override
        returns (bytes32 requestId)
    {
        requestId = keccak256(
            abi.encode(0x46c67d94991023132faf3f9e770ecd33d68ab32d0090d4aa36bd53c895aa5bed, randomnessRequestCount)
        );
        randomnessRequests[requestId] = request;
        randomnessRequestCount++;
        emit RandomnessRequested(tableId, requestId, msg.sender, request.randomnessType);
    }
}
