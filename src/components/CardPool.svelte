<script>
  import { createEventDispatcher } from "svelte";
  import { afterUpdate } from "svelte";
  import Card, { bgPooker, getCardByCode } from "./Card.svelte";

  export let onPick = false;
  let oCardPoolPicker;
  let duckHolder = [bgPooker, bgPooker, bgPooker, bgPooker, bgPooker];
  let duckHolderVague = [true, true, false, false, false];
  export let cardColumns = [];
  export let remark = "";
  // // test: populate cardColumns by 0-20 code
  // for (let j = 0; j < 20; j++) {
  //   cardColumns.push(getCardByCode(j));
  // }

  // event
  const dispatch = createEventDispatcher();

  afterUpdate(() => {
    if (onPick) {
      oCardPoolPicker.style.display = "flex";
    } else {
      oCardPoolPicker.style.display = "none";
    }
  });

  let panEndHandler = function (wantCard, index, x, y) {
    console.log("x: " + x + " y: " + y);
    // decide if this is a valid pan
    if (y > 100 && y < 180) {
      // x: 457 y: 127
      // x: 598 y: 137
      // x: 756 y: 118
      // x: 915 y: 124
      // x: 1060 y: 119
      if (x > 300 && x < 520) {
        duckHolder[0] = wantCard;
      } else if (x > 520 && x < 700) {
        // 2
        duckHolder[1] = wantCard;
      } else if (x > 700 && x < 880) {
        // 3
        duckHolder[2] = wantCard;
      } else if (x > 880 && x < 1000) {
        // 4
        duckHolder[3] = wantCard;
      } else if (x > 1000 && x < 1200) {
        // 5
        duckHolder[4] = wantCard;
      }
    }
    return [-1, -1];
  };

  function focus(event) {
    // let playerCard = event.detail.wantCard;
    // let index = event.detail.index;
    // foucsOnCardFromHand(playerCard, index);
  }

  function confirm(event) {
    // checks hands should not contain any bgPooker
    if (duckHolder.includes(bgPooker)) {
      alert("Please select 5 cards");
      return;
    }
    // checks hands can not be repeated
    if (new Set(duckHolder).size !== duckHolder.length) {
      alert("Please select 5 different cards");
      return;
    }

    let confirmedHands = [...duckHolder];

    dispatch("confirm", {
      confirmedHands,
    });

    duckHolder = [bgPooker, bgPooker, bgPooker, bgPooker, bgPooker];
  }
</script>

<div class="cardPoolPicker" bind:this={oCardPoolPicker}>
  <div class="hand">
    {#each duckHolder as wantCard, i}
      <Card
        on:click={focus}
        canPan={false}
        {panEndHandler}
        {wantCard}
        index={3 * i}
        vague={duckHolderVague[i]}
        picked={false}
      />
    {/each}
  </div>
  <div class="panel">
    <p class="title">Select 5 cards as your hands:</p>
    <p class="title">(the first two cards will not show your opponent)</p>
    {#if remark != ""}
      <p class="title">{remark}</p>
    {/if}
    <button class="cardPoolButton" on:click={confirm}>Confirm</button>
  </div>

  <div style="height: 20%;" />

  <div class="cardSet">
    {#each cardColumns.slice(0, 5) as wantCard, i}
      <Card
        on:click={focus}
        canPan={!wantCard.chosen}
        {panEndHandler}
        {wantCard}
        index={3.5 * i}
        vague={wantCard.chosen}
        picked={false}
      />
    {/each}
  </div>
  <div class="cardSet">
    {#each cardColumns.slice(5, 10) as wantCard, i}
      <Card
        on:click={focus}
        canPan={!wantCard.chosen}
        {panEndHandler}
        {wantCard}
        index={3.5 * i}
        vague={wantCard.chosen}
        picked={false}
      />
    {/each}
  </div>
  <div class="cardSet">
    {#each cardColumns.slice(10, 15) as wantCard, i}
      <Card
        on:click={focus}
        canPan={!wantCard.chosen}
        {panEndHandler}
        {wantCard}
        index={3.5 * i}
        vague={wantCard.chosen}
        picked={false}
      />
    {/each}
  </div>
  <div class="cardSet">
    {#each cardColumns.slice(15, 20) as wantCard, i}
      <Card
        on:click={focus}
        canPan={!wantCard.chosen}
        {panEndHandler}
        {wantCard}
        index={3.5 * i}
        vague={wantCard.chosen}
        picked={false}
      />
    {/each}
  </div>
  <div style="height: 20%;" />
</div>

<style>
  .panel {
    position: absolute;
    right: 100px;
  }
  .title {
    font-size: 1.5em;
    /* margin-block-start: 0.83em;
    margin-block-end: 0.83em;
    margin-inline-start: 0px;
    margin-inline-end: 0px; */
    font-weight: bold;
  }
  .hand {
    width: 90%;
    height: 10%;
    padding: 1em;
    margin: 0 0 1em 0;
    top: 0;
    left: 200px;
    right: 0;
    bottom: 0;
    position: absolute;
  }
  .cardSet {
    width: 50%;
    height: 1px;
    padding: 1em;
    margin: 0 0 1em 0;
    position: relative;
    z-index: -1000;
    user-select: none;
    pointer-events: none;
  }
  .cardPoolPicker {
    color: #fff;
    width: 90%;
    height: 90%;
    display: flex;
    background-color: #40527e;
    flex-direction: column;
    justify-content: space-between;
    align-items: center;
    border-radius: 10px;
    padding-top: 50px;
    padding-bottom: 50px;
    box-sizing: border-box;
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    margin: auto;
    z-index: 1000;
  }
  .cardPoolButton {
    color: #fff;
    cursor: pointer;
    width: 160px;
    height: 50px;
    background-color: #02a0a0;
    margin: 1em;
    font-size: 1.2em;
    text-align: center;
    align-items: center;
  }

  .cardPoolButton:hover {
    background-color: #019191;
  }
</style>
