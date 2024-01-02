<script>
  import Web3 from "web3";
  import { onMount, afterUpdate } from "svelte";
  import RoundState from "./RoundState.svelte";
  import Hand from "./Hand.svelte";
  import Sequence from "./Sequence.svelte";
  import ControlPanel from "./ControlPanel.svelte";
  import Arena from "./Arena.svelte";
  import CardPool from "./CardPool.svelte";
  import MessageBoard from "./MessageBoard.svelte";
  import HelpBoard from "./HelpBoard.svelte";
  import CardPick from "./CardPick.svelte";
  import TablePicker from "./TablePicker.svelte";
  import AudioVolumn from "./AudioVolumn.svelte";
  import {
    listenTableCreated,
    listenTableJoined,
    listenCardPoolGenerated,
    listenCardDrawn,
    listenSequenceCommitted,
    listenSequenceRevealed,
    listenCardReforgeGenerated,
    listenGameStarted,
    listenInningEnded,
    listenRoundEnded,
    listenGameEnded,
    createTable as web3CreateTable,
    joinTable as web3JoinTable,
    commitPickedCards as web3CommitPickedCards,
    commitSequence as web3CommitSequence,
    revealSequence as web3RevealSequence,
    upgradeCard as web3UpgradeCard,
    reforgeCard as web3ReforgeCard,
    summitReforge as web3SummitReforge,
    getPlayers as web3GetPlayers,
    claimVictory as web3ClaimVictory,
    getSalt,
    sendETH,
  } from "../../utils/web3";
  import {
    LOW_QUALITY_CARD_IDS,
    MIDDLE_QUALITY_CARD_IDS,
    HIGH_QUALITY_CARD_IDS,
    QualityType,
    repeatedDraw,
    getCard,
  } from "../../utils/card";
  import { MAX_CARD_ID } from "../../constants/card_constant";
  import {
    PlayerState,
    IdentityType,
    fight,
    clearCallback as clearFightCallback,
  } from "../../utils/game_fight";
  import {
    broadcastSe,
    stopSe,
    SE,
    isPlaying,
    muteAll,
    unmuteAll,
  } from "../../utils/se";

  const CardType = {
    Pick: 0,
    Draw: 1,
    Upgrade: 2,
    Reforge: 3,
  };

  class Card {
    constructor(index, id, cardType, salt, used) {
      this.index = index;
      this.id = id;
      this.cardType = cardType;
      this.salt = salt;
      this.used = used;
    }
  }

  class RevealedCard {
    constructor(index, id, salt) {
      this.index = index;
      this.id = id;
      this.salt = salt;
    }
  }

  let web3;
  let BN;
  let websocketProvider = process.env.WEBSOCKET_PROVIDER;
  let contractAddress = process.env.CONTRACT_ADDRESS;
  let devAccounts = process.env.DEV_ACCOUNTS;
  let demoETHValue = process.env.DEMO_ETH_VALUE;

  let oHidden;
  let oHand;
  let oDesc;
  let oArena;
  let oWarRoom;
  let oAudio;
  let oMmessageBoard;
  let oHelpBoard;
  let oSettleButton;
  let oOpponentSequenceBox;
  let helpText;
  let helpBoardHeight;
  let musicTimer;

  let canPlay = true;
  let canReforge = true;
  let canRestart = false;
  let canSettle = false;
  let canHelpBack = false;
  let canHandPick = false;
  let canHandPan = true;
  let canSequencePan = true;
  let duringReforge = false;
  let onTablePick;
  let onCardPoolPick = false;
  let onCardPick = false;
  let onWaitingPage = false;
  let isConceal = false;
  let isMuted = false;
  let concealResumeCallback;
  let warRoomResumeCallback;
  let selfCommited;
  let opponentCommited;
  let hasStartedFight = false;
  let hasInitialCardPoolPick = false;

  let subscriptions = [];
  let availableSequence = [3, 5, 7];
  let cardPool = [];
  let selfCards = [];
  let sequence = [
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
  ];
  let selfIdSequence = [];
  let opponentIdSequence = [0, 0, 0];
  let opponentSequence = [getCard(0), getCard(0), getCard(0)];
  let hands = [];
  let cardsToPick = [];
  let currentReforgeRequestId;

  let tableId = 0;
  let isTableCreator;
  let selfName;
  let opponentName = "A worthy opponent";
  let currentRound = 0;
  let currentInning = 0;
  let selfScore = 0;
  let opponentScore = 0;
  let isSelfOffensive;
  let nextCommitmentTime;
  let timeToCountDown = 999;
  let timePhase = "Preparing";

  let self = PlayerState.placeholder();
  let enemy = PlayerState.placeholder();
  let fightRandomness;
  let outcome = "waiting...";
  let round = 0;

  $: sequenceUpperBound = availableSequence[currentRound];
  $: concealButtonEnabled =
    isConceal || onCardPick || onCardPoolPick || onWaitingPage;
  $: time = `${timePhase}... ${timeToCountDown}`;

  onMount(async () => {
    pauseInteraction();
    web3 = new Web3(new Web3.providers.WebsocketProvider(websocketProvider));
    BN = web3.utils.BN;
    // TODO we create a new keypair for demo use
    web3.eth.accounts.wallet.create(1);
    selfName = web3.eth.accounts.wallet[0].address;
    for (var i = 0; i < 20; i++) {
      try {
        let index = Math.floor(Math.random() * devAccounts.length);
        console.log(devAccounts[index]);
        let account = web3.eth.accounts.wallet.add(devAccounts[index]);
        await sendETH(web3, account.address, selfName, demoETHValue);
        break;
      } catch (error) {
        console.error(error);
      }
    }
    await init();
    startTablePick();

    // oHidden.style.display = "none";

    // test arena fight
    // setTimeout(() => {
    //   self = PlayerState.buildPlayerState(IdentityType.Self, 3000, 150);
    //   enemy = PlayerState.buildPlayerState(IdentityType.Enemy, 3000, 150);
    //   selfSequence = [35, 2, 14, 29, 45, 31];
    //   opponentSequence = [35, 14, 2, 29, 45, 31];
    //   fightRandomness = web3.utils.toBN(web3.utils.soliditySha3(42));
    //   oWarRoom.style.display = "none";
    //   oHidden.style.display = "none";
    //   oArena.style.display = "block";
    // }, 200);
  });

  afterUpdate(() => {
    if (canSettle) {
      oSettleButton.style.zIndex = 1001;
    } else {
      oSettleButton.style.zIndex = 1;
    }
    if (onWaitingPage) {
      oHelpBoard.style.display = "block";
    } else {
      oHelpBoard.style.display = "none";
    }
  });

  async function init() {
    initMessageBoard();
    selfCards = [];
    sequence = [
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
    ];
    selfIdSequence = [];
    opponentIdSequence = [0, 0, 0];
    opponentSequence = [getCard(0), getCard(0), getCard(0)];
    hands = [];
    tableId = 0;
    opponentName = "A worthy opponent";
    currentRound = 0;
    currentInning = 0;
    selfScore = 0;
    opponentScore = 0;
    canSettle = false;
    timePhase = "Preparing";
    timeToCountDown = 999;
    selfCommited = false;
    opponentCommited = false;
    hasInitialCardPoolPick = false;
    oHelpBoard.style.display = "none";

    addSubscription(
      listenTableCreated(web3, contractAddress, handleTableCreated, selfName)
    );
  }

  async function clearSubscriptions() {
    for (let subscription of subscriptions) {
      await subscription.unsubscribe();
    }
    subscriptions = [];
  }

  function addSubscription(subscription) {
    subscriptions = [...subscriptions, subscription];
  }

  async function initGame(_opponent) {
    newMessage("The game will start soon...");
    opponentName = _opponent;
    initGameListeners();
  }

  async function countDownCommitmentTime() {
    if (hasStartedFight || canRestart) {
      canSettle = false;
      stopSe(SE.Tick);
      return;
    }
    timeToCountDown--;
    if (!isPlaying(SE.Tick)) {
      broadcastSe(SE.Tick, false);
    }
    if (timeToCountDown == 5 && !selfCommited) {
      stopSe(SE.Tick);
      setTimeout(onFight, 0);
    }
    if (timeToCountDown < 0) {
      canSettle = true;
    }
    setTimeout(countDownCommitmentTime, 1000);
  }

  function onHelpBack() {
    if (canHelpBack) {
      broadcastSe(SE.Click);
      hideWaitingPage();
    }
  }

  function onShowHelp() {
    broadcastSe(SE.Click);
    let helpText = `The card pool will be generated randomly at the beginning of each Round. In the first inning players pick cards from the card pool, and at the beginning of each other round, players will get 2 cards with quality of corresponding to this round.

    Drag the card to the sequence. Click "Start Fighting!" to commit sequence, then start the fight at arena. Each inning has a time limit of 300 seconds. Hurry back to the war room so that you can have more time to think. If the opponent does not commit sequence within the limited time, you can claim the victory.
    
    You can choose the following two ways to strengthen your sequence: 
    (1) Upgrade: Drag a card with the same name to the sequence. Up to level 3.
    (2) Reforge: Click the reforge button, consume several cards, and confirm to create a higher quality card. The quality of the reforging card equals to (the sum of the qualities of the cards)/2, rounded down, and the corresponding quality card is selected from three random options.
    
    Think twice before acting. The sequence will be committed automatically when the countdown reaches the last 5 seconds.`;
    showWaitingPage(helpText, true, 800);
  }

  function onConceal() {
    broadcastSe(SE.Click);
    isConceal = !isConceal;
    if (isConceal) {
      if (onCardPick) {
        onCardPick = false;
        concealResumeCallback = () => {
          onCardPick = true;
        };
      } else if (onCardPoolPick) {
        onCardPoolPick = false;
        concealResumeCallback = () => {
          onCardPoolPick = true;
        };
      } else if (onWaitingPage) {
        onWaitingPage = false;
        concealResumeCallback = () => {
          onWaitingPage = true;
        };
      }
    } else {
      concealResumeCallback();
    }
  }

  async function onCreateTable() {
    broadcastSe(SE.Click);
    playMusic();
    closeTablePick();
    newMessage("Creating table...");
    isTableCreator = true;
    await web3CreateTable(web3, contractAddress);
  }

  async function onJoinTable(event) {
    broadcastSe(SE.Click);
    playMusic();
    closeTablePick();
    tableId = new BN(event.detail.tableId);
    let players = await web3GetPlayers(web3, contractAddress, tableId);
    newMessage(` ${players[0]} has created the table, id: ${tableId}`);
    newMessage("Joining table...");
    await web3JoinTable(web3, contractAddress, tableId);
    newMessage("You have joined the table, id: " + tableId);
    isTableCreator = false;
    initGame(players[0]);
  }

  async function onReforgeRequestConfirm(event) {
    onReforgeCancel();
    let pickedCards = event.detail.pickedCards;
    if (
      pickedCards.length == 1 &&
      getCard(selfCards[pickedCards[0].index].id).quality == QualityType.Low
    ) {
      alert(`The quality of the card is too low to reforge!`);
    } else {
      pickedCards = pickedCards.map(({ index: cardIndex }) => {
        let card = selfCards[cardIndex];
        card.used = true;
        hands.splice(indexOfHands(cardIndex), 1);
        return new RevealedCard(card.index, card.id, card.salt);
      });
      // call contract to reforge
      showWaitingPage("Waiting for reforge...", false);
      await web3ReforgeCard(web3, contractAddress, tableId, pickedCards);
    }
  }

  async function onReforgeSubmitConfirm(event) {
    broadcastSe(SE.Click);
    closeCardPick();
    let pickedCards = event.detail.pickedCards;
    let nonce = pickedCards[0];
    let pickedCard = cardsToPick[nonce];
    // call contract to reforge
    showWaitingPage("Waiting for submitting reforge...", false);
    await web3SummitReforge(
      web3,
      contractAddress,
      tableId,
      currentReforgeRequestId,
      nonce
    );
    let card = new Card(
      selfCards.length,
      pickedCard.id,
      CardType.Reforge,
      0,
      false
    );
    selfCards = [...selfCards, card];
    hands = [...hands, card];
    hideWaitingPage();
  }

  function onReforgeCancel() {
    broadcastSe(SE.Click);
    hands = hands;
    duringReforge = false;
    oHidden.style.display = "none";
    oHidden.style.height = "100%";
    canHandPan = true;
    canHandPick = false;
  }

  function showWaitingPage(_helpText, _canHelpBack, _boardHeight = 500) {
    canHelpBack = _canHelpBack;
    helpText = _helpText;
    helpBoardHeight = _boardHeight;
    onWaitingPage = true;
    oHidden.style.display = "block";
  }

  function hideWaitingPage() {
    onWaitingPage = false;
    isConceal = false;
    oHidden.style.display = "none";
  }

  async function onSetSequenceHolder(event) {
    let handIndex = event.detail.handIndex;
    let index = event.detail.index;
    let card = event.detail.card;
    if (index >= availableSequence[currentRound]) {
      return;
    }
    hands.splice(handIndex, 1);
    hands = hands;
    let originalCard = sequence[index];
    if (originalCard) {
      if (originalCard.id == card.id && card.id / (MAX_CARD_ID + 1) < 2) {
        // upgrade the card with the same id
        sequence[index] = await upgradeCard(originalCard, card);
      } else {
        // swap the original card to hand
        hands = [...hands, originalCard];
        sequence[index] = card;
      }
    } else {
      sequence[index] = card;
    }
  }

  async function upgradeCard(originalCard, card) {
    // upgrade the card with the same id
    originalCard.used = true;
    card.used = true;
    let newCard = new Card(
      selfCards.length,
      parseInt(card.id) + (MAX_CARD_ID + 1),
      CardType.Upgrade,
      0,
      false
    );
    let material1 = new RevealedCard(
      originalCard.index,
      originalCard.id,
      originalCard.salt
    );
    let material2 = new RevealedCard(card.index, card.id, card.salt);
    showWaitingPage("Waiting for upgrade...", false);
    await web3UpgradeCard(web3, contractAddress, tableId, [
      material1,
      material2,
    ]);
    hideWaitingPage();
    selfCards = [...selfCards, newCard];
    return newCard;
  }

  async function onSwapSequenceHolder(event) {
    let fromIndex = event.detail.fromIndex;
    let toIndex = event.detail.toIndex;
    let card = event.detail.card;
    if (fromIndex == toIndex || toIndex >= availableSequence[currentRound]) {
      return;
    }
    let originalCard = sequence[toIndex];
    if (originalCard) {
      if (originalCard.id == card.id && card.id / (MAX_CARD_ID + 1) < 2) {
        // upgrade the card with the same id
        sequence[toIndex] = await upgradeCard(originalCard, card);
        sequence[fromIndex] = undefined;
      } else {
        // swap the index of the two cards in sequence
        sequence[toIndex] = card;
        sequence[fromIndex] = originalCard;
      }
    } else {
      sequence[toIndex] = card;
      sequence[fromIndex] = undefined;
    }
  }

  function onDragToHand(event) {
    let index = event.detail.index;
    let card = event.detail.card;
    sequence[index] = undefined;
    hands = [...hands, card];
  }

  function indexOfSequence(cardIndex) {
    for (let i = 0; i < sequence.length; i++) {
      if (sequence[i] && sequence[i].index == cardIndex) {
        return i;
      }
    }
    return -1;
  }

  function indexOfHands(cardIndex) {
    for (let i = 0; i < hands.length; i++) {
      if (hands[i].index == cardIndex) {
        return i;
      }
    }
    return -1;
  }

  function startCardPoolPick() {
    oHidden.style.display = "block";
    onCardPoolPick = true;
  }

  function closeCardPoolPick() {
    oHidden.style.display = "none";
    onCardPoolPick = false;
    isConceal = false;
  }

  function startCardPick() {
    oHidden.style.display = "block";
    onCardPick = true;
  }

  function closeCardPick() {
    oHidden.style.display = "none";
    onCardPick = false;
    isConceal = false;
  }

  function startTablePick() {
    oHidden.style.display = "block";
    onTablePick = true;
  }

  function closeTablePick() {
    oHidden.style.display = "none";
    onTablePick = false;
  }

  async function onCardPoolConfirm(event) {
    broadcastSe(SE.Click);
    closeCardPoolPick();
    showWaitingPage("Waiting for submitting picked cards...", false);
    let pickedCards = event.detail.pickedCards;
    let commitments = [];
    for (let i = 0; i < pickedCards.length; i++) {
      let card = new Card(
        selfCards.length,
        pickedCards[i],
        CardType.Pick,
        getSalt(),
        false
      );
      selfCards = [...selfCards, card];
      hands = [...hands, card];
      commitments.push(
        web3.utils.toBN(web3.utils.soliditySha3(card.index, card.id, card.salt))
      );
    }
    await web3CommitPickedCards(web3, contractAddress, tableId, commitments);
    hideWaitingPage();
  }

  function initMessageBoard() {
    oMmessageBoard.initMessages(
      [oMmessageBoard.createMessage("Waiting for the game to start...")],
      oMmessageBoard.createMessage(
        "3 rounds will be played in total, with 2/2/3 innings respectively (the initial action order will be randomly determined, and the loser will on the offensive in the next inning)."
      )
    );
  }

  function newMessage(text) {
    oMmessageBoard.appendMessage(text);
  }

  function playMusic() {
    if (isMuted) {
      return;
    }
    let musicIndex = Math.floor(Math.random() * 6) + 1;
    oAudio.src = `./audios/bgm/${musicIndex}.mp3`;
    // play audio
    oAudio.currentTime = 1;
    oAudio.volume = 0;
    musicTimer = setInterval(() => {
      if (oAudio.volume >= 0.2) {
        clearInterval(musicTimer);
      }
      oAudio.volume += 0.01;
    }, 100);
    oAudio.play();
  }

  async function commitSequence() {
    let jointCommitment = 0;
    for (let i = 0; i < availableSequence[currentRound]; i++) {
      if (sequence[i]) {
        jointCommitment = web3.utils.soliditySha3(
          jointCommitment,
          web3.utils.toBN(
            web3.utils.soliditySha3(
              sequence[i].index,
              sequence[i].id,
              sequence[i].salt
            )
          )
        );
      } else {
        jointCommitment = web3.utils.soliditySha3(
          jointCommitment,
          web3.utils.toBN(web3.utils.soliditySha3(0, 0, 0))
        );
      }
    }
    await web3CommitSequence(web3, contractAddress, tableId, jointCommitment);
  }

  async function onFight() {
    broadcastSe(SE.Click);
    pauseInteraction();
    showWaitingPage(
      `Waiting for the battle to begin...

    (You can click settle button to claim victory after the timeout)`,
      false
    );
    await commitSequence();
    timePhase = "Committed";
    selfCommited = true;
    if (opponentCommited) {
      newMessage("Sending the original sequence...");
      newMessage("Waiting for the opponent to commit...", false);
      await submitSequence();
    }
  }

  async function submitSequence() {
    selfIdSequence = [];
    let revealedSequence = [];
    for (let i = 0; i < availableSequence[currentRound]; i++) {
      if (sequence[i]) {
        selfIdSequence.push(sequence[i].id);
        revealedSequence.push(
          new RevealedCard(sequence[i].index, sequence[i].id, sequence[i].salt)
        );
      } else {
        selfIdSequence.push(0);
        revealedSequence.push(new RevealedCard(0, 0, 0));
      }
    }
    await web3RevealSequence(web3, contractAddress, tableId, revealedSequence);
    timePhase = "Revealed";
  }

  function pauseInteraction() {
    canHandPan = false;
    canSequencePan = false;
    canPlay = false;
    canReforge = false;
  }

  function resumeInteraction() {
    canHandPan = true;
    canSequencePan = true;
    canPlay = true;
    canReforge = true;
  }

  function onReforge() {
    broadcastSe(SE.Click);
    oHidden.style.height = "61%";
    oHidden.style.display = "block";
    duringReforge = true;
    canHandPan = false;
    canHandPick = true;
  }

  async function onRestart() {
    broadcastSe(SE.Click);
    await clearSubscriptions();
    canRestart = false;
    await init();
    startTablePick();
  }

  async function onSettle() {
    canSettle = false;
    try {
      newMessage("Try claiming victory...");
      await web3ClaimVictory(web3, contractAddress, tableId);
      newMessage("Success! You win!");
      hideWaitingPage();
      pauseInteraction();
      canRestart = true;
    } catch (e) {
      console.log(e);
      canSettle = true;
      newMessage(
        "Claim failed, the opponent's action has not timed out yet!",
        true
      );
    }
  }

  function onSwitchAudioVolumn() {
    broadcastSe(SE.Click);
    if (isMuted) {
      oAudio.volume = 0.2;
      unmuteAll();
      isMuted = false;
    } else {
      if (musicTimer) clearInterval(musicTimer);
      oAudio.volume = 0;
      muteAll();
      isMuted = true;
    }
  }

  function onShowOpponentSequence() {
    broadcastSe(SE.Click);
    if (oOpponentSequenceBox.style.display == "flex") {
      oOpponentSequenceBox.style.display = "none";
    } else {
      oOpponentSequenceBox.style.display = "flex";
    }
  }

  async function onSimulateBattle() {
    broadcastSe(SE.Click);
    oHidden.style.display = "block";
    clearFightCallback();
    selfIdSequence = [];
    for (let i = 0; i < availableSequence[currentRound]; i++) {
      if (sequence[i]) {
        selfIdSequence.push(sequence[i].id);
      } else {
        selfIdSequence.push(0);
      }
    }
    // simulate 200 times then count chance of winning
    let winCount = 0;
    for (let i = 0; i < 200; i++) {
      prepareNextBattle();
      let randomNumber = Math.floor(Math.random() * 10000) + 1;
      let simulationRandomness = web3.utils.toBN(randomNumber);

      let selfWin = await fight(
        self,
        enemy,
        selfIdSequence,
        opponentIdSequence,
        isSelfOffensive,
        simulationRandomness
      );
      if (selfWin) {
        winCount++;
      }
    }
    let winRate = winCount / 200;
    newMessage(`Battle simulation win rate: ${(winRate * 100).toFixed(4)}%`);
    oHidden.style.display = "none";
  }

  async function onArenaSkip() {
    playMusic();
    oWarRoom.style.display = "flex";
    oArena.style.display = "none";
    hasStartedFight = false;
    selfCommited = false;
    opponentCommited = false;
    await warRoomResumeCallback();
    timePhase = "Preparing";
    if (!canRestart) {
      resumeInteraction();
    }
  }

  function startFight(randomness, selfWin) {
    oAudio.pause();
    hideWaitingPage();
    oWarRoom.style.display = "none";
    oDesc.style.display = "none";

    prepareNextBattle();

    fightRandomness = web3.utils.toBN(randomness);
    outcome = selfWin ? "win" : "lose";
    round = 0;

    oOpponentSequenceBox.style.display = "none";
    oArena.style.display = "block";
  }

  function prepareNextBattle() {
    let maxHealth;
    let damage;
    if (currentRound == 0) {
      maxHealth = 3000;
      damage = 150;
    } else if (currentRound == 1) {
      maxHealth = 6000;
      damage = 300;
    } else if (currentRound == 2) {
      maxHealth = 12000;
      damage = 600;
    } else {
      throw "Invalid round";
    }

    self = PlayerState.buildPlayerState(IdentityType.Self, maxHealth, damage);
    enemy = PlayerState.buildPlayerState(IdentityType.Enemy, maxHealth, damage);
  }

  function printGameScores() {
    return "(" + selfScore + ":" + opponentScore + ")";
  }

  function initGameListeners() {
    addSubscription(
      listenGameStarted(web3, contractAddress, handleGameStarted, tableId)
    );
    addSubscription(
      listenCardPoolGenerated(
        web3,
        contractAddress,
        handleCardPoolGenerated,
        tableId
      )
    );
    addSubscription(
      listenCardDrawn(web3, contractAddress, handleCardDrawn, tableId, selfName)
    );
    addSubscription(
      listenCardReforgeGenerated(
        web3,
        contractAddress,
        handleCardReforgeGenerated,
        tableId,
        selfName
      )
    );
    addSubscription(
      listenSequenceCommitted(
        web3,
        contractAddress,
        handleSequenceCommitted,
        tableId,
        opponentName
      )
    );
    addSubscription(
      listenSequenceRevealed(
        web3,
        contractAddress,
        handleSequenceRevealed,
        tableId,
        opponentName
      )
    );
    addSubscription(
      listenInningEnded(web3, contractAddress, handleInningEnded, tableId)
    );
    addSubscription(
      listenRoundEnded(web3, contractAddress, handleRoundEnded, tableId)
    );
    addSubscription(
      listenGameEnded(web3, contractAddress, handleGameEnded, tableId)
    );
  }

  function handleTableCreated(event) {
    newMessage("You have created the table, id: " + event.returnValues.tableId);
    tableId = new BN(event.returnValues.tableId);
    addSubscription(
      listenTableJoined(
        web3,
        contractAddress,
        handleTableJoined,
        event.returnValues.tableId
      )
    );
  }

  async function handleTableJoined(event) {
    newMessage(
      `${event.returnValues.player} has joined the table, id: ${event.returnValues.tableId}`
    );
    initGame(event.returnValues.player);
  }

  async function handleGameStarted(event) {
    newMessage("The game has started.");
    newMessage("Generating the card pool...");
    nextCommitmentTime = event.returnValues.nextCommitmentTime;
    let firstPlayerOffensive = event.returnValues.firstPlayerOffensive;

    isSelfOffensive = isTableCreator
      ? firstPlayerOffensive
      : !firstPlayerOffensive;
    timeToCountDown = nextCommitmentTime - Math.floor(Date.now() / 1000);
    await countDownCommitmentTime();
  }

  function handleCardPoolGenerated(event) {
    cardPool = event.returnValues.cardPool;
    if (!hasInitialCardPoolPick) {
      hasInitialCardPoolPick = true;
      startCardPoolPick();
      resumeInteraction();
    }
  }

  function handleCardDrawn(event) {
    let cards = event.returnValues.cards;
    for (let i = 0; i < cards.length; i++) {
      let card = new Card(
        selfCards.length,
        cards[i].id,
        CardType.Draw,
        0,
        false
      );
      selfCards = [...selfCards, card];
      hands = [...hands, card];
    }
  }

  async function handleSequenceCommitted(event) {
    newMessage("Your opponent has committed the sequence.");
    opponentCommited = true;
    if (selfCommited) {
      newMessage("Sending the original sequence...");
      await submitSequence();
    }
  }

  async function handleSequenceRevealed(event) {
    newMessage(
      "Your opponent has played the sequence, the inning will start soon."
    );
    let revealedSequence = event.returnValues.cards;
    opponentIdSequence = revealedSequence.map((card) => {
      return parseInt(card.id);
    });
    opponentSequence = revealedSequence.map((card) => {
      return getCard(card.id);
    });
  }

  function handleCardReforgeGenerated(event) {
    let randomness = event.returnValues.randomness;
    let qualityToReforge = event.returnValues.qualityToReforge;
    currentReforgeRequestId = event.returnValues.requestId;
    let fromCards =
      qualityToReforge == 0
        ? LOW_QUALITY_CARD_IDS
        : qualityToReforge == 1
          ? MIDDLE_QUALITY_CARD_IDS
          : HIGH_QUALITY_CARD_IDS;
    let availableCards = repeatedDraw(randomness, fromCards, 3);
    cardsToPick = availableCards.map((card, index) => {
      return new Card(index, card, CardType.Reforge, 0, false);
    });

    hideWaitingPage();
    startCardPick();
  }

  async function handleInningEnded(event) {
    let winner = event.returnValues.winner;
    let randomness = event.returnValues.randomness;
    let nextCommitmentTime = event.returnValues.nextCommitmentTime;
    let selfWin = winner.toLowerCase() == selfName.toLowerCase();
    if (winner == selfName) {
      selfScore++;
    } else {
      opponentScore++;
    }

    warRoomResumeCallback = async () => {
      newMessage(
        `Inning ${currentInning} has ended, the winner is ${winner}. ${printGameScores()}`
      );
      if (currentInning == 2 && currentRound == 2) {
        // Game Ended
        return;
      } else if (currentInning == 1 && currentRound < 2) {
        currentInning = 0;
        currentRound++;
        startCardPoolPick();
      } else {
        currentInning++;
      }
      isSelfOffensive = !selfWin;
      newMessage(
        `The next inning has started. You are on the ${
          isSelfOffensive ? "offensive" : "defensive"
        }.`
      );
      timeToCountDown = nextCommitmentTime - Math.floor(Date.now() / 1000);
      await countDownCommitmentTime();
    };

    startFight(randomness, selfWin);
    hasStartedFight = true;
  }

  async function handleRoundEnded(event) {
    newMessage(`Round ${currentRound} has ended.`);
  }

  function handleGameEnded(event) {
    let winner = event.returnValues.winner;
    if (winner.toLowerCase() == selfName.toLowerCase()) {
      newMessage(`You won the game! Thanks for playing! ${printGameScores()}`);
    } else {
      newMessage(
        `Opponent won the game! Thanks for playing! ${printGameScores()}`
      );
    }
    pauseInteraction();
    canSettle = false;
    canRestart = true;
  }
