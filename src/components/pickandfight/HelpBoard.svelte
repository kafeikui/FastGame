<script>
  import { createEventDispatcher, afterUpdate } from "svelte";

  const dispatch = createEventDispatcher();

  export let helpText;
  export let canBack;

  let oBack;

  function back() {
    dispatch("back");
  }

  afterUpdate(() => {
    if (canBack) {
      oBack.style.display = "flex";
    } else {
      oBack.style.display = "none";
    }
  });
</script>

<div class="help-board">
  <div class="help-text">
    {helpText}
  </div>
  <button class="back" on:click={back} bind:this={oBack}>Back</button>
</div>

<style>
  .help-board {
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    margin: auto;
    width: 1600px;
    height: 1024px;
    z-index: 1001;
    background-image: url(/images/help.png);
    background-size: 1600px 1024px;
    object-fit: fill;
    font-weight: bold;
  }
  .help-text {
    position: absolute;
    left: 50%;
    transform: translate(-50%);
    display: flex;
    justify-content: center;
    align-items: center;
    width: 1100px;
    height: 1024px;
    z-index: 1002;
    font-size: 28px;
    font-weight: 450;
    color: black;
    white-space: pre-line;
  }
  .back {
    position: absolute;
    display: flex;
    justify-content: center;
    align-items: center;
    right: 4%;
    transform: translate(-50%);
    bottom: 100px;
    width: 200px;
    height: 50px;
    z-index: 1002;
    border-radius: 10px;
    background-color: rgba(255, 255, 255, 0.65);
    font-size: 30px;
    font-weight: bold;
    color: black;
  }
</style>
