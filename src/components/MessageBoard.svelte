<script>
  import { beforeUpdate, afterUpdate } from "svelte";
  export function appendMessage(_text) {
    messages = [...messages, { text: _text }];
  }
  export function createMessage(_text) {
    return { text: _text };
  }
  export function initMessages(_messages, _fixedMessage) {
    messages = _messages;
    fixedMessage = _fixedMessage;
  }
  export function setFixedMessage(_text) {
    fixedMessage = { text: _text };
  }

  let fixedMessage = { text: "" };
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

<div class="flex">
  <div class="fixed">
    <article>
      <span>{@html fixedMessage.text}</span>
    </article>
  </div>
  <div class="scrollable" bind:this={oboard}>
    {#each messages as message}
      <article>
        <span>{@html message.text}</span>
      </article>
    {/each}
  </div>
</div>

<style>
  .flex {
    display: flex;
    flex-flow: column nowrap;
    justify-content: center;
    align-items: center;
    border: 1px solid #eee;
  }
  .fixed {
    text-align: center;
    flex: 1 1 auto;
    border-top: 1px solid #eee;
    margin: 0 0 0 0;
    user-select: text;
  }
  .scrollable {
    height: 10vh;
    text-align: center;
    flex: 1 1 auto;
    border-top: 1px solid #eee;
    margin: 0 0 1em 0;
    overflow-y: auto;
    user-select: text;
  }
  article {
    height: 26px;
    font-size: 1.1em;
  }
</style>
