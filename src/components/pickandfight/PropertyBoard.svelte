<script>
  export let playerState;
</script>

<div class="board">
  <div class="property">
    <div class="property-value">生命:{playerState.health}</div>
  </div>
  <div class="property">
    <div class="property-value">最大生命:{playerState.maxHealth}</div>
  </div>
  <div class="property">
    <div class="property-value">攻击:{playerState.damage}</div>
  </div>
  <div class="property">
    <div class="property-value">命中:{playerState.hitRate}</div>
  </div>
  <div class="property">
    <div class="property-value">闪避:{playerState.dodgeRate}</div>
  </div>
  <div class="property">
    <div class="property-value">暴击:{playerState.critRate}</div>
  </div>
  <div class="property">
    <div class="property-value">暴伤:{playerState.critDamage}</div>
  </div>
  <div class="property">
    <div class="property-value">攻击系数:{playerState.damageReduction}</div>
  </div>
  <div class="property">
    <div class="property-value">防御系数:{playerState.damageIncrease}</div>
  </div>
</div>

<style>
  .board {
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    align-items: center;
    width: 100%;
    height: 100%;
  }
  .property {
    display: flex;
    justify-content: center;
    align-items: center;
    width: 100%;
    height: 15%;
    border-style: none;
  }
  .property-value {
    font-size: 1rem;
    font-weight: bold;
  }
</style>
