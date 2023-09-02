<script>
  import Card from "./Card.svelte";
  export let card;
</script>

<div class="battlecard">
  {#if card}
    <Card wantCard={card} index={0} offset={50} />
  {/if}
</div>

<style>
  .battlecard {
    width: 200px;
    height: 300px;
    border: 1px solid #aaa;
    border-radius: 2px;
    box-shadow: 2px 2px 8px rgba(0, 0, 0, 0.1);
    padding: 0.5em;
    margin: 0 0 1em 0;
    position: relative;
  }
</style>
