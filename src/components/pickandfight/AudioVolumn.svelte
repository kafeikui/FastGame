<script>
  import { createEventDispatcher } from "svelte";

  export let isMuted = false;

  const dispatch = createEventDispatcher();

  function switchVol() {
    dispatch("switchVol", {});
  }
</script>

<div class="volumn" class:gray={isMuted} on:click={switchVol}></div>

<style>
  .volumn {
    width: 100%;
    height: 100%;
    background-image: url(/images/volumn.png);
    background-size: cover;
  }
  .gray {
    -webkit-filter: grayscale(100%);
    -moz-filter: grayscale(100%);
    -ms-filter: grayscale(100%);
    -o-filter: grayscale(100%);
    filter: grayscale(100%);
    filter: gray;
    opacity: 0.7;
  }
</style>
