// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {GameLobbyHarness, GameLobby} from "./GameLobbyHarness.sol";

contract GameLobbyHarnessTest is Test {
    address user1 = 0x0165878a594cA255338aDFa4D48449f69242eb1F;
    address user2 = 0x0bBDBF4bf1b6A54645a0fb393bCCbcceeFDfe1FA;
    address adapter = 0x0165878A594ca255338adfa4d48449f69242Eb8F;
    GameLobbyHarness gl;
    uint256 tableId;
    bytes32 requestId;

    function testCommitAndRevealSequence() public {
        GameLobby.RevealedCard[] memory sequence = new GameLobbyHarness.RevealedCard[](3);
        sequence[0] = GameLobby.RevealedCard(0, 2, 0xec00bdb86eb91e125702f870417c04c6d0c14e931340b0c6702304247ec13cd3);
        sequence[1] = GameLobby.RevealedCard(1, 2, 0xec00bdb86eb91e125702f870417c04c6d0c14e931340b0c6702304247ec13cd3);
        sequence[2] = GameLobby.RevealedCard(2, 3, 0xec00bdb86eb91e125702f870417c04c6d0c14e931340b0c6702304247ec13cd3);

        uint256 calculatedCommitment;
        uint256 jointCommitment;
        for (uint256 i = 0; i < sequence.length; i++) {
            emit log_named_bytes32(
                "commitment", keccak256(abi.encode(sequence[i].index, sequence[i].id, sequence[i].salt))
            );
            calculatedCommitment = uint256(keccak256(abi.encode(sequence[i].index, sequence[i].id, sequence[i].salt)));
            // emit log_named_uint("calculatedCommitment", calculatedCommitment);
            jointCommitment = uint256(keccak256(abi.encode(jointCommitment, calculatedCommitment)));
            emit log_named_bytes32("jointCommitment", bytes32(jointCommitment));
        }
    }

    function prepareTable() public {
        gl = new GameLobbyHarness(0x0165878A594ca255338adfa4d48449f69242Eb8F);
        vm.prank(user1);
        tableId = gl.createTable();
        vm.prank(user2);
        requestId = gl.joinTable(tableId);
        gl.exposed_fulfillRandomness(requestId, 0x46c67d94991023132faf3f9e770ecd33d68ab32d0090d4aa36bd53c895aa5bed);
    }

    function testCommitPickedCards() public {
        prepareTable();
        uint256[] memory commitments = new uint256[](3);
        commitments[0] = 0x04c5a571305ade74a86c76276f5776c2cdf2fc5d18219cde98a38551e4cb8af5;
        commitments[1] = 0xfc7600e0e9210881da5d4400eac53345e0e97b4ba476c2559fdc0abb1389e14b;
        commitments[2] = 0x63c86423d6717cded5f612c047607d9c60ffc778c581f23189f0dcdbafb6e9db;
        vm.prank(user1);
        gl.commitPickedCards(tableId, commitments);
        vm.prank(user2);
        gl.commitPickedCards(tableId, commitments);
    }

    function testUpgradeCard() public {
        testCommitPickedCards();
        // for (uint256 i = 0; i < 20; i++) {
        //     uint256 cardPool = gl.cardPools(tableId, 0, i);
        //     emit log_named_uint("cardPool", cardPool);
        // }
        GameLobby.RevealedCard[] memory material = new GameLobby.RevealedCard[](2);
        material[0] = GameLobby.RevealedCard(0, 2, 0xec00bdb86eb91e125702f870417c04c6d0c14e931340b0c6702304247ec13cd3);
        material[1] = GameLobby.RevealedCard(1, 2, 0xec00bdb86eb91e125702f870417c04c6d0c14e931340b0c6702304247ec13cd3);
        vm.prank(user1);
        gl.upgradeCard(tableId, material);
        showHands(tableId, user1);

        // uint256 randomness = 66325099237375448398629316405342488647054435602179032875269657032798587322100;
        // uint256 randomness = 0;
        // emit log_uint(randomness);
        // for (uint8 i = 0; i < 3; i++) {
        //     // uint256 index = uint256(keccak256(abi.encodePacked(randomness, i))) % 9;
        //     // emit log_uint(index);
        //     // emit log_uint(gl.MIDDLE_QUALITY_CARD_IDS(index));
        //     uint32 cardId =
        //         MIDDLE_QUALITY_CARD_IDS[uint256(keccak256(abi.encode(randomness, i))) % MIDDLE_QUALITY_CARD_IDS.length];
        //     emit log_uint(cardId);
        //     // emit log_uint(MIDDLE_QUALITY_CARD_IDS[cardId]);

        //     // uint256 index = uint256(keccak256(abi.encode(randomness, i))) % 9;
        //     // emit log_uint(index);
        //     // emit log_uint(gl.MIDDLE_QUALITY_CARD_IDS(index));
        // }
    }

    function testReforgeCard() public {
        testCommitPickedCards();
        GameLobby.RevealedCard[] memory material = new GameLobby.RevealedCard[](2);
        material[0] = GameLobby.RevealedCard(0, 2, 0xec00bdb86eb91e125702f870417c04c6d0c14e931340b0c6702304247ec13cd3);
        material[1] = GameLobby.RevealedCard(1, 2, 0xec00bdb86eb91e125702f870417c04c6d0c14e931340b0c6702304247ec13cd3);
        vm.prank(user1);
        gl.reforgeCard(tableId, material);
        showHands(tableId, user1);
    }

    function showHands(uint256 _tableId, address player) public {
        GameLobby.Card[] memory cards = gl.getHands(_tableId, player);
        for (uint256 i = 0; i < cards.length; i++) {
            emit log_named_uint("index", cards[i].index);
            emit log_named_uint("id", cards[i].id);
            emit log_named_uint("commitment", cards[i].commitment);
        }
    }
}
