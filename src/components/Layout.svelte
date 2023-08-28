<script>
  import Player from "./Player.svelte";
  import Hand from "./Hand.svelte";
  import BattleBoard from "./BattleBoard.svelte";
  import WinballBoard from "./WinballBoard.svelte";
  import Card, {
    getRndomDuck,
    getRndomCardFromDuck,
    clearCardPlayFlag,
    bgPooker,
  } from "./Card.svelte";
  import ControlPanel from "./ControlPanel.svelte";
  import MessageBoard from "./MessageBoard.svelte";
  import { onMount } from "svelte";
  import RuleBoard from "./RuleBoard.svelte";
  import RulePicker, { buildRuleDesc } from "./RulePicker.svelte";
  let playerHand, AIHand;
  let playerDuckData;
  let AIDuckData;
  let playerDuck = [],
    AIDuck = [];
  let oPlayerDucks = [],
    oAIDucks = [];
  let playerBattleCard, AIBattleCard;
  let playerWinballBoard, AIWinballBoard;
  let playerBalls = [];
  let AIBalls = [];
  let roundCount;
  let playerPoint, AIPoint;
  let roleToPickRule;
  let playButton;
  let focusCard, focusIndex;
  let messageBoard;
  let canNext;
  let ruleMode = {};
  let oHidden;
  let onRulePick;

  onMount(() => {
    setTimeout(() => {
      init();
    }, 100);
  });

  function init() {
    playerBalls = [
      { id: "0", win: false },
      { id: "1", win: false },
    ];
    AIBalls = [
      { id: "0", win: false },
      { id: "1", win: false },
    ];
    // AI picks the rule at first
    roleToPickRule = 1;
    initMessageBoard();
    nextGame();
  }

  function nextGame() {
    clearCardPlayFlag();
    playButton = false;
    canNext = false;
    playerBattleCard = undefined;
    AIBattleCard = undefined;
    roundCount = 0;
    playerPoint = 0;
    AIPoint = 0;
    oPlayerDucks = [
      { picked: false, vague: false },
      { picked: false, vague: false },
      { picked: false, vague: false },
      { picked: false, vague: false },
      { picked: false, vague: false },
    ];
    oAIDucks = [
      { vague: false },
      { vague: false },
      { vague: false },
      { vague: false },
      { vague: false },
    ];
    // actually player and AI can't chooose the same card
    playerDuckData = getRndomDuck(5, 2);
    AIDuckData = getRndomDuck(5, 2);
    clearCardPlayFlag();
    playerDuck = playerDuckData.slice(0);
    AIDuck = [bgPooker, bgPooker, AIDuckData[2], AIDuckData[3], AIDuckData[4]];

    // the one who loses last game will pick the rule
    if (roleToPickRule === 1) {
      AIRollRuleMode();
    } else {
      startRulePick();
    }

    // another solution:
    // if AI falls behind, AI roll the rule in next game
    // if (AIWinballBoard.winPoint() <= playerWinballBoard.winPoint()) {
    //   AIRollRuleMode();
    // } else {
    //   startRulePick();
    // }
  }

  function handleRulePick(event) {
    let mode = event.detail.mode;
    ruleMode = buildRuleMode(0, mode);
    newMessage("The Player picks rule " + buildRuleDesc(mode));
    oHidden.style.display = "none";
    onRulePick = false;
  }

  function startRulePick() {
    oHidden.style.display = "block";
    onRulePick = true;
  }

  function initMessageBoard() {
    messageBoard.initMessages(
      ["Welcome! The AI wants to have a card battle! ", "Best of three!"].map(
        messageBoard.createMessage
      )
    );
  }

  function focus(event) {
    let playerCard = event.detail.wantCard;
    let index = event.detail.index;
    foucsOnCardFromHand(playerCard, index);
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
      restoreControlPanel();
    } else {
      setControlPanel(playerCard, index);
    }
  }

  function play() {
    focusCard.chosen = true;
    // draw a card from AI duck
    let [AICard, AICardIndex] = getRndomCardFromDuck(AIDuckData);
    // render
    // put in battleboard
    playerBattleCard = focusCard;
    AIBattleCard = AICard;
    // show hide cards
    if (AICardIndex < 2) {
      AIDuck[AICardIndex] = AIDuckData[AICardIndex];
    }
    // change opacity in both hand
    oPlayerDucks[focusIndex].vague = true;
    oAIDucks[AICardIndex].vague = true;
    // compare and show result, change point
    let res;
    // this score rule are decided by ruleMode
    if (ruleMode.mode === 1) {
      if (focusCard.type === AICard.type) {
        res = focusCard.points - AICard.points;
      } else {
        res = AICard.points - focusCard.points;
      }
    } else {
      if (focusCard.type === AICard.type) {
        res = AICard.points - focusCard.points;
      } else {
        res = focusCard.points - AICard.points;
      }
    }

    // when draw, the one who decided the rule wins and gets 1 point
    if (res > 0) {
      playerPoint += res;
      newMessage("Player won this round! (points: " + res + ")");
    } else if (res < 0) {
      AIPoint -= res;
      newMessage("AI won this round! (points: " + -res + ")");
    } else {
      let role = ruleMode.role;
      if (role === 0) {
        playerPoint++;
      } else if (role === 1) {
        AIPoint++;
      }
      newMessage(
        "Wow draw round! The one who picks the rule will get 1 point!"
      );
    }
    roundCount++;
    unpickDuck(oPlayerDucks);
    restoreControlPanel();
    checkGame();
  }

  function checkGame() {
    if (roundCount === 5) {
      if (playerPoint > AIPoint) {
        roleToPickRule = 1;
        if (playerBalls[0].win) {
          playerBalls[1].win = true;
          newMessage("Player won! Thanks for playing! " + printGameScores());
        } else {
          playerBalls[0].win = true;
          newMessage("Player won the game! " + printGameScores());
          canNext = true;
        }
      } else if (playerPoint < AIPoint) {
        roleToPickRule = 0;
        if (AIBalls[0].win) {
          AIBalls[1].win = true;
          newMessage("AI won! Thanks for playing! " + printGameScores());
        } else {
          AIBalls[0].win = true;
          newMessage("AI won the game! " + printGameScores());
          canNext = true;
        }
      } else {
        roleToPickRule = 1;
        newMessage(
          "Draw this round! Let's continue! AI will pick the rule!" +
            printGameScores()
        );
        canNext = true;
      }
    }
  }

  function onNextGame() {
    nextGame();
  }

  function onRestart() {
    init();
  }

  function unpickDuck(oPlayerDucks) {
    for (let ocard of oPlayerDucks) {
      ocard.picked = false;
    }
  }

  function restoreControlPanel() {
    playButton = false;
    focusCard = undefined;
    focusIndex = -1;
  }

  function setControlPanel(_focusCard, _focusIndex) {
    playButton = true;
    focusCard = _focusCard;
    focusIndex = _focusIndex;
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

  function printGameScores() {
    return (
      "(" +
      playerWinballBoard.printScore() +
      ":" +
      AIWinballBoard.printScore() +
      ")"
    );
  }

  function AIRollRuleMode() {
    let mode = Math.ceil(Math.random() * 2);
    ruleMode = buildRuleMode(1, mode);
    newMessage("The AI picks " + buildRuleDesc(mode));
  }

  // role: 0-player 1-AI
  function buildRuleMode(_role, _mode) {
    return { role: _role, mode: _mode };
  }

  let panEndHandler = function (wantCard, index, x, y) {
    // decide if this is a valid pan
    // if (x > 300 && x < 550 && y > 100 && y < 300) {
    if (y > 100 && y < 300) {
      // decide if player had focused on another card then dragged this one
      if (getPickedFromDuck(oPlayerDucks) != index) {
        foucsOnCardFromHand(wantCard, index);
      }
      // take this as play that card
      play();
    }
    return [-1, -1];
  };
</script>

<div class="bg">
  <header />
  <div class="box">
    <Player>
      <img
        slot="avatar"
        src="/images/player.jpg"
        alt="player"
        height="100"
        width="100"
      />
      <span slot="name"> Card Beginner </span>
      <span slot="level"> 1 </span>
      <span slot="win"> 0 </span>
      <span slot="lose"> 0 </span>
      <span slot="cards"> 5 </span>
    </Player>
    <WinballBoard balls={playerBalls} bind:this={playerWinballBoard} />
    <BattleBoard points={playerPoint} battlecard={playerBattleCard} />
    <RuleBoard class="ruleBoard">
      <span slot="mode"> {ruleMode.mode} </span>
      <span slot="role"> {ruleMode.role === 0 ? "Player" : "AI"} </span>
    </RuleBoard>
    <BattleBoard points={AIPoint} battlecard={AIBattleCard} />
    <WinballBoard balls={AIBalls} bind:this={AIWinballBoard} />
    <Player>
      <img
        slot="avatar"
        src="/images/AI.jpg"
        alt="AI"
        height="100"
        width="100"
      />
      <span slot="name"> Card Sensei </span>
      <span slot="level"> 99 </span>
      <span slot="win"> 999 </span>
      <span slot="lose"> Never </span>
      <span slot="cards"> Infinite </span>
    </Player>
  </div>
  <div class="messageBox">
    <MessageBoard bind:this={messageBoard} />
  </div>
  <div class="box">
    <Hand bind:this={playerHand}>
      <span> Player </span>
      {#each playerDuck as wantCard, i}
        <Card
          on:click={focus}
          canPan="true"
          {panEndHandler}
          {wantCard}
          index={i}
          vague={oPlayerDucks[i].vague}
          picked={oPlayerDucks[i].picked}
        />
      {/each}
    </Hand>
    <ControlPanel
      on:play={play}
      on:next={onNextGame}
      on:restart={onRestart}
      enablePlay={playButton}
      enableNext={canNext}
    />
    <Hand bind:this={AIHand}>
      <span> AI </span>
      {#each AIDuck as wantCard, i}
        <Card
          {wantCard}
          index={i}
          vague={oAIDucks[i].vague}
          picked={oAIDucks[i].picked}
        />
      {/each}
    </Hand>
  </div>
  <footer />
</div>
<div class="hidden" bind:this={oHidden} />
<RulePicker onPick={onRulePick} on:choose={handleRulePick} />

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
    height: 10vh;
    width: 100vw;
  }
  header,
  footer {
    flex: 1;
  }
</style>
