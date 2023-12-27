<script>
  import { createEventDispatcher } from "svelte";
  import { SectType, QualityType, BuffType } from "../../utils/card";
  import { spring } from "svelte/motion";
  import { pannable } from "../../utils/pannable";
  import { getCard } from "../../utils/card";

  export let id;
  export let index = 0;
  export let canPick = false;
  export let canPan = false;
  export let panStartHandler = () => {};
  export let panEndHandler = () => [-1, -1];

  let c_frame;
  let c_pic;
  let c_name;
  let c_desc;
  let c_desc_bg;

  $: card = getCard(id);
  $: if (!canPick) {
    card.picked = false;
  }
  $: if (c_frame != undefined) {
    switch (card.sect) {
      case SectType.Attack:
        c_frame.style.backgroundImage = `url(/images/frame/a_frame.png)`;
        break;
      case SectType.Defense:
        c_frame.style.backgroundImage = `url(/images/frame/d_frame.png)`;
        break;
      case SectType.Enhance:
        c_frame.style.backgroundImage = `url(/images/frame/e_frame.png)`;
        break;
      case SectType.Weaken:
        c_frame.style.backgroundImage = `url(/images/frame/w_frame.png)`;
        break;
    }
    c_pic.style.backgroundImage = `url(${card.pic})`;
    c_name.innerHTML = card.name;
    switch (card.quality) {
      case QualityType.Low:
        c_desc_bg.style.backgroundColor = `#c4c5c6`;
        break;
      case QualityType.Middle:
        c_desc_bg.style.backgroundColor = `#bbcae6`;
        break;
      case QualityType.High:
        c_desc_bg.style.backgroundColor = `#f1cece`;
        break;
    }
    let desc =
      card.desc == "" ? "" : `${card.desc}<div class="line-break"></div>`;
    let buff_desc = "";
    if (card.buff_type == BuffType.Buff) {
      buff_desc = `<span><span style="color:#9d2933;font-weight:bold";>增益</span>${card.buff_desc}</span>`;
      buff_desc += `<div class="line-break"></div><span>持续${card.continue_turns}回合</span>`;
    } else if (card.buff_type == BuffType.Debuff) {
      buff_desc = `<span><span style="color:purple;font-weight:bold";>减益</span>${card.buff_desc}</span>`;
      buff_desc += `<div class="line-break"></div><span>持续${card.continue_turns}回合</span>`;
    } else if (card.buff_type == BuffType.TimedBuff) {
      buff_desc = `<span>${card.buff_desc}</span>`;
      buff_desc += `<div class="line-break"></div><span>持续${card.continue_turns}次</span>`;
    } else if (card.buff_type == BuffType.Passive) {
      buff_desc = `<span><span style="color:#3d3b4f;font-weight:bold";>被动</span>${card.buff_desc}</span>`;
    }
    if (card.continuous_action) {
      buff_desc += `<div class="line-break"></div><span style="color:#9b4400;font-weight:bold";>连续行动</span>`;
    }
    if (card.available_times < 99) {
      buff_desc += `<div class="line-break"></div><span>可用次数：${card.available_times}</span>`;
    }
    c_desc.innerHTML = desc + buff_desc;
  }

  const dispatch = createEventDispatcher();

  function click() {
    if (!canPick) return;
    card.picked = !card.picked;
    dispatch("click", { card, index });
  }

  // pan
  const coords = spring(
    { x: 0, y: 0 },
    {
      stiffness: 0.2,
      damping: 0.4,
    }
  );

  function handlePanStart(event) {
    coords.stiffness = coords.damping = 1;
    panStartHandler(event.detail.x, event.detail.y);
  }

  function handlePanMove(event) {
    coords.update(($coords) => ({
      x: $coords.x + event.detail.dx,
      y: $coords.y + event.detail.dy,
    }));
  }

  function handlePanEnd(event) {
    coords.stiffness = 0.2;
    coords.damping = 0.4;
    let [targetX, targetY] = panEndHandler(
      card,
      event.detail.x,
      event.detail.y
    );
    targetX = targetX > 0 ? targetX : 0;
    targetY = targetY > 0 ? targetY : 0;
    coords.set({ x: targetX, y: targetY });
  }
