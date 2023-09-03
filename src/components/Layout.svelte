<script>
  import Web3 from "web3";
  import Player from "./Player.svelte";
  import Hand from "./Hand.svelte";
  import BattleBoard from "./BattleBoard.svelte";
  import WinballBoard from "./WinballBoard.svelte";
  import Card, {
    getCardByCode,
    clearCardPlayFlag,
    bgPooker,
  } from "./Card.svelte";
  import ControlPanel from "./ControlPanel.svelte";
  import MessageBoard from "./MessageBoard.svelte";
  import { onMount } from "svelte";
  import RuleBoard from "./RuleBoard.svelte";
  import RulePicker, { buildRuleDesc } from "./RulePicker.svelte";
  import TablePicker from "./TablePicker.svelte";
  import CardPool from "./CardPool.svelte";
  import {
    createTable,
    getRandomSeed,
    joinTable,
    listenCardPoolGenerated,
    listenTableCreated,
    listenTableJoined,
    commitHands,
    listenHandsCommitted,
    commit,
    playCard,
    listenCardCommitted,
    listenCardPlayed,
    listenRoundEnded,
    listenSetEnded,
    getPlayers,
    sendETH,
    listenRuleTypeDetermined,
    determineRuleType,
    getSalt,
  } from "../utils/web3";

  let playerDuck = [],
    opponentDuck = [];
  let oPlayerDucks = [],
    oOpponentDucks = [];
  let playerBattleCard, opponentBattleCard;
  let playerWinballBoard, opponentWinballBoard;
  let playerBalls = [];
  let opponentBalls = [];
  let playerPoint, opponentPoint;
  let playButton;
  let focusingCard, focusingIndex, focusingCardSalt;
  let messageBoard;
  let ruleMode = { role: -1, mode: -1 };
  let oHidden;
  let onRulePick;
  let onTablePick;
  let onCardPoolPick;
  let web3;
  let websocketProvider = import.meta.env.WEBSOCKET_PROVIDER;
  let contractAddress = import.meta.env.CONTRACT_ADDRESS;
  let devAccounts = import.meta.env.DEV_ACCOUNTS;
  let demoETHValue = import.meta.env.DEMO_ETH_VALUE;
  let myName = "Card Beginner";
  let opponentName = "Card Sensei";
  let opponent;
  let tableId;
  let cardPool = [];
  let playerCommitedHands;
  let opponentCommitedHands;
  let roundPlayed;
  let ruleDetermined;
  let playerCommited;
  let opponentCommited;
  let playerPickRule;
  let canRestart;
  let BN;
  $: isPlayable =
    playerCommitedHands &&
    opponentCommitedHands &&
    ruleDetermined &&
    !roundPlayed;

  onMount(async () => {
    oHidden.style.display = "block";
    web3 = new Web3(new Web3.providers.WebsocketProvider(websocketProvider));

    BN = web3.utils.BN;
    // TODO we create a new keypair for demo use
    web3.eth.accounts.wallet.create(1);
    for (var i = 0; i < 20; i++) {
      try {
        let index = Math.floor(Math.random() * devAccounts.length);
        let account = web3.eth.accounts.wallet.add(devAccounts[index]);
        await sendETH(
          web3,
          account.address,
          web3.eth.accounts.wallet[0].address,
          demoETHValue
        );
        break;
      } catch (error) {
        console.error(error);
      }
    }
    init();
    startTablePick();
  });

  async function init() {
    (playerDuck = []), (opponentDuck = []);
    ruleMode = { role: -1, mode: -1 };
    playerBattleCard = undefined;
    opponentBattleCard = undefined;
    ruleDetermined = false;
    playerBalls = [
      { id: "0", win: false },
      { id: "1", win: false },
    ];
    opponentBalls = [
      { id: "0", win: false },
      { id: "1", win: false },
    ];
    // A randomness will decide the card pool and the rule for the first set
    initMessageBoard();
    myName =
      web3.eth.accounts.wallet[0].address.slice(0, 4) +
      "..." +
      web3.eth.accounts.wallet[0].address.slice(-4);

    listenTableCreated(
      web3,
      contractAddress,
      handleTableCreated,
      web3.eth.accounts.wallet[0].address
    );
  }

  async function initGame(_opponent) {
    opponent = _opponent;
    // check length of the opponent address
    if (opponent.length > 8) {
      opponentName = opponent.slice(0, 4) + "..." + opponent.slice(-4);
    }
    initGameListeners();
    await nextSet();
  }

  function initGameListeners() {
    listenCardPoolGenerated(
      web3,
      contractAddress,
      handleCardPoolGenerated,
      tableId
    );
    listenHandsCommitted(
      web3,
      contractAddress,
      handleHandsCommitted,
      tableId,
      opponent
    );
    listenCardCommitted(
      web3,
      contractAddress,
      handleCardCommitted,
      tableId,
      opponent
    );
    listenCardPlayed(
      web3,
      contractAddress,
      handleCardPlayed,
      tableId,
      opponent
    );
    listenRoundEnded(web3, contractAddress, handleRoundEnded, tableId);
    listenSetEnded(web3, contractAddress, handleSetEnded, tableId);
    listenRuleTypeDetermined(
      web3,
      contractAddress,
      handleRuleTypeDetermined,
      tableId
    );
  }

  async function onCreateTable() {
    closeTablePick();
    newMessage("Creating table...");
    await createTable(web3, contractAddress);
  }

  async function onJoinTable(event) {
    closeTablePick();
    tableId = new BN(event.detail.tableId);
    let players = await getPlayers(web3, contractAddress, tableId);
    newMessage(` ${players[0]} has created the table, id: ${tableId}`);
    newMessage("Joining table...");
    await joinTable(web3, contractAddress, tableId);
    newMessage("You have joined the table, id: " + tableId);
    initGame(players[0]);
  }

  async function onCardPoolConfirm(event) {
    let confirmedHands = event.detail.confirmedHands;
    closeCardPoolPick(confirmedHands);
    let hands = [];
    for (let i = 0; i < 5; i++) {
      if (i == 0 || i == 1) {
        let salt = getSalt();
        oPlayerDucks[i].salt = salt;
        hands.push(
          web3.utils.toBN(web3.utils.soliditySha3(confirmedHands[i].code, salt))
        );
      } else {
        hands.push(web3.utils.toBN(confirmedHands[i].code));
      }
    }
    playerDuck = confirmedHands;
    newMessage("Sending your hands commitment to the chain...");
    await commitHands(web3, contractAddress, tableId, hands);
    playerCommitedHands = true;

    checkTheFirstRoundStart();

    if (playerPickRule) {
      playerPickRule = false;
      startRulePick();
    }
  }

  async function onChooseRulePick(event) {
    closeRulePick();
    await determineRuleType(web3, contractAddress, tableId, event.detail.mode);
  }

  function handleTableCreated(event) {
    newMessage("You have created the table, id: " + event.returnValues.tableId);
    tableId = new BN(event.returnValues.tableId);
    listenTableJoined(
      web3,
      contractAddress,
      handleTableJoined,
      event.returnValues.tableId
    );
  }

  async function handleTableJoined(event) {
    newMessage(
      `${event.returnValues.player} has joined the table, id: ${event.returnValues.tableId}`
    );
    initGame(event.returnValues.player);
  }

  function handleCardPoolGenerated(event) {
    newMessage("Card pool generated, please select your hands.");
    cardPool = [];
    event.returnValues.cardPool.forEach((card) => {
      cardPool.push(getCardByCode(card));
    });
    newMessage("Start in 5 seconds...");
    setTimeout(() => {
      startCardPoolPick();
    }, 5000);
  }

  function handleRuleTypeDetermined(event) {
    if (event.returnValues.player.toLowerCase() == opponent.toLowerCase()) {
      updateRuleMode(2, event.returnValues.ruleType);
    } else if (
      event.returnValues.player.toLowerCase() ==
      web3.eth.accounts.wallet[0].address.toLowerCase()
    ) {
      updateRuleMode(1, event.returnValues.ruleType);
    } else {
      updateRuleMode(0, event.returnValues.ruleType);
    }
    ruleDetermined = true;
    checkTheFirstRoundStart();
  }

  function handleHandsCommitted(event) {
    newMessage("Your opponent has committed the hands.");
    let hands = event.returnValues.hands;
    opponentDuck = [
      bgPooker,
      bgPooker,
      getCardByCode(Number(hands[2])),
      getCardByCode(Number(hands[3])),
      getCardByCode(Number(hands[4])),
    ];
    opponentCommitedHands = true;
    checkTheFirstRoundStart();
  }

  async function handleCardCommitted(event) {
    newMessage("Your opponent has committed the card.");
    opponentBattleCard = { ...bgPooker };

    opponentCommited = true;
    if (playerCommited) {
      playerCommited = false;
      opponentCommited = false;
      newMessage("Sending the original card...");
      await playCard(
        web3,
        contractAddress,
        tableId,
        focusingIndex,
        focusingCard.code,
        focusingCardSalt,
        oPlayerDucks[focusingIndex].salt
      );
    }
  }

  function handleCardPlayed(event) {
    newMessage("Your opponent has played the card.");
    let card = getCardByCode(Number(event.returnValues.card));
    opponentBattleCard = { ...card };
    // show hide cards
    if (event.returnValues.index < 2) {
      opponentDuck[event.returnValues.index] = card;
    }
    // change opacity
    oOpponentDucks[event.returnValues.index].vague = true;
  }

  function handleRoundEnded(event) {
    let endRound = Number(event.returnValues.round);
    newMessage(`Round ${endRound} ended.`);
    let winner = event.returnValues.winner;
    if (web3.utils.toBN(winner).isZero()) {
      newMessage(`Wow draw round!`);
    } else {
      if (winner.toLowerCase() == opponent.toLowerCase()) {
        opponentPoint += Number(event.returnValues.points);
      } else {
        playerPoint += Number(event.returnValues.points);
      }
      newMessage(`Winner: ${winner} with points: ${event.returnValues.points}`);
    }

    if (endRound < 5) {
      newMessage(`Next round starts in 5 seconds.`);
      setTimeout(() => {
        playerBattleCard = undefined;
        opponentBattleCard = undefined;
        roundPlayed = false;
        newMessage(`Round ${endRound + 1} starts. Please pick a card to play.`);
      }, 5000);
    }
  }

  async function handleSetEnded(event) {
    let endSet = Number(event.returnValues.set);
    newMessage(`Set ${endSet} ended.`);
    ruleDetermined = false;
    let winner = event.returnValues.winner;
    if (web3.utils.toBN(winner).isZero()) {
      setFixedMessage(
        `Wow draw set, a randomness will determine the rule for the next set!`
      );
      setTimeout(async () => {
        newMessage(`Next set starts in 2 seconds`);
        await nextSet();
      }, 2000);
    } else if (winner.toLowerCase() == opponent.toLowerCase()) {
      if (opponentBalls[0].win) {
        opponentBalls[1].win = true;
        newMessage(
          `Opponent won the game! Thanks for playing! ${printGameScores()}`
        );
        canRestart = true;
      } else {
        opponentBalls[0].win = true;
        newMessage(`Opponent won the set! ${printGameScores()}`);
        setFixedMessage(
          `As a compensation, you will pick the rule for the next set!`
        );
        playerPickRule = true;
        setTimeout(async () => {
          newMessage(`Next set starts in 2 seconds`);
          await nextSet();
        }, 2000);
      }
    } else {
      if (playerBalls[0].win) {
        playerBalls[1].win = true;
        newMessage(
          `You won the game! Thanks for playing! ${printGameScores()}`
        );
        canRestart = true;
      } else {
        playerBalls[0].win = true;
        newMessage(`You won the set! ${printGameScores()}`);
        setFixedMessage("Waiting for the opponent to pick the rule...");
        setTimeout(async () => {
          newMessage(`Next set starts in 2 seconds`);
          await nextSet();
        }, 2000);
      }
    }
  }

  async function nextSet() {
    clearCardPlayFlag();
    (playerDuck = []), (opponentDuck = []);
    ruleMode = { role: -1, mode: -1 };
    playButton = false;
    playerBattleCard = undefined;
    opponentBattleCard = undefined;
    playerPoint = 0;
    opponentPoint = 0;
    oPlayerDucks = [
      { picked: false, vague: false, salt: 0 },
      { picked: false, vague: false, salt: 0 },
      { picked: false, vague: false, salt: 0 },
      { picked: false, vague: false, salt: 0 },
      { picked: false, vague: false, salt: 0 },
    ];
    oOpponentDucks = [
      { vague: false },
      { vague: false },
      { vague: false },
      { vague: false },
      { vague: false },
    ];
    cardPool = [];
    playerCommitedHands = false;
    opponentCommitedHands = false;
    roundPlayed = false;

    newMessage("Requesting randomness...");
    await getRandomSeed(web3, contractAddress, tableId);
  }

  function startRulePick() {
    oHidden.style.display = "block";
    onRulePick = true;
  }

  function startTablePick() {
    oHidden.style.display = "block";
    onTablePick = true;
  }

  function startCardPoolPick() {
    oHidden.style.display = "block";
    onCardPoolPick = true;
  }

  function closeRulePick() {
    oHidden.style.display = "none";
    onRulePick = false;
  }

  function closeTablePick() {
    oHidden.style.display = "none";
    onTablePick = false;
  }

  function closeCardPoolPick() {
    oHidden.style.display = "none";
    onCardPoolPick = false;
  }

  function initMessageBoard() {
    messageBoard.initMessages(
      ["Welcome! Let's have a card battle! Best of three!"].map(
        messageBoard.createMessage
      ),
      messageBoard.createMessage("Waiting for the game to start...")
    );
  }

  function focus(event) {
    if (isPlayable) {
      let playerCard = event.detail.wantCard;
      let index = event.detail.index;
      foucsOnCardFromHand(playerCard, index);
    }
  }

  function foucsOnCardFromHand(playerCard, index) {
    // play once per card during one game
    if (playerCard.chosen) return;
    // handle and render picked
    let pickedIndex = getPickedFromDuck(oPlayerDucks);
    oPlayerDucks[index].picked = true;
    if (pickedIndex > -1) {
      oPlayerDucks[pickedIndex].picked = false;
    }
    if (pickedIndex === index) {
      restorePlayButton();
    } else {
      setFocusCard(playerCard, index);
      enablePlayButton();
    }
  }

  async function onPlay() {
    roundPlayed = true;
    focusingCardSalt = getSalt();
    focusingCard.chosen = true;
    playerBattleCard = { ...focusingCard };
    oPlayerDucks[focusingIndex].vague = true;
    unpickDuck(oPlayerDucks);
    restorePlayButton();

    newMessage("Sending the commitment of the card...");
    await commit(
      web3,
      contractAddress,
      tableId,
      web3.utils.soliditySha3(focusingCard.code, focusingCardSalt)
    );

    playerCommited = true;
    if (opponentCommited) {
      opponentCommited = false;
      playerCommited = false;
      newMessage("Sending the original card...");
      await playCard(
        web3,
        contractAddress,
        tableId,
        focusingIndex,
        focusingCard.code,
        focusingCardSalt,
        oPlayerDucks[focusingIndex].salt
      );
    }
  }

  async function onNextGame() {
    await nextSet();
  }

  function onRestart() {
    web3.eth.clearSubscriptions();
    canRestart = false;
    init();
    startTablePick();
  }

  function checkTheFirstRoundStart() {
    if (playerCommitedHands && opponentCommitedHands && ruleDetermined) {
      newMessage("The first round starts. Please pick a card to play.");
    }
  }

  function unpickDuck(oPlayerDucks) {
    for (let ocard of oPlayerDucks) {
      ocard.picked = false;
    }
  }

  function restorePlayButton() {
    playButton = false;
  }

  function enablePlayButton() {
    playButton = true;
  }

  function setFocusCard(_focusCard, _focusIndex) {
    focusingCard = _focusCard;
    focusingIndex = _focusIndex;
  }

  function getPickedFromDuck(oPlayerDucks) {
    for (let index in oPlayerDucks) {
      if (oPlayerDucks[index].picked) {
        return Number(index);
      }
    }
    return -1;
  }

  function newMessage(text) {
    messageBoard.appendMessage(text);
  }

  function setFixedMessage(text) {
    messageBoard.setFixedMessage(text);
  }

  function printGameScores() {
    return (
      "(" +
      playerWinballBoard.printScore() +
      ":" +
      opponentWinballBoard.printScore() +
      ")"
    );
  }

  function updateRuleMode(role, mode) {
    ruleMode.role = role;
    ruleMode.mode = Number(mode);
    setFixedMessage(
      `The current set uses ${buildRuleDesc(Number(mode))} by ${formatRuleRole(
        role
      )}.`
    );
  }

  // role: -1-TBD 0-Randomness 1-You 2-Opponent
  function formatRuleRole(role) {
    switch (role) {
      case -1:
        return "TBD";
      case 0:
        return "Randomness";
      case 1:
        return "You";
      case 2:
        return "Opponent";
    }
  }

  function panEndHandler(wantCard, index, x, y) {
    // decide if this is a valid pan
    // if (x > 300 && x < 550 && y > 100 && y < 300) {
    if (y > 100 && y < 300) {
      // decide if player had focused on another card then dragged this one
      if (getPickedFromDuck(oPlayerDucks) != index) {
        foucsOnCardFromHand(wantCard, index);
      }
      // take this as play that card
      onPlay();
    }
    return [-1, -1];
  }
