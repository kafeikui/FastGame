<script>
  import { afterUpdate, onMount } from "svelte";
  import { MAX_CARD_ID } from "../../constants/card_constant";

  export let buffs;
  let oBuffList = [];
  let oDesc;
  function descOnmouseover(desc) {
    oDesc.style.display = "block";
    oDesc.style.borderStyle = "solid";
    oDesc.innerHTML = desc;
  }
  function descOnmouseout() {
    oDesc.style.borderStyle = "none";
    oDesc.style.display = "none";
  }
  function descOnmousemove(ev) {
    var e = ev || window.event;
    oDesc.style.left = e.clientX + 3 + "px";
    oDesc.style.top = e.clientY + 3 + "px";
  }

  afterUpdate(() => {
    let buffList = buffs;
    for (let i = 0; i < buffList.length; i++) {
      let id = buffList[i].id % (MAX_CARD_ID + 1);
      oBuffList[i].style.backgroundImage = `url(/images/buff/${id}.png)`;
    }
  });
</script>

{#each buffs as buff, i}
  <div
    class="buff"
    bind:this={oBuffList[i]}
    on:mouseover={() => {
      descOnmouseover(buff.description());
    }}
    on:mouseout={descOnmouseout}
    on:mousemove={descOnmousemove}
  >
    <div class="buff-turns">{buff.duration}</div>
  </div>
{/each}
<div class="desc" bind:this={oDesc} />

<style>
  .buff {
    width: 50px;
    height: 50px;
    background-size: cover;
    z-index: 990;
  }
  .buff-turns {
    width: 15px;
    height: 20px;
    font-size: large;
    font-weight: bold;
    background-color: rgba(255, 255, 255, 0.65);
  }
  .desc {
    position: absolute;
    top: 0;
    left: 0;
    width: 20%;
    height: 3rem;
    z-index: 998;
    font-weight: bold;
  }
</style>
