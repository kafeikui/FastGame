<script>
  import { beforeUpdate, afterUpdate } from "svelte";
  export function appendMessage(_text) {
    messages = [...messages, { text: _text }];
  }
  export function createMessage(_text) {
    return { text: _text };
  }
  export function initMessages(_messages) {
    messages = _messages;
  }
  let messages = [];
  let oboard;
  let autoscroll;

  beforeUpdate(() => {
    autoscroll =
      oboard &&
      oboard.offsetHeight + oboard.scrollTop > oboard.scrollHeight - 20;
  });

  afterUpdate(() => {
    if (autoscroll) oboard.scrollTo(0, oboard.scrollHeight);
  });
</script>

<div class="scrollable" bind:this={oboard}>
  {#each messages as message}
    <article>
      <span>{@html message.text}</span>
    </article>
  {/each}
</div>

<style>
  .scrollable {
    text-align: center;
    flex: 1 1 auto;
    border-top: 1px solid #eee;
    margin: 0 0 1em 0;
    overflow-y: auto;
    user-select: none;
  }
  article {
    height: 26px;
    font-size: 1.1em;
  }
</style>
