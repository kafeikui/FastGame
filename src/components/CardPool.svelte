<script>
  import { createEventDispatcher } from "svelte";
  import { afterUpdate } from "svelte";
  import Card, { bgPooker } from "./Card.svelte";

  export let onPick = false;
  export let cards = [];
  export let remark = "";

  let oCardPoolPicker;
  let duckHolder = [bgPooker, bgPooker, bgPooker, bgPooker, bgPooker];
  let duckHolderProps = [
    { cardIndex: undefined, vague: true },
    { cardIndex: undefined, vague: true },
    { cardIndex: undefined, vague: false },
    { cardIndex: undefined, vague: false },
    { cardIndex: undefined, vague: false },
  ];
  let cardsProps = Array.from(Array(20), (item, index) => ({
    picked: false,
    vague: false,
  }));
  let focusingCard, focusingIndex;

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
    if (y > 80 && y < 200) {
      // x: 457 y: 127
      // x: 598 y: 137
      // x: 756 y: 118
      // x: 915 y: 124
      // x: 1060 y: 119
      if (x > 400 && x < 544) {
        // 1
        setDuckHolder(0, wantCard, index);
      } else if (x > 544 && x < 688) {
        // 2
        setDuckHolder(1, wantCard, index);
      } else if (x > 688 && x < 832) {
        // 3
        setDuckHolder(2, wantCard, index);
      } else if (x > 832 && x < 976) {
        // 4
        setDuckHolder(3, wantCard, index);
      } else if (x > 976 && x < 1120) {
        // 5
        setDuckHolder(4, wantCard, index);
      }
    }
    return [-1, -1];
  };

  function onClickDuckHolder(event) {
    if (focusingIndex !== undefined) {
      let holderIndex = event.detail.index;
      setDuckHolder(holderIndex, focusingCard, focusingIndex);
    } else {
      alert("Please select a card first or drag a card to a holder");
    }
  }

  function setDuckHolder(holderIndex, card, cardIndex) {
    if (duckHolderProps[holderIndex].cardIndex !== undefined) {
      cardsProps[duckHolderProps[holderIndex].cardIndex].vague = false;
    }
    duckHolderProps[holderIndex].cardIndex = cardIndex;
    cardsProps[cardIndex].vague = true;
    duckHolder[holderIndex] = card;
    clearFocusCard();
    unpickDuck();
  }

  function onClickCard(event) {
    // handle and render picked
    let playerCard = event.detail.wantCard;
    let index = event.detail.index;
    cardsProps[index].picked = true;
    if (focusingIndex > -1) {
      cardsProps[focusingIndex].picked = false;
    }
    if (focusingIndex === index) {
      clearFocusCard();
    } else {
      setFocusCard(playerCard, index);
    }
  }

  function setFocusCard(_focusCard, _focusIndex) {
    focusingCard = _focusCard;
    focusingIndex = _focusIndex;
  }

  function clearFocusCard() {
    focusingCard = undefined;
    focusingIndex = undefined;
  }

  function unpickDuck() {
    for (let card of cardsProps) {
      card.picked = false;
    }
  }

  function initCardPoolProps() {
    duckHolder = [bgPooker, bgPooker, bgPooker, bgPooker, bgPooker];
    duckHolderProps = [
      { cardIndex: undefined, vague: true },
      { cardIndex: undefined, vague: true },
      { cardIndex: undefined, vague: false },
      { cardIndex: undefined, vague: false },
      { cardIndex: undefined, vague: false },
    ];
    cardsProps = Array.from(Array(20), (item, index) => ({
      picked: false,
      vague: false,
    }));
    focusingCard = undefined;
    focusingIndex = undefined;
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

    initCardPoolProps();
  }
</script>

<div class="cardPoolPicker" bind:this={oCardPoolPicker}>
  <div class="hand">
    {#each duckHolder as wantCard, i}
      <Card
        on:click={onClickDuckHolder}
        canPan={false}
        {panEndHandler}
        {wantCard}
        index={i}
        spacing={150}
        vague={duckHolderProps[i].vague}
        picked={false}
        forbidClickIfVague={false}
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
  {#each [...Array(4).keys()] as j}
    <div class="cardSet">
      {#each cards.slice(5 * j, 5 * (j + 1)) as wantCard, i}
        <Card
          on:click={onClickCard}
          canPan={!cardsProps[5 * j + i].vague}
          {panEndHandler}
          {wantCard}
          index={5 * j + i}
          spacing={175}
          offset={-5 * j * 175}
          vague={cardsProps[5 * j + i].vague}
          picked={cardsProps[5 * j + i].picked}
        />
      {/each}
    </div>
  {/each}

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