</script>

<body>
  <div class="bg" bind:this={oWarRoom}>
    <div class="state-bar">
      <RoundState
        selfAddress={selfName}
        opponentAddress={opponentName}
        round={currentRound}
        inning={currentInning}
        {time}
        {selfScore}
        {opponentScore}
        {isSelfOffensive}
        on:showHelp={onShowHelp}
      >
        <div slot="audioVolumn" class="audioVolumnButton">
          <AudioVolumn {isMuted} on:switchVol={onSwitchAudioVolumn} />
        </div>
        <div
          slot="opponentSequence"
          class="opponentSequenceButton"
          on:click={onShowOpponentSequence}
        ></div>
        <div
          slot="battleSimulation"
          class="battleSimulationButton"
          on:click={onSimulateBattle}
        ></div>
      </RoundState>
    </div>
    <div class="messageBox">
      <MessageBoard bind:this={oMmessageBoard} />
    </div>
    <div class="sequence-bar">
      <div class="sequence-box">
        <Sequence
          {sequence}
          canPan={canSequencePan}
          availableSequence={sequenceUpperBound}
          on:swapSequenceHolder={onSwapSequenceHolder}
          on:dragToHand={onDragToHand}
        />
      </div>
      <div class="control-box">
        <ControlPanel
          enablePlay={canPlay}
          enableReforge={canReforge}
          enableRestart={canRestart}
          on:play={onFight}
          on:reforge={onReforge}
          on:restart={onRestart}
        >
          <button
            slot="exbutton"
            class="settleButton"
            disabled={!canSettle}
            bind:this={oSettleButton}
            on:click={onSettle}
          >
            Settle
          </button>
        </ControlPanel>
      </div>
    </div>
    <div class="hand-bar" bind:this={oHand}>
      <Hand
        cards={hands}
        canPan={canHandPan}
        canPick={canHandPick}
        onReforge={duringReforge}
        on:setSequenceHolder={onSetSequenceHolder}
        on:confirm={onReforgeRequestConfirm}
        on:cancel={onReforgeCancel}
      />
    </div>
  </div>
  <div class="arena" bind:this={oArena}>
    <Arena
      on:skip={onArenaSkip}
      {self}
      {enemy}
      selfSequence={selfIdSequence}
      enemySequence={opponentIdSequence}
      selfFirst={isSelfOffensive}
      randomness={fightRandomness}
      {outcome}
      {round}
    />
  </div>
  <div class="audio">
    <!-- svelte-ignore a11y-media-has-caption -->
    <audio controls loop bind:this={oAudio} />
  </div>
  <div class="desc" bind:this={oDesc} />
  <div class="hidden" bind:this={oHidden} />
  <div class="help-box" bind:this={oHelpBoard}>
    <HelpBoard
      {helpText}
      boardHeight={helpBoardHeight}
      canBack={canHelpBack}
      on:back={onHelpBack}
    />
  </div>
  <TablePicker
    onPick={onTablePick}
    on:create={onCreateTable}
    on:join={onJoinTable}
  />
  <CardPool
    ids={cardPool}
    onPick={onCardPoolPick}
    pickNum={sequenceUpperBound}
    on:confirm={onCardPoolConfirm}
  />
  <CardPick
    cards={cardsToPick}
    onPick={onCardPick}
    pickNum={1}
    on:confirm={onReforgeSubmitConfirm}
  />
  <button class="conceal" disabled={!concealButtonEnabled} on:click={onConceal}
    >{isConceal ? "Return" : "Conceal"}</button
  >
  <div class="opponent-sequence-box" bind:this={oOpponentSequenceBox}>
    <Sequence
      sequence={opponentSequence}
      canPan={false}
      availableSequence={sequenceUpperBound}
    />
  </div>