</script>

<div class="bg">
  <header />
  <div class="box">
    <Player>
      <img
        slot="avatar"
        src="/images/player.jpg"
        alt="player"
        height={100}
        width={100}
      />
      <span slot="name"> {myName} </span>
      <span slot="level"> 1 </span>
      <span slot="win"> 0 </span>
      <span slot="lose"> 0 </span>
      <span slot="rank"> 999+ </span>
    </Player>
    <WinballBoard balls={playerBalls} bind:this={playerWinballBoard} />
    <BattleBoard points={playerPoint} battlecard={playerBattleCard} />
    <RuleBoard class="ruleBoard">
      <span slot="mode"> {ruleMode.mode} </span>
      <span slot="role"> {formatRuleRole(ruleMode.role)} </span>
    </RuleBoard>
    <BattleBoard points={opponentPoint} battlecard={opponentBattleCard} />
    <WinballBoard balls={opponentBalls} bind:this={opponentWinballBoard} />
    <Player>
      <img
        slot="avatar"
        src="/images/opponent.jpg"
        alt="opponent"
        height={100}
        width={100}
      />
      <span slot="name"> {opponentName} </span>
      <span slot="level"> 99 </span>
      <span slot="win"> 999 </span>
      <span slot="lose"> Never </span>
      <span slot="rank"> 1 </span>
    </Player>
  </div>
  <div class="messageBox">
    <MessageBoard bind:this={messageBoard} />
  </div>
  <div class="box">
    <Hand>
      <span> Player </span>
      {#each playerDuck as wantCard, i}
        <Card
          on:click={focus}
          canPan={isPlayable && !oPlayerDucks[i].vague}
          {panEndHandler}
          {wantCard}
          index={i}
          vague={oPlayerDucks[i].vague}
          picked={oPlayerDucks[i].picked}
          offset={50}
        />
      {/each}
    </Hand>
    <ControlPanel
      on:play={onPlay}
      on:next={onNextGame}
      on:restart={onRestart}
      enablePlay={isPlayable && playButton}
      enableNext={false}
      enableRestart={canRestart}
    />
    <Hand>
      <span> Opponent </span>
      {#each opponentDuck as wantCard, i}
        <Card
          {wantCard}
          index={i}
          vague={oOpponentDucks[i].vague}
          picked={oOpponentDucks[i].picked}
          offset={50}
        />
      {/each}
    </Hand>
  </div>
  <footer />
</div>
<div class="hidden" bind:this={oHidden} />
<RulePicker onPick={onRulePick} on:choose={onChooseRulePick} />
<TablePicker
  onPick={onTablePick}
  on:create={onCreateTable}
  on:join={onJoinTable}
/>
<CardPool
  remark={playerPickRule ? "Note: you can pick the rule for next set" : ""}
  cards={cardPool}
  onPick={onCardPoolPick}
  on:confirm={onCardPoolConfirm}
/>

<style>
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
    display: none;
    z-index: 999;
  }
  .box {
    display: flex;
    justify-content: center;
    /* height: 46vh; */
    width: 100vw;
  }
  .messageBox {
    display: flex;
    height: 13vh;
  }
  header,
  footer {
    flex: 1;
  }
</style>
