<script>
  import { onMount, createEventDispatcher } from "svelte";
  import Actor from "./Actor.svelte";
  import BuffBoard from "./BuffBoard.svelte";
  import StateBoard from "./StateBoard.svelte";
  import PropertyBoard from "./PropertyBoard.svelte";
  import CardColumn from "./CardColumn.svelte";
  import AudioVolumn from "./AudioVolumn.svelte";
  import {
    PlayerState,
    IdentityType,
    fight,
    setCallback,
    applyBuff,
  } from "../../utils/game_fight";
  import { broadcastSe, SE, muteAll, unmuteAll } from "../../utils/se";

  const dispatch = createEventDispatcher();

  export let self = PlayerState.placeholder();
  export let enemy = PlayerState.placeholder();
  export let selfSequence = [];
  export let enemySequence = [];
  export let selfFirst;
  export let randomness;
  export let outcome = "waiting...";
  export let round = 0;

  let selfForInit;
  let enemyForInit;
  let resetFight;

  let isFighting;
  let fightAborted;
  let roundPause;
  let postDamagePause;
  let musicTimer;
  let isMuted = false;

  let oReset;
  let oAudio;
  let oSkip;
  let oQuick;
  let oNormal;
  let oSelfMsgBox;
  let oEnemyMsgBox;

  const fightAbortedError = new DOMException(
    "Fight aborted by user",
    "AbortError"
  );

  // function prepareFight() {
  //     self = new PlayerState(
  //       IdentityType.Self,
  //       0,
  //       12000,
  //       12000,
  //       600,
  //       100,
  //       10,
  //       10,
  //       200,
  //       100,
  //       100,
  //       Actionable.Normal,
  //       0,
  //       []
  //     );
  //     enemy = new PlayerState(
  //       IdentityType.Enemy,
  //       0,
  //       12000,
  //       12000,
  //       600,
  //       100,
  //       10,
  //       10,
  //       200,
  //       100,
  //       100,
  //       Actionable.Normal,
  //       0,
  //       []
  //     );
  //     // they are all of defense and heal sect cards of highest level which will result in a long fight
  //     selfSequence = (function () {
  //       let sequence = [];
  //       sequence[0] = 22 + 2 * (MAX_CARD_ID + 1);
  //       sequence[1] = 24 + 2 * (MAX_CARD_ID + 1);
  //       sequence[2] = 22 + 2 * (MAX_CARD_ID + 1);
  //       sequence[3] = 24 + 2 * (MAX_CARD_ID + 1);
  //       sequence[4] = 27 + 2 * (MAX_CARD_ID + 1);
  //       sequence[5] = 16 + 2 * (MAX_CARD_ID + 1);
  //       sequence[6] = 15 + 2 * (MAX_CARD_ID + 1);
  //       return sequence;
  //     })();

  //     enemySequence = (function () {
  //       let sequence = [];
  //       sequence[0] = 22 + 2 * (MAX_CARD_ID + 1);
  //       sequence[1] = 24 + 2 * (MAX_CARD_ID + 1);
  //       sequence[2] = 27 + 2 * (MAX_CARD_ID + 1);
  //       sequence[3] = 16 + 2 * (MAX_CARD_ID + 1);
  //       sequence[4] = 15 + 2 * (MAX_CARD_ID + 1);
  //       sequence[5] = 13 + 2 * (MAX_CARD_ID + 1);
  //       sequence[6] = 10 + 2 * (MAX_CARD_ID + 1);
  //       return sequence;
  //     })();
  //     selfFirst = true;
  //     randomness = web3.utils.toBN(web3.utils.soliditySha3(42));
  //   }

  onMount(() => {
    setNormalRoundPause();
  });

  $: selfBuffs = self.buffs.filter((buff) => buff.duration > 0);
  $: enemyBuffs = enemy.buffs.filter((buff) => buff.duration > 0);

  $: buffedSelf = applyBuff(self, false);
  $: buffedEnemy = applyBuff(enemy, false);

  function sleep(time) {
    return new Promise((resolve) => setTimeout(resolve, time));
  }

  async function play() {
    isFighting = true;
    try {
      setTimeout(() => {
        oSkip.disabled = false;
      }, 5000);

      let selfWin = await fight(
        self,
        enemy,
        selfSequence,
        enemySequence,
        selfFirst,
        randomness
      );
      let clientOutcome = selfWin ? "win" : "lose";
      if (clientOutcome != outcome) {
        console.log("client outcome: ", clientOutcome);
      }
      if (oSkip.disabled) {
        oSkip.disabled = false;
      }
    } catch (e) {
      if (e === fightAbortedError) {
        console.log("fight aborted");
      } else {
        throw e;
      }
    } finally {
      isFighting = false;
    }
  }

  function setNormalRoundPause() {
    broadcastSe(SE.Click);
    oNormal.disabled = true;
    oQuick.disabled = false;
    roundPause = 800;
    postDamagePause = 1500;
  }

  function setQuickRoundPause() {
    broadcastSe(SE.Click);
    oQuick.disabled = true;
    oNormal.disabled = false;
    roundPause = 500;
    postDamagePause = 500;
  }

  function skip() {
    broadcastSe(SE.Click);
    selfForInit = undefined;
    oSelfMsgBox.innerHTML = "";
    oEnemyMsgBox.innerHTML = "";
    selfSequence = [];
    enemySequence = [];
    round = 0;
    oSkip.disabled = true;
    oAudio.pause();
    if (isFighting) {
      fightAborted = true;
    }
    dispatch("skip", {});
  }

  async function reset() {
    broadcastSe(SE.Click);
    if (selfForInit == undefined) {
      //deep copy
      selfForInit = JSON.parse(JSON.stringify(self));
      enemyForInit = JSON.parse(JSON.stringify(enemy));
      resetFight = () => {
        self = JSON.parse(JSON.stringify(selfForInit));
        enemy = JSON.parse(JSON.stringify(enemyForInit));
        round = 0;
      };
    }
    oSelfMsgBox.innerHTML = "";
    oEnemyMsgBox.innerHTML = "";
    oReset.disabled = true;

    playMusic();

    let intervalBeforeFight = 500;
    if (isFighting) {
      fightAborted = true;
      intervalBeforeFight = 3000;
    }
    setTimeout(async () => {
      oReset.disabled = false;
      resetFight();
      prepareCallback();
      setTimeout(async () => {
        await play();
      }, 1000);
    }, intervalBeforeFight);
  }

  export const DamageResult = {
    Dodge: 0,
    Normal: 1,
    Crit: 2,
    Absorb: 3,
  };

  function playMusic() {
    if (isMuted) {
      return;
    }
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

  function parseDamageResult(result) {
    switch (result) {
      case DamageResult.Dodge:
        return "dodge!";
      case DamageResult.Normal:
        return "";
      case DamageResult.Crit:
        return "crit!";
      case DamageResult.Absorb:
        return "absorb!";
      default:
        return "unknown";
    }
  }

  function prepareCallback() {
    let applyPassiveCardCallback = (state) => {
      checkFightAborted();
      if (state.identityType == IdentityType.Self) {
        self = state;
      } else {
        enemy = state;
      }
      checkFightAborted();
    };
    let triggerRoundBuffCallback = async (state, _round) => {
      checkFightAborted();
      round = _round;
      if (state.identityType == IdentityType.Self) {
        self = state;
      } else {
        enemy = state;
      }
      checkFightAborted();
    };
    let handleRoundBuffCallback = async (state, buffName, value, isHeal) => {
      checkFightAborted();
      broadcastSe(SE.Hit);
      if (state.identityType == IdentityType.Self) {
        self = state;
        oSelfMsgBox.innerHTML = `Buff: ${buffName} health${
          isHeal ? "+" : "-"
        }${value}`;
      } else {
        enemy = state;
        oEnemyMsgBox.innerHTML = `Buff: ${buffName} health${
          isHeal ? "+" : "-"
        }${value}`;
      }
      await sleep(postDamagePause);
      checkFightAborted();
    };
    let applyBuffCallback = (state) => {
      checkFightAborted();
      if (state.identityType == IdentityType.Self) {
        self = state;
      } else {
        enemy = state;
      }
      checkFightAborted();
    };
    let applyTimedBuffCallback = (state) => {
      checkFightAborted();
      if (state.identityType == IdentityType.Self) {
        self = state;
      } else {
        enemy = state;
      }
      checkFightAborted();
    };
    let handleDamageCallback = async (
      cardName,
      state,
      damageResult,
      damage
    ) => {
      checkFightAborted();
      // broadcast hit or punch on random
      let se = Math.floor(Math.random() * 2);
      if (se == 0) {
        broadcastSe(SE.Pa);
      } else {
        broadcastSe(SE.Punch);
      }
      if (state.identityType == IdentityType.Self) {
        self = state;
        oSelfMsgBox.innerHTML = `${cardName} ${parseDamageResult(
          damageResult
        )} health-${damage}`;
      } else {
        enemy = state;
        oEnemyMsgBox.innerHTML = `${cardName} ${parseDamageResult(
          damageResult
        )} health-${damage}`;
      }
      await sleep(postDamagePause);
      checkFightAborted();
    };
    let preCastCardCallback = async (sequenceIndex, attacker, defender) => {
      checkFightAborted();
      if (attacker.identityType == IdentityType.Self) {
        self = attacker;
        enemy = defender;
        window.dispatchEvent(
          new CustomEvent("playCard", {
            detail: {
              sequenceIndex: sequenceIndex,
              isEnemy: false,
            },
          })
        );
      } else {
        self = defender;
        enemy = attacker;
        window.dispatchEvent(
          new CustomEvent("playCard", {
            detail: {
              sequenceIndex: sequenceIndex,
              isEnemy: true,
            },
          })
        );
      }
      await sleep(roundPause);
      checkFightAborted();
    };
    let postCastCardCallback = async (sequenceIndex, attacker, defender) => {
      checkFightAborted();
      if (attacker.identityType == IdentityType.Self) {
        self = attacker;
        enemy = defender;
        window.dispatchEvent(
          new CustomEvent("retractCard", {
            detail: {
              sequenceIndex: sequenceIndex,
              isEnemy: false,
            },
          })
        );
      } else {
        self = defender;
        enemy = attacker;
        window.dispatchEvent(
          new CustomEvent("retractCard", {
            detail: {
              sequenceIndex: sequenceIndex,
              isEnemy: true,
            },
          })
        );
      }
      await sleep(roundPause);
      checkFightAborted();
    };
    let addBuffCallback = async (state, buff) => {
      checkFightAborted();
      if (buff.positive) {
        broadcastSe(SE.Buff);
      } else {
        broadcastSe(SE.Debuff);
      }
      if (state.identityType == IdentityType.Self) {
        self = state;
      } else {
        enemy = state;
      }
      await sleep(postDamagePause);
      checkFightAborted();
    };

    setCallback(
      applyPassiveCardCallback,
      triggerRoundBuffCallback,
      handleRoundBuffCallback,
      applyBuffCallback,
      applyTimedBuffCallback,
      handleDamageCallback,
      preCastCardCallback,
      postCastCardCallback,
      addBuffCallback
    );
  }

  function checkFightAborted() {
    if (fightAborted) {
      fightAborted = false;
      throw fightAbortedError;
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
</script>

<body>
  <div class="bg">
    <div class="state-bar">
      <div class="state-bar-self">
        <div class="property-box">
          <PropertyBoard playerState={buffedSelf} />
        </div>
        <div>
          <div class="msgBox" bind:this={oSelfMsgBox}></div>
          <StateBoard maxHp={self.maxHealth} hp={self.health} />
          <div class="buff_box">
            <BuffBoard buffs={selfBuffs} />
          </div>
        </div>
      </div>
      <div class="game-bar">
        <span> {selfFirst ? "on the offensive" : "on the defensive"} </span>
        <span> Fight Outcome: {outcome} </span>
        <button disabled on:click={skip} bind:this={oSkip}> Skip </button>
        <div class="vs-bar">
          <div class="v"></div>
          <div class="s"></div>
        </div>
        <div>Round: {round + 1}</div>
        <div>
          <button on:click={reset} bind:this={oReset}> Start / Reset </button>
          <button disabled on:click={setNormalRoundPause} bind:this={oNormal}>
            Normal
          </button>
          <button on:click={setQuickRoundPause} bind:this={oQuick}>
            Quick
          </button>
        </div>
      </div>
      <div class="state-bar-enemy">
        <div>
          <div class="msgBox" bind:this={oEnemyMsgBox}></div>
          <StateBoard maxHp={enemy.maxHealth} hp={enemy.health} />
          <div class="buff_box">
            <BuffBoard buffs={enemyBuffs} />
          </div>
        </div>
        <div class="property-box">
          <PropertyBoard playerState={buffedEnemy} />
        </div>
      </div>
    </div>
    <div class="audio">
      <!-- svelte-ignore a11y-media-has-caption -->
      <audio controls loop src="./audios/bgm/fight.mp3" bind:this={oAudio} />
    </div>
    <div class="audioVolumnSwitch">
      <AudioVolumn {isMuted} on:switchVol={onSwitchAudioVolumn} />
    </div>
    <div class="actor-bar">
      <div class="actor-box">
        <Actor playerAvatar="/images/player.jpg" />
      </div>
      <div class="actor-box">
        <Actor playerAvatar="/images/opponent.jpg" />
      </div>
    </div>
    <div class="sequence-bar">
      <div class="sequence-box">
        <CardColumn cards={selfSequence} isEnemy={false} />
      </div>
      <div class="sequence-box">
        <CardColumn cards={enemySequence} isEnemy={true} />
      </div>
    </div>
  </div>
</body>

<style>
  body {
    width: 100vw;
    height: 100vh;
    overflow: hidden;
    background: url(/images/bg.jpg) no-repeat;
    background: linear-gradient(45deg, rgb(205, 200, 200), rgb(159, 176, 190))
      no-repeat;
  }
  .bg {
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    align-items: center;
    height: 100vh;
    /* background: url(/images/bg.jpg) no-repeat;
    background-size: cover; */
  }
  .state-bar {
    border-style: solid;
    border-top-style: none;
    display: flex;
    justify-content: space-between;
    align-items: center;
    width: 100%;
    height: 30vh;
  }
  .property-box {
    border-style: solid;
    display: flex;
    justify-content: space-between;
    align-items: center;
    width: 360px;
    height: 100%;
  }
  .msgBox {
    width: 360px;
    height: 50px;
    font-size: 24px;
    font-weight: bold;
  }
  .buff_box {
    display: flex;
    flex-direction: row;
    width: 360px;
    height: 100px;
  }
  .state-bar-self {
    border-style: solid;
    display: flex;
    justify-content: space-between;
    align-items: center;
    width: 40%;
    height: 100%;
  }
  .state-bar-enemy {
    border-style: solid;
    display: flex;
    justify-content: space-between;
    align-items: center;
    width: 40%;
    height: 100%;
  }
  .game-bar {
    display: flex;
    flex-direction: column;
    align-items: center;
  }
  .vs-bar {
    display: flex;
    flex-direction: row;
  }
  .v {
    width: 100px;
    height: 100px;
    background-image: url(/images/v.png);
  }
  .s {
    width: 100px;
    height: 100px;
    background-image: url(/images/s.png);
  }
  .actor-bar {
    border-style: solid;
    display: flex;
    justify-content: space-between;
    align-items: center;
    width: 100%;
    height: 26vh;
  }
  .actor-box {
    border-style: solid;
    display: flex;
    justify-content: center;
    align-items: center;
    width: 50%;
    height: 100%;
  }
  .sequence-bar {
    border-style: solid;
    border-top-style: none;
    display: flex;
    justify-content: space-between;
    align-items: center;
    width: 100%;
    height: 40vh;
  }
  .sequence-box {
    border-style: none;
    display: flex;
    align-items: center;
    margin-left: 30px;
    margin-right: 30px;
    margin-top: 30px;
    width: 50%;
    height: 100%;
  }
  .audio {
    display: none;
  }
  .audioVolumnSwitch {
    width: 50px;
    height: 50px;
  }
</style>
