<script>
  import { createEventDispatcher } from "svelte";
  import Card from "./Card.svelte";

  export let availableSequence;
  export let sequence;
  export let canPan;

  let cardBoxes = [];
  // event
  const dispatch = createEventDispatcher();

  function swapSequenceHolder(fromIndex, toIndex, card) {
    dispatch("swapSequenceHolder", { fromIndex, toIndex, card });
  }

  function dragToHand(index, card) {
    dispatch("dragToHand", { index, card });
  }

  function handlePanStart(x, y) {}

  function handlePanEnd(card, i, x, y) {
    console.log(i, x, y);
    if (y > 225 && y < 540) {
      // 40 240
      if (x > 30 && x < 250) {
        swapSequenceHolder(i, 0, card);
      } // 270 470
      else if (x > 260 && x < 480) {
        swapSequenceHolder(i, 1, card);
      } // 500 700
      else if (x > 490 && x < 710) {
        swapSequenceHolder(i, 2, card);
      } // 730 930
      else if (x > 720 && x < 940) {
        swapSequenceHolder(i, 3, card);
      } // 960 1160
      else if (x > 950 && x < 1170) {
        swapSequenceHolder(i, 4, card);
      } // 1190 1390
      else if (x > 1180 && x < 1400) {
        swapSequenceHolder(i, 5, card);
      } // 1420 1620
      else if (x > 1410 && x < 1630) {
        swapSequenceHolder(i, 6, card);
      }
    } else if (y > 560) {
      dragToHand(i, card);
    }
    return [-1, -1];
  }
</script>

{#each Array(7) as _, i}
  <div
    class="card_box"
    class:card_box_locked={i >= availableSequence}
    bind:this={cardBoxes[i]}
  >
    {#if sequence[i]}
      <Card
        id={sequence[i].id}
        {canPan}
        panStartHandler={handlePanStart}
        panEndHandler={(_, x, y) => handlePanEnd(sequence[i], i, x, y)}
      />
    {/if}
  </div>
{/each}

<style>
  .card_box {
    width: 200px;
    height: 300px;
    background-color: rgba(65, 65, 65, 0.5);
  }
  .card_box_locked {
    background-image: url(/images/lock.png);
    background-size: cover;
  }
</style>
