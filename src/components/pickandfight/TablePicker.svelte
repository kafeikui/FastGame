<script>
  import { createEventDispatcher, afterUpdate } from "svelte";

  export let onPick = false;
  let oTablePicker;
  let tableId;

  // event
  const dispatch = createEventDispatcher();

  afterUpdate(() => {
    if (onPick) {
      oTablePicker.style.display = "flex";
    } else {
      oTablePicker.style.display = "none";
    }
  });
</script>

<div class="tablePicker" bind:this={oTablePicker}>
  <div class="title">
    <p>Welcome! Please create a table or join one:</p>
  </div>
  <div class="tableBoard">
    <button class="table" on:click={(e) => dispatch("create", {})}
      >Create</button
    >
  </div>
  <div class="tableBoard">
    <input class="tableIdInput" bind:value={tableId} />
    <button
      class="table"
      on:click={(e) => {
        dispatch("join", {
          tableId,
        });
        tableId = "";
      }}>Join</button
    >
  </div>
</div>

<style>
  .title {
    font-size: 1.5em;
    /* margin-block-start: 0.83em;
    margin-block-end: 0.83em;
    margin-inline-start: 0px;
    margin-inline-end: 0px; */
    font-weight: bold;
  }
  .tableIdInput {
    width: 22em;
  }
  .tablePicker {
    color: #fff;
    width: 600px;
    height: 400px;
    background-color: #40527e;
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    align-items: center;
    border-radius: 10px;
    padding-top: 50px;
    padding-bottom: 50px;
    box-sizing: border-box;
    position: absolute;
    top: 10vh;
    left: 35vw;
    z-index: 1000;
  }
  .tableBoard {
    justify-content: center;
  }
  .table {
    color: #fff;
    cursor: pointer;
    width: 160px;
    height: 50px;
    background-color: #02a0a0;
    margin: 1em;
    font-size: 1.2em;
    text-align: center;
    align-items: center;
  }

  .table:hover {
    background-color: #019191;
  }
</style>
