<script>
  import { afterUpdate } from "svelte";

  export let maxHp;
  export let hp;
  let oWrap;
  let oHp;
  afterUpdate(() => {
    oHp.style.width = `${(hp / maxHp) * 100}%`;
  });
</script>

<div class="address">0xd5246e9E34063EF56eA9872E01483248facbBda3</div>
<div class="health_box">
  <div class="wrap" bind:this={oWrap}>
    <div class="hp" bind:this={oHp}></div>
  </div>
</div>

<style>
  .address {
    display: flex;
    justify-content: center;
    align-items: center;
    width: 100%;
    height: 10%;
  }
  .health_box {
    display: flex;
    justify-content: center;
    align-items: center;
    width: 100%;
    height: 90%;
  }
  .wrap {
    width: 100%;
    height: 30px;
    background-color: #000;
  }

  .hp {
    width: 100%;
    height: 100%;
    transition: width 1s ease;
    background-color: rgb(221, 58, 58);
  }
</style>
