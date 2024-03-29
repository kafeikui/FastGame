// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {GameFight} from "../src/library/GameFight.sol";

contract GameFightTest is Test {
    function testSimpleFight() public {
        // GameFight f = new GameFight();

        GameFight.PlayerState memory a = GameFight.PlayerState(
            0, 3000, 3000, 150, 100, 10, 10, 200, 100, 100, GameFight.Actionable.Normal, 0, new GameFight.Buff[](128)
        );
        GameFight.PlayerState memory b = GameFight.PlayerState(
            0, 3000, 3000, 150, 100, 10, 10, 200, 100, 100, GameFight.Actionable.Normal, 0, new GameFight.Buff[](128)
        );
        uint32[] memory aSequence = new uint32[](3);
        uint32[] memory bSequence = new uint32[](3);
        bool aFirst = true;
        uint256 randomness = uint256(keccak256(abi.encode(42)));

        bool awin;
        awin = GameFight.fight(a, b, aSequence, bSequence, aFirst, randomness);
        assertEq(awin, true);
        awin = GameFight.fight(a, b, aSequence, bSequence, !aFirst, randomness);
        assertEq(awin, false);
    }

    function testComplicatedFight() public {
        // GameFight f = new GameFight();

        GameFight.PlayerState memory a = GameFight.PlayerState(
            0, 12000, 12000, 600, 100, 10, 10, 200, 100, 100, GameFight.Actionable.Normal, 0, new GameFight.Buff[](128)
        );
        GameFight.PlayerState memory b = GameFight.PlayerState(
            0, 12000, 12000, 600, 100, 10, 10, 200, 100, 100, GameFight.Actionable.Normal, 0, new GameFight.Buff[](128)
        );
        // they are all of defense and heal sect cards of highest level which will result in a long fight
        uint32[] memory aSequence = new uint32[](7);
        aSequence[0] = 22 + 2 * (GameFight.MAX_CARD_ID + 1);
        aSequence[1] = 24 + 2 * (GameFight.MAX_CARD_ID + 1);
        aSequence[2] = 22 + 2 * (GameFight.MAX_CARD_ID + 1);
        aSequence[3] = 24 + 2 * (GameFight.MAX_CARD_ID + 1);
        aSequence[4] = 27 + 2 * (GameFight.MAX_CARD_ID + 1);
        aSequence[5] = 16 + 2 * (GameFight.MAX_CARD_ID + 1);
        aSequence[6] = 15 + 2 * (GameFight.MAX_CARD_ID + 1);
        uint32[] memory bSequence = new uint32[](7);
        bSequence[0] = 22 + 2 * (GameFight.MAX_CARD_ID + 1);
        bSequence[1] = 24 + 2 * (GameFight.MAX_CARD_ID + 1);
        bSequence[2] = 27 + 2 * (GameFight.MAX_CARD_ID + 1);
        bSequence[3] = 16 + 2 * (GameFight.MAX_CARD_ID + 1);
        bSequence[4] = 15 + 2 * (GameFight.MAX_CARD_ID + 1);
        bSequence[5] = 13 + 2 * (GameFight.MAX_CARD_ID + 1);
        bSequence[6] = 10 + 2 * (GameFight.MAX_CARD_ID + 1);
        bool aFirst = true;
        uint256 randomness = uint256(keccak256(abi.encode(42)));

        bool awin = GameFight.fight(a, b, aSequence, bSequence, !aFirst, randomness);
        emit log_named_uint("awin", awin ? 1 : 0);
    }
}
