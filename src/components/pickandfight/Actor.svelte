<script>
  import { afterUpdate } from "svelte";

  export let playerAvatar;
  let oAvatar;
  afterUpdate(() => {
    oAvatar.style.backgroundImage = `url(${playerAvatar})`;
  });
</script>

<div class="actor" bind:this={oAvatar}></div>

<style>
  .actor {
    width: 180px;
    height: 180px;
    background-size: cover;
  }
</style>
