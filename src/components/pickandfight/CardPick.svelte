<script>
  import Card from "./Card.svelte";
  import { afterUpdate, createEventDispatcher } from "svelte";

  export let cards;
  export let onPick = false;
  export let pickNum;

  $: canConfirm = pickedCards.length == pickNum;

  let pickedCards = [];
  let oCardPicker;

  // event
  const dispatch = createEventDispatcher();
  let oCards = [];
  let cardsInterval = [
    195, 195, 195, 195, 195, 195, 195, 195, 180, 160, 144, 130, 118, 108, 100,
    94, 90,
  ];

  function onClickCard(event) {
    let card = event.detail.card;
    let index = event.detail.index;
    let picked = card.picked;
    if (picked) {
      if (pickedCards.length >= pickNum) {
        card.picked = false;
        alert(`You can only pick ${pickNum} cards!`);
        return;
      }
      pickedCards.push(index);
    } else {
      for (let i = 0; i < pickedCards.length; i++) {
        if (pickedCards[i] === index) {
          pickedCards.splice(i, 1);
          break;
        }
      }
    }
    canConfirm = onPick && pickedCards.length == pickNum;
  }

  function onConfirm() {
    dispatch("confirm", { pickedCards });
    pickedCards = [];
  }

  afterUpdate(() => {
    if (onPick) {
      oCardPicker.style.display = "flex";
    } else {
      oCardPicker.style.display = "none";
    }
    let cardsLength = cards.length;
    let interval =
      cardsLength < 18
        ? cardsInterval[cardsLength - 1]
        : 90 - (cardsLength - 17) * 4;
    for (let i = 0; i < cardsLength; i++) {
      oCards[i].style.left = `${i * interval}px`;
      oCards[i].style.zIndex = i;
    }
  });
</script>

<div class="cardPicker" bind:this={oCardPicker}>
  <div style="height: 5%;" />
  <div class="card_box">
    {#each cards as card, i}
      <div class="card_case" bind:this={oCards[i]}>
        <Card
          id={card.id}
          index={card.index}
          canPan={false}
          canPick={true}
          on:click={onClickCard}
        />
      </div>
    {/each}
  </div>
  <button class="confirm" disabled={!canConfirm} on:click={onConfirm}
    >Confirm</button
  >
</div>

<style>
  .cardPicker {
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
  .card_box {
    display: flex;
    position: relative;
    flex-wrap: nowrap;
    justify-items: center;
    align-items: start;
    margin-top: 80px;
    width: 100%;
    height: 100%;
  }
  .card_case {
    position: absolute;
    width: 200px;
    height: 300px;
  }
  .confirm {
    position: absolute;
    bottom: 180px;
    right: 10px;
    width: 100px;
    height: 3rem;
    z-index: 998;
    font-weight: bold;
  }
</style>
