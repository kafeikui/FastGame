// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {
    GeneralRandcastConsumerBase,
    BasicRandcastConsumerBase
} from "Randcast-User-Contract/user/GeneralRandcastConsumerBase.sol";
import {shuffle} from "Randcast-User-Contract/user/RandcastSDK.sol";

contract CardGame is GeneralRandcastConsumerBase {
    event RandomnessRequested(uint256 indexed tableId, bytes32 indexed requestId);
    event CardPoolGenerated(
        uint256 indexed tableId, bytes32 indexed requestId, uint256[] cardPool, uint8 ruleType, uint256 randomness
    );
    event RoundEnded(
        uint256 indexed tableId, uint256 indexed set, uint256 indexed round, address winner, uint256 points
    );
    event SetEnded(uint256 indexed tableId, uint256 indexed set, address winner);
    event CheatDetected(uint256 indexed tableId, address indexed player, uint256 set, uint256 round);
    event TableCreated(uint256 indexed tableId, address indexed player);
    event TableJoined(uint256 indexed tableId, address indexed player);
    event GameEnded(uint256 indexed tableId, address indexed winner);
    event RuleTypeDetermined(uint256 indexed tableId, address indexed player, uint8 ruleType);
    event HandsCommitted(uint256 indexed tableId, address indexed player, uint256[] hands);
    event CardCommitted(uint256 indexed tableId, address indexed player, uint256 indexed round, uint256 commitment);
    event CardPlayed(
        uint256 indexed tableId, address indexed player, uint256 set, uint256 round, uint256 index, uint256 card
    );

    struct Table {
        uint256 id;
        // 2 players
        Player[] players;
        // 20 cards
        uint256[] cardPool;
        uint8 ruleType;
        uint8 randomnessState;
        uint8 currentSet;
        uint8 currentRound;
        address lastSetWinner;
        address winner;
    }

    struct Player {
        address playerAddress;
        // 5 hands
        uint256[] hands;
        // 5 rounds
        uint256[] playedCommitments;
        // 5 rounds
        uint256[] playedCards;
        // 5 rounds
        uint256[] points;
        uint8 wonSets;
    }

    mapping(bytes32 => uint256) public tableIds;
    mapping(uint256 => Table) public tables;

    // solhint-disable-next-line no-empty-blocks
    constructor(address adapter) BasicRandcastConsumerBase(adapter) {}

    modifier notEnded(uint256 tableId) {
        require(tables[tableId].winner == address(0), "Game ended");
        _;
    }

    // ===============================
    // transactions
    // ===============================
    function createTable() external {
        uint256 tableId = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender)));
        tables[tableId].id = tableId;
        tables[tableId].cardPool = new uint256[](0);

        tables[tableId].players.push(
            Player(msg.sender, new uint256[](0), new uint256[](5), new uint256[](5), new uint256[](5), 0)
        );
        for (uint256 i = 0; i < 5; i++) {
            tables[tableId].players[0].playedCards[i] = 52;
        }
        emit TableCreated(tableId, msg.sender);
    }

    function joinTable(uint256 tableId) external notEnded(tableId) {
        require(tables[tableId].id != 0, "Table does not exist");
        require(tables[tableId].players.length < 2, "Table is full");
        tables[tableId].players.push(
            Player(msg.sender, new uint256[](0), new uint256[](5), new uint256[](5), new uint256[](5), 0)
        );
        for (uint256 i = 0; i < 5; i++) {
            tables[tableId].players[1].playedCards[i] = 52;
        }
        emit TableJoined(tableId, msg.sender);
    }

    function clearTable(uint256 tableId) external onlyOwner {
        require(tables[tableId].id != 0, "Table does not exist");
        delete tables[tableId];
    }

    function determineRuleType(uint256 tableId, uint8 ruleType) external notEnded(tableId) {
        require(tables[tableId].id != 0, "Table does not exist");
        require(
            tables[tableId].players[0].playerAddress == msg.sender
                || tables[tableId].players[1].playerAddress == msg.sender,
            "Not a player"
        );
        require(tables[tableId].ruleType == 0, "Rule type already determined");
        require(ruleType == 1 || ruleType == 2, "Invalid rule type");
        require(tables[tableId].lastSetWinner != msg.sender, "Last set winner cannot determine rule type");
        tables[tableId].ruleType = ruleType;
        emit RuleTypeDetermined(tableId, msg.sender, ruleType);
    }

    // Since there are two hidden cards, we will check if hands are in card pool when the player plays it
    function commitHands(uint256 tableId, uint256[] memory hands) external notEnded(tableId) {
        require(tables[tableId].cardPool.length == 20, "Card pool is not generated");
        require(hands.length == 5, "Invalid hands");
        if (tables[tableId].players[0].playerAddress == msg.sender) {
            require(tables[tableId].players[0].hands.length == 0, "Hands already committed");
            tables[tableId].players[0].hands = hands;
        } else if (tables[tableId].players[1].playerAddress == msg.sender) {
            require(tables[tableId].players[1].hands.length == 0, "Hands already committed");
            tables[tableId].players[1].hands = hands;
        } else {
            revert("Not a player");
        }
        emit HandsCommitted(tableId, msg.sender, hands);
    }

    function commit(uint256 tableId, uint256 commitment) external notEnded(tableId) {
        require(tables[tableId].id != 0, "Table does not exist");
        require(tables[tableId].cardPool.length == 20, "Card pool is not generated");
        require(tables[tableId].ruleType == 1 || tables[tableId].ruleType == 2, "Rule type not determined");
        require(
            tables[tableId].players[0].hands.length != 0 && tables[tableId].players[1].hands.length != 0,
            "Hands not committed"
        );
        if (tables[tableId].players[0].playerAddress == msg.sender) {
            require(
                tables[tableId].players[0].playedCommitments[tables[tableId].currentRound] == 0,
                "Commitment already played"
            );
            tables[tableId].players[0].playedCommitments[tables[tableId].currentRound] = commitment;
        } else if (tables[tableId].players[1].playerAddress == msg.sender) {
            require(
                tables[tableId].players[1].playedCommitments[tables[tableId].currentRound] == 0,
                "Commitment already played"
            );
            tables[tableId].players[1].playedCommitments[tables[tableId].currentRound] = commitment;
        } else {
            revert("Not a player");
        }
        emit CardCommitted(tableId, msg.sender, tables[tableId].currentRound, commitment);
    }

    function play(uint256 tableId, uint256 index, uint256 card, uint256 salt, uint256 hiddenSalt)
        external
        notEnded(tableId)
    {
        require(tables[tableId].id != 0, "Table does not exist");
        require(tables[tableId].cardPool.length == 20, "Card pool is not generated");
        require(tables[tableId].ruleType == 1 || tables[tableId].ruleType == 2, "Rule type not determined");
        require(index < 5, "Invalid index");

        if (tables[tableId].players[0].playerAddress == msg.sender) {
            if (!_checkCard(tableId, 0, index, card, salt, hiddenSalt)) {
                return;
            }
            tables[tableId].players[0].playedCards[tables[tableId].currentRound] = card;
        } else if (tables[tableId].players[1].playerAddress == msg.sender) {
            if (!_checkCard(tableId, 1, index, card, salt, hiddenSalt)) {
                return;
            }
            tables[tableId].players[1].playedCards[tables[tableId].currentRound] = card;
        } else {
            revert("Not a player");
        }
        emit CardPlayed(tableId, msg.sender, tables[tableId].currentSet, tables[tableId].currentRound, index, card);

        // calculate points and move round if all players have played
        if (
            tables[tableId].players[0].playedCards[tables[tableId].currentRound] != 52
                && tables[tableId].players[1].playedCards[tables[tableId].currentRound] != 52
        ) _proceedWithGame(tableId);
    }

    /**
     * Requests randomness
     */
    function getRandomSeed(uint256 tableId) external {
        if (tables[tableId].randomnessState == 1) {
            return;
        }

        bytes memory params;
        bytes32 requestId = _requestRandomness(RequestType.Randomness, params);
        tableIds[requestId] = tableId;
        tables[tableId].randomnessState = 1;
        emit RandomnessRequested(tableId, requestId);
    }

    // ===============================
    // internal functions
    // ===============================
    function _resetTable(uint256 tableId) internal {
        tables[tableId].cardPool = new uint256[](0);
        tables[tableId].ruleType = 0;
        tables[tableId].randomnessState = 0;
        tables[tableId].players[0].hands = new uint256[](0);
        tables[tableId].players[0].playedCommitments = new uint256[](5);
        tables[tableId].players[0].playedCards = new uint256[](5);
        for (uint256 i = 0; i < 5; i++) {
            tables[tableId].players[0].playedCards[i] = 52;
        }
        tables[tableId].players[0].points = new uint256[](5);
        tables[tableId].players[1].hands = new uint256[](0);
        tables[tableId].players[1].playedCommitments = new uint256[](5);
        tables[tableId].players[1].playedCards = new uint256[](5);
        for (uint256 i = 0; i < 5; i++) {
            tables[tableId].players[1].playedCards[i] = 52;
        }
        tables[tableId].players[1].points = new uint256[](5);
    }

    function _checkCardInCardPool(uint256 tableId, uint256 card) internal view returns (bool) {
        require(tables[tableId].id != 0, "Table does not exist");
        if (card > 51) {
            return false;
        }
        for (uint256 i = 0; i < tables[tableId].cardPool.length; i++) {
            if (tables[tableId].cardPool[i] == card) {
                return true;
            }
        }
        return false;
    }

    function _decodeSuitAndRank(uint256 card) internal pure returns (uint256, uint256) {
        return (card / 13, card % 13);
    }

    function _proceedWithGame(uint256 tableId) internal {
        uint8 currentSet = tables[tableId].currentSet;
        uint8 currentRound = tables[tableId].currentRound;

        (address roundWinner, uint256 wonPoints) = _calculatePoints(
            tableId,
            currentRound,
            tables[tableId].players[0].playedCards[currentRound],
            tables[tableId].players[1].playedCards[currentRound]
        );

        emit RoundEnded(tableId, currentSet, currentRound + 1, roundWinner, wonPoints);

        if (currentRound == 4) {
            _determineSetWinner(tableId);
            _resetTable(tableId);
            emit SetEnded(tableId, currentSet + 1, tables[tableId].lastSetWinner);

            if (_checkGameWinner(tableId) != address(0)) {
                // end game
                emit GameEnded(tableId, tables[tableId].winner);
                return;
            }

            // move set if all rounds have been played
            tables[tableId].currentSet += 1;
            tables[tableId].currentRound = 0;
        } else {
            tables[tableId].currentRound += 1;
        }
    }

    function _determineSetWinner(uint256 tableId) internal {
        require(tables[tableId].id != 0, "Table does not exist");
        uint256 player0Points = 0;
        uint256 player1Points = 0;
        for (uint256 i = 0; i < 5; i++) {
            player0Points += tables[tableId].players[0].points[i];
            player1Points += tables[tableId].players[1].points[i];
        }
        if (player0Points > player1Points) {
            tables[tableId].players[0].wonSets += 1;
            tables[tableId].lastSetWinner = tables[tableId].players[0].playerAddress;
        } else if (player0Points < player1Points) {
            tables[tableId].players[1].wonSets += 1;
            tables[tableId].lastSetWinner = tables[tableId].players[1].playerAddress;
        }
    }

    function _checkGameWinner(uint256 tableId) internal returns (address) {
        require(tables[tableId].id != 0, "Table does not exist");
        if (tables[tableId].players[0].wonSets == 2) {
            tables[tableId].winner = tables[tableId].players[0].playerAddress;
        } else if (tables[tableId].players[1].wonSets == 2) {
            tables[tableId].winner = tables[tableId].players[1].playerAddress;
        }
        return tables[tableId].winner;
    }

    //TODO emit more specific cheat reason
    function _checkCard(
        uint256 tableId,
        uint256 playerIndex,
        uint256 index,
        uint256 card,
        uint256 salt,
        uint256 hiddenSalt
    ) internal returns (bool) {
        uint8 currentSet = tables[tableId].currentSet;
        uint8 currentRound = tables[tableId].currentRound;

        require(tables[tableId].players[playerIndex].hands.length != 0, "Hands not committed");
        require(tables[tableId].players[playerIndex].playedCards[currentRound] == 52, "Card already played");
        require(tables[tableId].players[playerIndex].playedCommitments[currentRound] != 0, "Commitment not played");
        // check card with former commitment
        require(
            tables[tableId].players[playerIndex].playedCommitments[currentRound]
                == uint256(keccak256(abi.encodePacked(card, salt))),
            "Card does not match commitment"
        );

        if (!_checkCardInCardPool(tableId, card)) {
            emit CheatDetected(tableId, tables[tableId].players[playerIndex].playerAddress, currentSet, currentRound);
            tables[tableId].winner = tables[tableId].players[1 - playerIndex].playerAddress;
            return false;
        }

        if (index == 0 || index == 1) {
            // check if the card matches hidden card from former commited hands
            if (
                tables[tableId].players[playerIndex].hands[index]
                    != uint256(keccak256(abi.encodePacked(card, hiddenSalt)))
            ) {
                emit CheatDetected(
                    tableId, tables[tableId].players[playerIndex].playerAddress, currentSet, currentRound
                );
                tables[tableId].winner = tables[tableId].players[1 - playerIndex].playerAddress;
                return false;
            }
        } else {
            // check if card is in hand with index
            if (tables[tableId].players[playerIndex].hands[index] != card) {
                emit CheatDetected(
                    tableId, tables[tableId].players[playerIndex].playerAddress, currentSet, currentRound
                );
                tables[tableId].winner = tables[tableId].players[1 - playerIndex].playerAddress;
                return false;
            }
        }

        return true;
    }

    function _calculatePoints(uint256 tableId, uint8 currentRound, uint256 player0Card, uint256 player1Card)
        internal
        returns (address roundWinner, uint256 wonPoints)
    {
        (uint256 player0Suit, uint256 player0Rank) = _decodeSuitAndRank(player0Card);

        (uint256 player1Suit, uint256 player1Rank) = _decodeSuitAndRank(player1Card);

        if (tables[tableId].ruleType == 1) {
            if (player0Suit == player1Suit) {
                if (player0Rank > player1Rank) {
                    wonPoints = player0Rank - player1Rank;
                    if (wonPoints > 0) {
                        tables[tableId].players[0].points[currentRound] = wonPoints;
                        roundWinner = tables[tableId].players[0].playerAddress;
                    }
                } else {
                    wonPoints = player1Rank - player0Rank;
                    if (wonPoints > 0) {
                        tables[tableId].players[1].points[currentRound] = wonPoints;
                        roundWinner = tables[tableId].players[1].playerAddress;
                    }
                }
            } else {
                if (player0Rank > player1Rank) {
                    wonPoints = player0Rank - player1Rank;
                    if (wonPoints > 0) {
                        tables[tableId].players[1].points[currentRound] = wonPoints;
                        roundWinner = tables[tableId].players[1].playerAddress;
                    }
                } else {
                    wonPoints = player1Rank - player0Rank;
                    if (wonPoints > 0) {
                        tables[tableId].players[0].points[currentRound] = wonPoints;
                        roundWinner = tables[tableId].players[0].playerAddress;
                    }
                }
            }
        } else if (tables[tableId].ruleType == 2) {
            if (player0Suit == player1Suit) {
                if (player0Rank > player1Rank) {
                    wonPoints = player0Rank - player1Rank;
                    if (wonPoints > 0) {
                        tables[tableId].players[1].points[currentRound] = wonPoints;
                        roundWinner = tables[tableId].players[1].playerAddress;
                    }
                } else {
                    wonPoints = player1Rank - player0Rank;
                    if (wonPoints > 0) {
                        tables[tableId].players[0].points[currentRound] = wonPoints;
                        roundWinner = tables[tableId].players[0].playerAddress;
                    }
                }
            } else {
                if (player0Rank > player1Rank) {
                    wonPoints = player0Rank - player1Rank;
                    if (wonPoints > 0) {
                        tables[tableId].players[0].points[currentRound] = wonPoints;
                        roundWinner = tables[tableId].players[0].playerAddress;
                    }
                } else {
                    wonPoints = player1Rank - player0Rank;
                    if (wonPoints > 0) {
                        tables[tableId].players[1].points[currentRound] = wonPoints;
                        roundWinner = tables[tableId].players[1].playerAddress;
                    }
                }
            }
        } else {
            revert("Invalid rule type");
        }
    }

    /**
     * Callback function used by Randcast Adapter
     */
    function _fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 tableId = tableIds[requestId];
        uint256[] memory shuffled = shuffle(52, randomness);
        uint256[] memory cardPool = new uint256[](20);
        for (uint256 i = 0; i < 20; i++) {
            cardPool[i] = shuffled[i];
        }
        tables[tableId].cardPool = cardPool;
        if (tables[tableId].lastSetWinner == address(0)) {
            uint8 ruleType = uint8(randomness % 2 + 1);
            tables[tableId].ruleType = ruleType;
            emit RuleTypeDetermined(tableId, address(0), ruleType);
        }
        emit CardPoolGenerated(tableId, requestId, cardPool, tables[tableId].ruleType, randomness);
    }

    // ===============================
    // views
    // ===============================
    function getPlayers(uint256 tableId) external view returns (address[] memory) {
        require(tables[tableId].id != 0, "Table does not exist");
        address[] memory players = new address[](2);
        if (tables[tableId].players.length > 0) {
            players[0] = tables[tableId].players[0].playerAddress;
            if (tables[tableId].players.length > 1) {
                players[1] = tables[tableId].players[1].playerAddress;
            }
        }
        return players;
    }

    function getCardPool(uint256 tableId) external view returns (uint256[] memory) {
        require(tables[tableId].id != 0, "Table does not exist");
        return tables[tableId].cardPool;
    }

    function getHands(uint256 tableId, address player) external view returns (uint256[] memory) {
        require(tables[tableId].id != 0, "Table does not exist");
        if (tables[tableId].players[0].playerAddress == player) {
            return tables[tableId].players[0].hands;
        } else if (tables[tableId].players[1].playerAddress == player) {
            return tables[tableId].players[1].hands;
        } else {
            revert("Not a player");
        }
    }

    function getCurrentState(uint256 tableId) external view returns (uint256, uint256) {
        return (tables[tableId].currentSet + 1, tables[tableId].currentRound + 1);
    }
}