</body>

<style>
  body {
    overflow: hidden;
  }
  .bg {
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    align-items: center;
    height: 100vh;
    background: url(/images/bg.jpg) no-repeat;
    background-size: cover;
  }
  .hidden {
    width: 100%;
    height: 100%;
    position: fixed;
    top: 0;
    left: 0;
    background-color: #000000;
    opacity: 0.3;
    display: block;
    z-index: 999;
  }
  .state-bar {
    border-style: solid;
    border-top-style: none;
    display: flex;
    justify-content: space-between;
    align-items: center;
    width: 100%;
    height: 10vh;
  }
  .messageBox {
    display: flex;
    justify-content: center;
    height: 10vh;
    width: 80%;
    z-index: 1000;
  }
  .sequence-bar {
    border-style: solid;
    display: flex;
    justify-content: space-between;
    align-items: center;
    width: 96%;
    height: 40vh;
  }
  .sequence-box {
    border-style: solid;
    display: flex;
    justify-content: space-between;
    align-items: center;
    width: 90%;
    height: 100%;
  }
  .control-box {
    border-style: solid;
    display: flex;
    justify-content: space-between;
    align-items: center;
    width: 8%;
    height: 100%;
  }
  .hand-bar {
    border-style: solid;
    border-top-style: none;
    display: flex;
    justify-content: space-between;
    align-items: center;
    width: 90%;
    height: 40vh;
    margin-left: 50px;
    margin-right: 50px;
  }
  .desc {
    position: absolute;
    top: 0;
    left: 0;
    width: 20%;
    height: 3rem;
    z-index: 998;
    font-weight: bold;
  }
  .arena {
    display: none;
  }
  .audio {
    display: none;
  }
  .conceal {
    position: absolute;
    bottom: 50px;
    right: 10px;
    width: 100px;
    height: 3rem;
    z-index: 1005;
    font-weight: bold;
  }
  .settleButton {
    position: relative;
    font-family: "Comic Sans MS", cursive;
    font-size: 1.6em;
    z-index: 1001;
  }
  .help-box {
    display: none;
  }
  .audioVolumnButton {
    width: 50px;
    height: 50px;
    border-radius: 10px;
    cursor: pointer;
  }
  .opponentSequenceButton {
    width: 50px;
    height: 50px;
    border-radius: 10px;
    background-image: url(/images/show_opponent_sequence.png);
    background-size: cover;
    cursor: pointer;
  }
  .battleSimulationButton {
    width: 50px;
    height: 50px;
    border-radius: 10px;
    background-image: url(/images/simulation.png);
    background-size: cover;
    cursor: pointer;
  }
  .opponent-sequence-box {
    display: none;
    position: absolute;
    top: 8vh;
    left: -15vh;
    border-style: none;
    justify-content: space-between;
    width: 106%;
    scale: 0.8;
  }
</style>
