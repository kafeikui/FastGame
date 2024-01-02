<script>
  import { createEventDispatcher } from "svelte";

  export let selfAddress = "0xd5246e9e34063ef56ea9872e01483248facbb999";
  export let opponentAddress = "0xd5246e9e34063ef56ea9872e01483248facbb999";
  export let round = 0;
  export let inning = 0;
  export let time = 99;
  export let selfScore = 0;
  export let opponentScore = 0;
  export let isSelfOffensive;

  const dispatch = createEventDispatcher();

  function showHelp() {
    dispatch("showHelp");
  }
</script>

<div class="address_box">
  you
  <div class="address">{selfAddress}</div>
  <div class="score">score: {selfScore}</div>
</div>
<div class="state_box">
  <div class="state_params">
    <div class="round">round: {round + 1}</div>
    <div class="inning">inning: {inning + 1}</div>
  </div>
  <div style="width: 5%;" />
  <div class="operation_params">
    <div class="order">
      {isSelfOffensive ? "on the offensive" : "on the defensive"}
    </div>
    <div class="time">
      time: <span style="color:#9b4400;font-weight:bold">{time}</span>
    </div>
  </div>
  <div style="width: 5%;" />
  <button class="help_icon" on:click={showHelp} />
  <div style="width: 1%;" />
  <slot name="audioVolumn" />
  <slot name="opponentSequence" />
  <slot name="battleSimulation" />
</div>
<div class="address_box">
  opponent
  <div class="address">{opponentAddress}</div>
  <div class="score">score: {opponentScore}</div>
</div>

<style>
  .address_box {
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    width: 100%;
    height: 50%;
    font-weight: 550;
    font-size: 18px;
  }
  .state_box {
    display: flex;
    flex-direction: row;
    justify-content: center;
    align-items: center;
    width: 100%;
    height: 90%;
    font-weight: 550;
    font-size: 18px;
  }
  .help_icon {
    width: 50px;
    height: 50px;
    border-radius: 10px;
    background-image: url(/images/help_icon.png);
    background-size: cover;
    background-repeat: no-repeat;
    background-position: center;
    cursor: pointer;
    margin: 0;
  }
  .state_params {
    font-size: 24px;
    width: 120px;
  }
  .operation_params {
    font-size: 24px;
    width: 280px;
  }
</style>
