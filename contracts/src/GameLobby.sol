// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {
    GeneralRandcastConsumerBase,
    BasicRandcastConsumerBase
} from "Randcast-User-Contract/user/GeneralRandcastConsumerBase.sol";
import {GameFight} from "./library/GameFight.sol";

contract GameLobby is GeneralRandcastConsumerBase {
    uint32 private constant CARD_POOL_SIZE = 20;
    uint256 private constant INNING_COMMITMENT_TIME = 300 seconds;
    uint256 private constant REVEAL_TIME = 20 seconds;

    // tableId => Table
    mapping(uint256 => Table) public tables;
    // requestId => RandomnessRequest
    mapping(bytes32 => RandomnessRequest) public randomnessRequests;
    // tableId => (playerAddress => PlayerState)
    mapping(uint256 => mapping(address => PlayerState)) public playerStates;
    // tableId => (playerAddress => card)
    mapping(uint256 => mapping(address => Card[])) private hands;
    // tableId => (round => cardPool)
    mapping(uint256 => mapping(uint8 => uint256[])) public cardPools;

    enum RandomnessType {
        Initialize,
        Play,
        Reforge
    }

    enum CardType {
        Pick,
        Draw,
        Upgrade,
        Reforge
    }

    struct Table {
        uint256 id;
        address[] playerAddress;
        uint8 currentRound;
        uint8 currentInning;
        bool firstPlayerOffensive;
        uint256 nextCommitmentTime;
        uint256 nextRevealTime;
        address winner;
    }

    struct PlayerState {
        uint32[] sequence;
        uint256 sequenceCommitment;
        bool cardPicked;
        uint8 wonInnings;
    }

    struct RandomnessRequest {
        uint256 tableId;
        RandomnessType randomnessType;
        uint256 qualityToReforge;
        uint256 randomness;
        address player;
        bool finished;
    }

    struct Card {
        uint32 index;
        uint32 id;
        CardType cardType;
        uint256 commitment;
        uint8 creationRound;
        bool used;
    }

    struct RevealedCard {
        uint32 index;
        uint32 id;
        uint256 salt;
    }

    event TableCreated(uint256 indexed tableId, address indexed player);
    event TableJoined(uint256 indexed tableId, address indexed player);
    event RandomnessRequested(
        uint256 indexed tableId, bytes32 indexed requestId, address indexed sender, RandomnessType randomnessType
    );
    event CardPoolGenerated(
        uint256 indexed tableId,
        bytes32 indexed requestId,
        uint8 indexed currentRound,
        uint32[] cardPool,
        uint256 randomness
    );
    event GameStarted(uint256 indexed tableId, bool firstPlayerOffensive, uint256 nextCommitmentTime);
    event InningEnded(
        uint256 indexed tableId,
        uint8 indexed round,
        uint8 indexed inning,
        address winner,
        uint256 randomness,
        uint256 nextCommitmentTime
    );
    event RoundEnded(uint256 indexed tableId, uint8 indexed round);
    event GameEnded(uint256 indexed tableId, address indexed winner);
    event CardPicked(uint256 indexed tableId, address indexed player, uint8 indexed round, uint256[] commitments);
    event CardDrawn(uint256 indexed tableId, address indexed player, uint8 round, uint8 inning, RevealedCard[] cards);
    event CardUpgraded(
        uint256 indexed tableId,
        address indexed player,
        uint8 round,
        uint8 inning,
        uint32 card,
        RevealedCard[] materials
    );
    event CardReforgeRequested(
        uint256 indexed tableId,
        address indexed player,
        uint8 round,
        uint8 inning,
        bytes32 requestId,
        uint256 qualityToReforge,
        RevealedCard[] materials
    );
    event CardReforgeGenerated(
        uint256 indexed tableId,
        address indexed player,
        bytes32 indexed requestId,
        uint256 qualityToReforge,
        uint256 randomness
    );
    event CardReforged(uint256 indexed tableId, address indexed player, uint8 round, uint8 inning, RevealedCard card);
    event SequenceCommitted(
        uint256 indexed tableId, address indexed player, uint8 round, uint8 inning, uint256 commitment
    );
    event SequenceRevealed(
        uint256 indexed tableId, address indexed player, uint8 round, uint8 inning, RevealedCard[] cards
    );

    error TableNotExist();
    error TableFull();
    error NotAPlayer();
    error InvalidRound();
    error InvalidVictory();
    error InvalidSequenceLength();
    error InvalidMaterialLength();
    error InvalidPickedCommitments();
    error InvalidCardCommitment();
    error DifferentCardIdFromHand();
    error CardAlreadyPicked();
    error GameAlreadyEnded();
    error CommitmentTimeExpired();
    error RevealTimeExpired();
    error SequenceAlreadyCommitted();
    error SequenceAlreadyRevealed();
    error InvalidSequenceCommitment();
    error SequenceNotCommitted();
    error EmptyCardNotAllowed();
    error InvalidUpgradeMaterial();
    error NotTheSameUpgradeMaterial();
    error MaxUpgraded();
    error CardNotInCardPool();
    error InvalidReforgeMaterial();
    error InvalidReforgeNonce();
    error NotEnoughReforgeMaterial();
    error ReforgeRequestNotFound();

    constructor(address randcastAdapter) BasicRandcastConsumerBase(randcastAdapter) {
        callbackGasLimit = 200_0000;
    }

    modifier playable(uint256 tableId) {
        if (tables[tableId].id == 0) {
            revert TableNotExist();
        }
        if (tables[tableId].winner != address(0)) {
            revert GameAlreadyEnded();
        }
        if (tables[tableId].playerAddress[0] != msg.sender && tables[tableId].playerAddress[1] != msg.sender) {
            revert NotAPlayer();
        }
        _;
    }

    // ===============================
    // transactions
    // ===============================
    function createTable() external returns (uint256) {
        uint256 tableId = uint256(keccak256(abi.encode(block.timestamp, msg.sender)));
        tables[tableId].id = tableId;
        tables[tableId].playerAddress.push(msg.sender);
        emit TableCreated(tableId, msg.sender);
        return tableId;
    }

    function clearTable(uint256 tableId) external onlyOwner {
        if (tables[tableId].id == 0) {
            revert TableNotExist();
        }
        delete tables[tableId];
    }

    function joinTable(uint256 tableId) external returns (bytes32) {
        if (tables[tableId].id == 0) {
            revert TableNotExist();
        }
        if (tables[tableId].winner != address(0)) {
            revert GameAlreadyEnded();
        }
        if (tables[tableId].playerAddress.length == 2) {
            revert TableFull();
        }
        tables[tableId].playerAddress.push(msg.sender);

        RandomnessRequest memory request =
            RandomnessRequest(tableId, RandomnessType.Initialize, 0, 0, msg.sender, false);
        bytes32 requestId = _getRandomSeed(tableId, request);

        emit TableJoined(tableId, msg.sender);
        return requestId;
    }

    function claimVictory(uint256 tableId) external playable(tableId) {
        address opponent = tables[tableId].playerAddress[0] == msg.sender
            ? tables[tableId].playerAddress[1]
            : tables[tableId].playerAddress[0];
        // check commitment time and reveal time
        if (
            tables[tableId].nextCommitmentTime < block.timestamp
                && playerStates[tableId][msg.sender].sequenceCommitment > 0
                && playerStates[tableId][opponent].sequenceCommitment == 0
        ) {
            tables[tableId].winner = msg.sender;
            emit GameEnded(tableId, msg.sender);
        } else if (
            tables[tableId].nextRevealTime < block.timestamp && playerStates[tableId][msg.sender].sequence.length > 0
                && playerStates[tableId][opponent].sequence.length == 0
        ) {
            tables[tableId].winner = msg.sender;
            emit GameEnded(tableId, msg.sender);
        } else {
            revert InvalidVictory();
        }
    }

    function commitPickedCards(uint256 tableId, uint256[] memory commitments) external playable(tableId) {
        if (tables[tableId].currentRound == 0 && commitments.length != 3) {
            revert InvalidPickedCommitments();
        } else if (tables[tableId].currentRound == 1 && commitments.length != 5) {
            revert InvalidPickedCommitments();
        } else if (tables[tableId].currentRound == 2 && commitments.length != 7) {
            revert InvalidPickedCommitments();
        }
        if (playerStates[tableId][msg.sender].cardPicked) {
            revert CardAlreadyPicked();
        }
        uint256 handsLength = hands[tableId][msg.sender].length;
        for (uint256 i = 0; i < commitments.length; i++) {
            hands[tableId][msg.sender].push(
                Card(uint32(handsLength + i), 0, CardType.Pick, commitments[i], tables[tableId].currentRound, false)
            );
        }
        playerStates[tableId][msg.sender].cardPicked = true;
        emit CardPicked(tableId, msg.sender, tables[tableId].currentRound, commitments);
    }

    // commitment[i] = hash(cardIndex, id, salt)
    // jointCommitment = hash(commitment[0], commitment[1], ... , commitment[n])
    function commitSequence(uint256 tableId, uint256 jointCommitment) external playable(tableId) {
        if (playerStates[tableId][msg.sender].sequenceCommitment > 0) {
            revert SequenceAlreadyCommitted();
        }
        if (tables[tableId].nextCommitmentTime < block.timestamp) {
            revert CommitmentTimeExpired();
        }
        playerStates[tableId][msg.sender].sequenceCommitment = jointCommitment;
        address opponent = tables[tableId].playerAddress[0] == msg.sender
            ? tables[tableId].playerAddress[1]
            : tables[tableId].playerAddress[0];

        if (playerStates[tableId][opponent].sequenceCommitment > 0) {
            tables[tableId].nextRevealTime = block.timestamp + REVEAL_TIME;
        }
        emit SequenceCommitted(
            tableId, msg.sender, tables[tableId].currentRound, tables[tableId].currentInning, jointCommitment
        );
    }

    function revealSequence(uint256 tableId, RevealedCard[] memory sequence) external playable(tableId) {
        if (playerStates[tableId][msg.sender].sequence.length > 0) {
            revert SequenceAlreadyRevealed();
        }
        if (tables[tableId].nextRevealTime < block.timestamp) {
            revert RevealTimeExpired();
        }
        if (tables[tableId].currentRound == 0 && sequence.length != 3) {
            revert InvalidSequenceLength();
        } else if (tables[tableId].currentRound == 1 && sequence.length != 5) {
            revert InvalidSequenceLength();
        } else if (tables[tableId].currentRound == 2 && sequence.length != 7) {
            revert InvalidSequenceLength();
        }
        // check sequence is within hands and commitments(0 as id is ok)
        _checkSequenceCommitment(tableId, sequence);

        uint32[] memory idSequence = new uint32[](sequence.length);
        for (uint256 i = 0; i < sequence.length; i++) {
            if (sequence[i].id != 0) {
                _revealCard(tableId, sequence[i]);
                idSequence[i] = sequence[i].id;
            } else {
                idSequence[i] = 0;
            }
        }
        playerStates[tableId][msg.sender].sequence = idSequence;
        emit SequenceRevealed(
            tableId, msg.sender, tables[tableId].currentRound, tables[tableId].currentInning, sequence
        );

        address opponent = tables[tableId].playerAddress[0] == msg.sender
            ? tables[tableId].playerAddress[1]
            : tables[tableId].playerAddress[0];

        if (playerStates[tableId][opponent].sequence.length > 0) {
            RandomnessRequest memory request = RandomnessRequest(tableId, RandomnessType.Play, 0, 0, msg.sender, false);
            _getRandomSeed(tableId, request);
        }
    }

    function upgradeCard(uint256 tableId, RevealedCard[] memory material) external playable(tableId) {
        if (material.length != 2) {
            revert InvalidMaterialLength();
        }

        uint32 handsLength = uint32(hands[tableId][msg.sender].length);
        for (uint256 i = 0; i < material.length; i++) {
            _revealCard(tableId, material[i]);
            uint32 index = material[i].index;
            if (index >= handsLength || hands[tableId][msg.sender][index].used) {
                revert InvalidUpgradeMaterial();
            }
            if (hands[tableId][msg.sender][index].id / (GameFight.MAX_CARD_ID + 1) >= 2) {
                revert MaxUpgraded();
            }
            hands[tableId][msg.sender][index].used = true;
        }

        uint32 aId = hands[tableId][msg.sender][material[0].index].id;
        uint32 bId = hands[tableId][msg.sender][material[1].index].id;

        if (aId != bId) {
            revert NotTheSameUpgradeMaterial();
        }

        hands[tableId][msg.sender].push(
            Card(handsLength, aId + GameFight.MAX_CARD_ID + 1, CardType.Upgrade, 0, tables[tableId].currentRound, false)
        );

        emit CardUpgraded(
            tableId, msg.sender, tables[tableId].currentRound, tables[tableId].currentInning, handsLength, material
        );
    }

    function reforgeCard(uint256 tableId, RevealedCard[] memory material) external playable(tableId) {
        uint32 handsLength = uint32(hands[tableId][msg.sender].length);
        uint256 qualityToReforge;
        for (uint256 i = 0; i < material.length; i++) {
            _revealCard(tableId, material[i]);
            uint32 index = material[i].index;
            if (index >= handsLength || hands[tableId][msg.sender][index].used) {
                revert InvalidReforgeMaterial();
            }
            hands[tableId][msg.sender][index].used = true;
            qualityToReforge += uint256(GameFight.getCardQuality(hands[tableId][msg.sender][index].id)) + 1;
        }
        qualityToReforge >>= 1;
        if (qualityToReforge == 0) {
            revert NotEnoughReforgeMaterial();
        }
        qualityToReforge = qualityToReforge > 3 ? 2 : (qualityToReforge - 1);
        RandomnessRequest memory request =
            RandomnessRequest(tableId, RandomnessType.Reforge, qualityToReforge, 0, msg.sender, false);
        bytes32 requestId = _getRandomSeed(tableId, request);
        emit CardReforgeRequested(
            tableId,
            msg.sender,
            tables[tableId].currentRound,
            tables[tableId].currentInning,
            requestId,
            qualityToReforge,
            material
        );
    }

    function summitReforge(uint256 tableId, bytes32 requestId, uint8 nonce) external playable(tableId) {
        if (nonce > 2) {
            revert InvalidReforgeNonce();
        }
        RandomnessRequest memory request = randomnessRequests[requestId];
        //TODO finished is not sufficient because it is possible that the player uses opponent's requestId
        if (request.player != msg.sender || request.finished) {
            revert ReforgeRequestNotFound();
        }
        uint32 handsLength = uint32(hands[tableId][msg.sender].length);
        uint32[] memory fromCards = GameFight.getCardIdsByQuality(request.qualityToReforge);
        uint32 cardId = fromCards[uint256(keccak256(abi.encode(request.randomness, nonce))) % fromCards.length];

        hands[tableId][msg.sender].push(
            Card(handsLength, cardId, CardType.Reforge, 0, tables[tableId].currentRound, false)
        );
        request.finished = true;
        RevealedCard memory card = RevealedCard(handsLength, cardId, 0);
        emit CardReforged(tableId, msg.sender, tables[tableId].currentRound, tables[tableId].currentInning, card);
    }

    // ===============================
    // internal functions
    // ===============================

    function _revealCard(uint256 tableId, RevealedCard memory card) internal {
        // pass if card id has already been revealed
        if (hands[tableId][msg.sender][card.index].id != 0) {
            if (hands[tableId][msg.sender][card.index].id != card.id) {
                revert DifferentCardIdFromHand();
            }
            return;
        }
        if (hands[tableId][msg.sender][card.index].cardType == CardType.Pick) {
            if (card.id == 0) {
                revert EmptyCardNotAllowed();
            }
            uint256 commitment = hands[tableId][msg.sender][card.index].commitment;
            uint256 calculatedCommitment = uint256(keccak256(abi.encode(card.index, card.id, card.salt)));
            if (calculatedCommitment != commitment) {
                revert InvalidCardCommitment();
            }
            _checkInCardPool(tableId, card.id, hands[tableId][msg.sender][card.index].creationRound);
            hands[tableId][msg.sender][card.index].id = card.id;
        }
    }

    function _checkSequenceCommitment(uint256 tableId, RevealedCard[] memory sequence) internal view {
        uint256 commitment = playerStates[tableId][msg.sender].sequenceCommitment;
        if (commitment == 0) {
            revert SequenceNotCommitted();
        }
        uint256 calculatedCommitment;
        uint256 jointCommitment;
        for (uint256 i = 0; i < sequence.length; i++) {
            calculatedCommitment = uint256(keccak256(abi.encode(sequence[i].index, sequence[i].id, sequence[i].salt)));
            jointCommitment = uint256(keccak256(abi.encode(jointCommitment, calculatedCommitment)));
        }
        if (jointCommitment != commitment) {
            revert InvalidSequenceCommitment();
        }
    }

    function _checkInCardPool(uint256 tableId, uint32 cardId, uint8 round) internal view {
        uint256[] memory cardPool = cardPools[tableId][round];
        bool found;
        for (uint256 i = 0; i < cardPool.length; i++) {
            if (cardPool[i] == cardId) {
                found = true;
                break;
            }
        }
        if (!found) {
            revert CardNotInCardPool();
        }
    }

    function _drawNextRoundCards(uint256 tableId, uint256 randomness, uint256 count) internal {
        uint8 currentRound = tables[tableId].currentRound;
        uint8 currentInning = tables[tableId].currentInning;
        for (uint256 j = 0; j < tables[tableId].playerAddress.length; j++) {
            RevealedCard[] memory drawnCards = new RevealedCard[](count);
            address player = tables[tableId].playerAddress[j];
            uint256 handsLength = hands[tableId][player].length;
            for (uint256 i = 0; i < count; i++) {
                uint32[] memory fromCards = GameFight.getCardIdsByQuality(tables[tableId].currentRound);
                uint32 cardId = fromCards[uint256(keccak256(abi.encode(randomness, i))) % fromCards.length];

                hands[tableId][player].push(
                    Card(uint32(handsLength + i), cardId, CardType.Draw, 0, currentRound, false)
                );
                drawnCards[i] = RevealedCard(uint32(handsLength + i), cardId, 0);
            }
            emit CardDrawn(tableId, player, currentRound, currentInning, drawnCards);
        }
    }

    function _fight(uint256 tableId, uint256 randomness) internal returns (address winner) {
        uint32 maxHealth;
        uint32 damage;
        if (tables[tableId].currentRound == 0) {
            maxHealth = 3000;
            damage = 150;
        } else if (tables[tableId].currentRound == 1) {
            maxHealth = 6000;
            damage = 300;
        } else if (tables[tableId].currentRound == 2) {
            maxHealth = 12000;
            damage = 600;
        } else {
            revert InvalidRound();
        }
        bool firstPlayerWin = GameFight.fight(
            _buildPlayerState(maxHealth, damage),
            _buildPlayerState(maxHealth, damage),
            playerStates[tableId][tables[tableId].playerAddress[0]].sequence,
            playerStates[tableId][tables[tableId].playerAddress[1]].sequence,
            tables[tableId].firstPlayerOffensive,
            randomness
        );
        winner = firstPlayerWin ? tables[tableId].playerAddress[0] : tables[tableId].playerAddress[1];
        playerStates[tableId][winner].wonInnings++;
        tables[tableId].firstPlayerOffensive = !firstPlayerWin;
    }

    function _buildPlayerState(uint32 maxHealth, uint32 damage) internal pure returns (GameFight.PlayerState memory) {
        return GameFight.PlayerState(
            0,
            maxHealth,
            maxHealth,
            damage,
            100,
            10,
            10,
            200,
            100,
            100,
            GameFight.Actionable.Normal,
            0,
            new GameFight.Buff[](128)
        );
    }

    function _play(uint256 tableId, bytes32 requestId, uint256 randomness) internal {
        address winner = _fight(tableId, randomness);
        uint8 currentRound = tables[tableId].currentRound;
        uint8 currentInning = tables[tableId].currentInning;

        if (tables[tableId].currentInning == 2 && tables[tableId].currentRound == 2) {
            tables[tableId].winner = playerStates[tableId][tables[tableId].playerAddress[0]].wonInnings
                > playerStates[tableId][tables[tableId].playerAddress[1]].wonInnings
                ? tables[tableId].playerAddress[0]
                : tables[tableId].playerAddress[1];
            emit GameEnded(tableId, tables[tableId].winner);
        } else if (tables[tableId].currentInning == 1 && tables[tableId].currentRound < 2) {
            emit RoundEnded(tableId, tables[tableId].currentRound);
            tables[tableId].currentInning = 0;
            tables[tableId].currentRound++;

            uint32[] memory cardPool = _generateCardPool(randomness, tables[tableId].currentRound);
            cardPools[tableId][tables[tableId].currentRound] = cardPool;
            emit CardPoolGenerated(tableId, requestId, tables[tableId].currentRound, cardPool, randomness);

            _resetInningState(tableId);
            tables[tableId].nextCommitmentTime = block.timestamp + INNING_COMMITMENT_TIME;
        } else {
            tables[tableId].currentInning++;
            _drawNextRoundCards(tableId, randomness, 2);
            _resetInningState(tableId);
            tables[tableId].nextCommitmentTime = block.timestamp + INNING_COMMITMENT_TIME;
        }
        emit InningEnded(tableId, currentRound, currentInning, winner, randomness, tables[tableId].nextCommitmentTime);
    }

    function _resetInningState(uint256 tableId) internal {
        for (uint256 i = 0; i < tables[tableId].playerAddress.length; i++) {
            address player = tables[tableId].playerAddress[i];
            delete playerStates[tableId][player].sequence;
            playerStates[tableId][player].sequenceCommitment = 0;
            if (tables[tableId].currentInning == 0) {
                playerStates[tableId][player].cardPicked = false;
            }
        }
        tables[tableId].nextCommitmentTime = 0;
        tables[tableId].nextRevealTime = 0;
    }

    /**
     * Requests randomness
     */
    function _getRandomSeed(uint256 tableId, RandomnessRequest memory request)
        internal
        virtual
        returns (bytes32 requestId)
    {
        bytes memory params;
        requestId = _requestRandomness(RequestType.Randomness, params);
        randomnessRequests[requestId] = request;
        emit RandomnessRequested(tableId, requestId, msg.sender, request.randomnessType);
    }

    /**
     * Callback function used by Randcast Adapter
     */
    function _fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        RandomnessRequest storage request = randomnessRequests[requestId];
        request.randomness = randomness;
        if (request.randomnessType == RandomnessType.Initialize) {
            uint8 currentRound = tables[request.tableId].currentRound;
            uint32[] memory cardPool = _generateCardPool(randomness, currentRound);
            cardPools[request.tableId][0] = cardPool;
            bool firstPlayerOffensive = randomness % 2 == 0;
            tables[request.tableId].firstPlayerOffensive = firstPlayerOffensive;
            uint256 nextCommitmentTime = block.timestamp + INNING_COMMITMENT_TIME;
            tables[request.tableId].nextCommitmentTime = nextCommitmentTime;
            request.finished = true;
            emit GameStarted(request.tableId, firstPlayerOffensive, nextCommitmentTime);
            emit CardPoolGenerated(request.tableId, requestId, currentRound, cardPool, randomness);
        } else if (request.randomnessType == RandomnessType.Play) {
            _play(request.tableId, requestId, randomness);
            request.finished = true;
        } else if (request.randomnessType == RandomnessType.Reforge) {
            emit CardReforgeGenerated(request.tableId, request.player, requestId, request.qualityToReforge, randomness);
        }
    }

    function _generateCardPool(uint256 randomness, uint8 round) internal pure returns (uint32[] memory) {
        return _repeatedDraw(randomness, GameFight.getCardIdsByUpperQuality(round), CARD_POOL_SIZE);
    }

    function _repeatedDraw(uint256 seed, uint32[] memory fromCards, uint256 count)
        internal
        pure
        returns (uint32[] memory)
    {
        uint32[] memory chosenIds = new uint32[](count);
        for (uint256 i = 0; i < count; i++) {
            chosenIds[i] = fromCards[uint256(keccak256(abi.encode(seed, i))) % fromCards.length];
        }
        return chosenIds;
    }

    // ===============================
    // views
    // ===============================
    function getPlayers(uint256 tableId) external view returns (address[] memory) {
        return tables[tableId].playerAddress;
    }

    function getHands(uint256 tableId, address player) external view returns (Card[] memory) {
        return hands[tableId][player];
    }
}
