// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {
    GeneralRandcastConsumerBase,
    BasicRandcastConsumerBase
} from "Randcast-User-Contract/user/GeneralRandcastConsumerBase.sol";

contract CardGame is GeneralRandcastConsumerBase {
    event RandomnessRequested(bytes32 requestId);
    event RandomnessFulfilled(bytes32 indexed requestId, uint256 randomness);

    // solhint-disable-next-line no-empty-blocks
    constructor(address adapter) BasicRandcastConsumerBase(adapter) {}

    /**
     * Requests randomness
     */
    function getRandomSeed() external {
        bytes memory params;
        bytes32 requestId = _requestRandomness(RequestType.Randomness, params);
        emit RandomnessRequested(requestId);
    }

    /**
     * Callback function used by Randcast Adapter
     */
    function _fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        emit RandomnessFulfilled(requestId, randomness);
    }
}
