<script>
  import Card from "./Card.svelte";

  export let cards;
  export let isEnemy;
  let oCards = [];
  let originX;
  let originY;
  let initialized = [];

  $: {
    for (let i = 0; i < cards.length; i++) {
      if (oCards[i] && !initialized[i]) {
        oCards[i].style.top = `0px`;
        if (!isEnemy) {
          oCards[i].style.left = `${i * 100}px`;
        } else {
          oCards[i].style.right = `${(6 - i) * 100}px`;
        }
        oCards[i].style.zIndex = i;
        initialized[i] = true;
      }
    }
  }
  $: initialize(cards);

  function initialize(_cards) {
    initialized = [];
  }

  function play(e) {
    let { sequenceIndex: i, isEnemy: _isEnemy } = e.detail;
    if (isEnemy !== _isEnemy) {
      return;
    }

    let x = parseInt(oCards[i].style.top.slice(0, -2));
    let y = isEnemy
      ? parseInt(oCards[i].style.right.slice(0, -2))
      : parseInt(oCards[i].style.left.slice(0, -2));
    originX = x;
    originY = y;
    // 0.3s
    let xSpeed = x <= -300 ? 0 : (x + 300) / 30;
    let ySpeed = y <= 0 ? 0 : y / 30;
    let dsq = setInterval(() => {
      if (x <= -300 && y <= 0) {
        clearInterval(dsq);
      }
      if (x > -300) {
        x = x - xSpeed > -300 ? x - xSpeed : -300;
      }
      if (y > 0) {
        y = y - ySpeed > 0 ? y - ySpeed : 0;
      }
      oCards[i].style.top = x + "px";
      if (!isEnemy) {
        oCards[i].style.left = y + "px";
      } else {
        oCards[i].style.right = y + "px";
      }
    }, 10);
  }

  function retract(e) {
    let { sequenceIndex: i, isEnemy: _isEnemy } = e.detail;
    if (isEnemy !== _isEnemy) {
      return;
    }

    //move back to origin
    let x = parseInt(oCards[i].style.top.slice(0, -2));
    let y = isEnemy
      ? parseInt(oCards[i].style.right.slice(0, -2))
      : parseInt(oCards[i].style.left.slice(0, -2));
    let xSpeed = (originX - x) / 30;
    let ySpeed = (originY - y) / 30;
    let dsq = setInterval(() => {
      if (x >= originX && y >= originY) {
        clearInterval(dsq);
      }
      if (x < originX) {
        x = x + xSpeed > originX ? originX : x + xSpeed;
      }
      if (y < originY) {
        y = y + ySpeed > originY ? originY : y + ySpeed;
      }
      oCards[i].style.top = x + "px";
      if (!isEnemy) {
        oCards[i].style.left = y + "px";
      } else {
        oCards[i].style.right = y + "px";
      }
    }, 10);
  }
</script>

<div class="card_box">
  {#each cards as card, i}
    <div class="card_case" bind:this={oCards[i]}>
      <Card id={card} />
    </div>
  {/each}
</div>
<svelte:window on:playCard={play} on:retractCard={retract} />

<style>
  .card_box {
    display: flex;
    flex-wrap: nowrap;
    justify-items: center;
    align-items: start;
    position: relative;
    width: 100%;
    height: 100%;
  }
  .card_case {
    position: absolute;
    width: 200px;
    height: 300px;
  }
</style>
