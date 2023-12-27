<script>
  import { createEventDispatcher } from "svelte";
  import { afterUpdate } from "svelte";
  import Card from "./Card.svelte";

  export let onPick = false;
  export let ids = [];
  export let pickNum = 3;

  let pickedCards = [];

  let oCardPoolPicker;
  let oCardCase = [];

  // event
  const dispatch = createEventDispatcher();

  afterUpdate(() => {
    if (onPick) {
      oCardPoolPicker.style.display = "flex";
    } else {
      oCardPoolPicker.style.display = "none";
    }
    for (let i = 0; i < oCardCase.length; i++) {
      oCardCase[i].style.left = `${(i % 10) * 180}px`;
      oCardCase[i].style.zIndex = i % 10;
    }
  });

  function onClickCard(event) {
    let card = event.detail.card;
    let picked = card.picked;
    if (picked) {
      if (pickedCards.length == pickNum) {
        card.picked = false;
        alert(`You can only pick ${pickNum} cards!`);
        return;
      }
      pickedCards.push(card.id);
    } else {
      for (let i = 0; i < pickedCards.length; i++) {
        if (pickedCards[i] === card.id) {
          pickedCards.splice(i, 1);
          break;
        }
      }
    }
  }

  function confirm(event) {
    if (pickedCards.length != pickNum) {
      alert(`You should pick ${pickNum} cards!`);
      return;
    }
    dispatch("confirm", { pickedCards });
    pickedCards = [];
  }
</script>

<div class="cardPoolPicker" bind:this={oCardPoolPicker}>
  <div style="height: 5%;" />
  <div class="panel">
    <p class="title">Note: You can pick {pickNum} cards for this round.</p>
    <button class="cardPoolButton" on:click={confirm}>Confirm</button>
  </div>

  {#each [...Array(2).keys()] as j}
    <div class="cardSet">
      {#each ids.slice(10 * j, 10 * (j + 1)) as id, i}
        <div class="cardCase" bind:this={oCardCase[10 * j + i]}>
          <Card
            id={parseInt(id)}
            canPick={true}
            canPan={false}
            on:click={onClickCard}
          />
        </div>
      {/each}
    </div>
  {/each}
  <div style="height: 10%;" />
</div>

<style>
  .panel {
    display: flex;
    flex-direction: row;
  }
  .title {
    font-size: 1.5em;
    font-weight: bold;
  }
  .cardSet {
    position: relative;
    display: flex;
    width: 100%;
    height: 300px;
    margin-left: 30px;
    margin-right: 30px;
    z-index: -1000;
    user-select: none;
    pointer-events: none;
  }
  .cardCase {
    position: absolute;
  }
  .cardPoolPicker {
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    margin: auto;
    color: #fff;
    width: 100%;
    height: 97%;
    display: flex;
    background-color: #40527e;
    flex-direction: column;
    justify-content: space-between;
    align-items: center;
    border-radius: 10px;
    box-sizing: border-box;
    z-index: 1002;
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
