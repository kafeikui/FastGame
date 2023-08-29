<script context="module">
  import {
    listenRandomSeedRequest,
    listenRandomSeedRequestFulfillment,
    getRandomSeed,
  } from "../utils/web3";

  // requestId => randomness
  const randoms = new Map();
  let lastRandomness;
  let web3, contractAddress;

  export function getLastRandomness() {
    return lastRandomness;
  }

  export function clearLastRandomness() {
    lastRandomness = undefined;
  }

  export function initListeners(_web3, _contractAddress) {
    web3 = _web3;
    contractAddress = _contractAddress;
    listenRandomSeedRequest(web3, contractAddress, function () {});
    listenRandomSeedRequestFulfillment(
      web3,
      contractAddress,
      handleRandomSeedRequestFulfillment
    );
  }

  export async function getRandom() {
    return getRandomSeed(web3, contractAddress);
  }

  function handleRandomSeedRequestFulfillment(event) {
    lastRandomness = event.returnValues.randomness;
    console.log(lastRandomness);
    randoms.set(event.returnValues.requestId, event.returnValues.randomness);
  }
</script>
