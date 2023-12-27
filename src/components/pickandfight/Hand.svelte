<script>
  import Card from "./Card.svelte";
  import { afterUpdate, createEventDispatcher } from "svelte";

  export let cards;
  export let canPan;
  export let canPick;
  export let onReforge;

  $: canConfirm = onReforge && pickedCards.length > 0;

  let pickedCards = [];
  $: qualityToReforge = Math.min(
    3,
    Math.floor(
      pickedCards.reduce((acc, cur) => {
        return acc + cur.quality;
      }, 0) / 2
    )
  );

  // event
  const dispatch = createEventDispatcher();
  let oCards = [];
  let cardsInterval = [
    195, 195, 195, 195, 195, 195, 195, 195, 180, 160, 144, 130, 118, 108, 100,
    94, 90,
  ];

  function play(event, card, i) {
    // console.log(card);
  }

  function onClickCard(event) {
    if (!onReforge) return;
    let card = event.detail.card;
    let index = event.detail.index;
    let picked = card.picked;
    if (picked) {
      pickedCards = [...pickedCards, { index: index, quality: card.quality }];
    } else {
      for (let i = 0; i < pickedCards.length; i++) {
        if (pickedCards[i].index === index) {
          pickedCards.splice(i, 1);
          pickedCards = pickedCards;
          break;
        }
      }
    }
    canConfirm = onReforge && pickedCards.length > 0;
  }

  function onConfirm() {
    dispatch("confirm", { pickedCards });
    pickedCards = [];
  }

  function onCancel() {
    dispatch("cancel");
    pickedCards = [];
  }

  function setSequenceHolder(handIndex, index, card) {
    dispatch("setSequenceHolder", { handIndex, index, card });
  }

  function handlePanStart(x, y) {}

  function handlePanEnd(card, i, x, y) {
    if (y > 225 && y < 540) {
      // 40 240
      if (x > 30 && x < 250) {
        setSequenceHolder(i, 0, card);
      } // 270 470
      else if (x > 260 && x < 480) {
        setSequenceHolder(i, 1, card);
      } // 500 700
      else if (x > 490 && x < 710) {
        setSequenceHolder(i, 2, card);
      } // 730 930
      else if (x > 720 && x < 940) {
        setSequenceHolder(i, 3, card);
      } // 960 1160
      else if (x > 950 && x < 1170) {
        setSequenceHolder(i, 4, card);
      } // 1190 1390
      else if (x > 1180 && x < 1400) {
        setSequenceHolder(i, 5, card);
      } // 1420 1620
      else if (x > 1410 && x < 1630) {
        setSequenceHolder(i, 6, card);
      }
    }
    return [-1, -1];
  }

  afterUpdate(() => {
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

<div class="card_box">
  {#each cards as card, i}
    <div
      class="card_case"
      bind:this={oCards[i]}
      on:click={(e) => play(e, card, i)}
    >
      <Card
        id={card.id}
        index={card.index}
        {canPan}
        {canPick}
        on:click={onClickCard}
        panStartHandler={handlePanStart}
        panEndHandler={(_, x, y) => handlePanEnd(card, i, x, y)}
      />
    </div>
  {/each}
</div>
<div class="reforge-quality">
  Reforge Quality:
  {qualityToReforge == 0
    ? "None"
    : qualityToReforge == 1
      ? "Low"
      : qualityToReforge == 2
        ? "Middle"
        : "High"}
</div>
<button class="reforge-confirm" disabled={!canConfirm} on:click={onConfirm}
  >Confirm</button
>
<button class="reforge-cancel" disabled={!onReforge} on:click={onCancel}
  >Cancel</button
>

<style>
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
  .reforge-quality {
    position: absolute;
    bottom: 290px;
    right: 10px;
    width: 80px;
    z-index: 998;
    font-weight: bold;
  }
  .reforge-confirm {
    position: absolute;
    bottom: 210px;
    right: 10px;
    width: 100px;
    height: 3rem;
    z-index: 998;
    font-weight: bold;
  }
  .reforge-cancel {
    position: absolute;
    bottom: 130px;
    right: 10px;
    width: 100px;
    height: 3rem;
    z-index: 998;
    font-weight: bold;
  }
</style>
