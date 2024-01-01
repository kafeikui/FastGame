<script>
  import { createEventDispatcher, afterUpdate } from "svelte";

  const dispatch = createEventDispatcher();

  export let helpText;
  export let canBack;
  export let boardHeight;
  let oHelpBoard;
  let oHelpText;
  let oBack;

  function back() {
    dispatch("back");
  }

  afterUpdate(() => {
    if (oHelpBoard) {
      oHelpBoard.style.height = boardHeight + "px";
      oHelpBoard.style.backgroundSize = "1600px " + boardHeight + "px";
    }
    if (oHelpText) {
      oHelpText.style.height = boardHeight + "px";
    }
    if (canBack) {
      oBack.style.display = "flex";
    } else {
      oBack.style.display = "none";
    }
  });
</script>

<div class="help-board" bind:this={oHelpBoard}>
  <div class="help-text" bind:this={oHelpText}>
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
    margin-top: 30px;
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
    right: 8%;
    bottom: 2%;
    transform: translate(-50%);
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