</script>

{#if canPan}
  <div
    class="card_box"
    class:picked={card.picked}
    on:click={click}
    use:pannable
    on:panstart={handlePanStart}
    on:panmove={handlePanMove}
    on:panend={handlePanEnd}
    style="transform:
translate({$coords.x}px,{$coords.y}px)"
  >
    <div class="card_frame" bind:this={c_frame}></div>
    <div class="pic" bind:this={c_pic}></div>
    <div class="name_bg"></div>
    <div class="name" bind:this={c_name}></div>
    <div class="desc_bg" bind:this={c_desc_bg}></div>
    <div class="desc_box">
      <div class="desc" bind:this={c_desc}></div>
    </div>
    <div class="star_bg">
      {#each Array(card.level) as _}
        <div class="star"></div>
      {/each}
    </div>
  </div>
{:else}
  <div class="card_box" class:picked={card.picked} on:click={click}>
    <div class="card_frame" bind:this={c_frame}></div>
    <div class="pic" bind:this={c_pic}></div>
    <div class="name_bg"></div>
    <div class="name" bind:this={c_name}></div>
    <div class="desc_bg" bind:this={c_desc_bg}></div>
    <div class="desc_box">
      <div class="desc" bind:this={c_desc}></div>
    </div>
    <div class="star_bg">
      {#each Array(card.level) as _}
        <div class="star"></div>
      {/each}
    </div>
  </div>
{/if}
<div class="line-break"></div>

<style>
  .line-break {
    display: block;
    width: 100%;
    height: 0;
    clear: both;
  }
  .picked {
    top: -40px;
  }

  .card_box {
    /* width: 100%;
    height: 100%; */
    width: 200px;
    height: 300px;
    position: relative;
  }

  .card_frame {
    position: absolute;
    width: 200px;
    height: 300px;
    background-image: url(/images/frame/a_frame.png);
    background-size: 200px 300px;
    pointer-events: auto;
    z-index: 4;
  }
  .pic {
    position: absolute;
    top: 1em;
    left: 1.7em;
    width: 155px;
    height: 155px;
    background-image: url(/images/skill/1.png);
    background-size: cover;
    pointer-events: auto;
    z-index: 1;
  }
  .name {
    position: absolute;
    top: 70px;
    width: 26px;
    height: 90px;
    pointer-events: auto;
    z-index: 6;
    font-size: 14px;
    text-align: center;
    text-shadow: 0 0 10px #000;
    font-weight: bolder;
    font-family: "Microsoft YaHei";
    color: azure;
  }
  .name_bg {
    position: absolute;
    top: 70px;
    width: 30px;
    height: 90px;
    pointer-events: auto;
    background-image: url(/images/skill_name.png);
    background-size: cover;
    z-index: 5;
  }
  .desc_bg {
    position: absolute;
    top: 170px;
    width: 170px;
    height: 110px;
    pointer-events: auto;
    background-color: #e97272;
    z-index: 0;
    margin-left: 15px;
  }
  .desc_box {
    position: absolute;
    display: flex;
    left: 50%;
    transform: translate(-50%);
    justify-content: center;
    margin-top: 170px;
    height: 100px;
    pointer-events: auto;
    z-index: 1;
  }
  .desc {
    display: flex;
    justify-content: center;
    flex-direction: column;
    width: 134px;
    pointer-events: auto;
    font-size: 14.5px;
    text-align: center;
    font-weight: 550;
    font-family: "Microsoft YaHei";
    color: rgb(0, 0, 0);
    z-index: 2;
  }
  .star_bg {
    position: absolute;
    display: flex;
    left: 50%;
    transform: translate(-50%);
    top: 273px;
    height: 30px;
    pointer-events: auto;
    z-index: 6;
  }
  .star {
    display: flex;
    justify-content: center;
    align-items: center;
    width: 20px;
    height: 22px;
    pointer-events: auto;
    background-image: url(/images/star.png);
    background-size: cover;
    z-index: 7;
  }
</style>
