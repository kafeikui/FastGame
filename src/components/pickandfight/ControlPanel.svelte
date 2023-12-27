<script>
  import { createEventDispatcher } from "svelte";
  export let enablePlay = true;
  export let enableReforge = true;
  export let enableRestart = false;
  const dispatch = createEventDispatcher();
  function play() {
    dispatch("play", {});
  }
  function reforge() {
    dispatch("reforge", {});
  }
  function restart() {
    dispatch("restart", {});
  }
</script>

<div class="panelBoard">
  <div class="panel">
    <button class="font" disabled={!enablePlay} on:click={play}>
      Start Fighting!
    </button>
  </div>
  <div class="panel">
    <button class="font" disabled={!enableReforge} on:click={reforge}>
      Reforge
    </button>
  </div>
  <div class="panel">
    <button class="font" disabled={!enableRestart} on:click={restart}>
      Restart
    </button>
  </div>
  <div class="panel">
    <slot name="exbutton" />
  </div>
</div>

<style>
  .panelBoard {
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    align-items: center;
    margin-top: 1em;
  }
  .panel {
    width: 120px;
    margin: 0.5em;
    text-align: center;
    position: relative;
  }

  .font {
    font-family: "Comic Sans MS", cursive;
    font-size: 1.6em;
  }
</style>
