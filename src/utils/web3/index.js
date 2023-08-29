import contractJSON from "./const/CardGame.json";
import Web3 from "web3";

export const getRandomSeed = async (web3, contractAddress) => {
  if (web3) {
    let instance = new web3.eth.Contract(contractJSON.abi, contractAddress);
    let account = web3.eth.accounts.wallet[0].address;
    let method = instance.methods.getRandomSeed();
    var gas_estimate = await method.estimateGas({ from: account });
    gas_estimate = Math.round(gas_estimate * 1.2);
    //   var gasprice = await web3.eth.getGasPrice();
    //  gasprice = Math.round(gasprice * 1.2);

    return method.send({
      from: account,
      gas: web3.utils.toHex(gas_estimate),
      //   web3.utils.toHex(gasprice),
    });
  }
};

export const listenRandomSeedRequest = (web3, contractAddress, handler) => {
  if (web3) {
    let instance = new web3.eth.Contract(contractJSON.abi, contractAddress);

    return instance.events.RandomnessRequested().on("data", function (event) {
      console.log(event);
      handler(event);
    });
  }
};

export const listenRandomSeedRequestFulfillment = (
  web3,
  contractAddress,
  handler
) => {
  if (web3) {
    let instance = new web3.eth.Contract(contractJSON.abi, contractAddress);

    return instance.events.RandomnessFulfilled().on("data", function (event) {
      console.log(event);
      handler(event);
    });
  }
};

export const getRandomIndex = (seed) => {
  var _seed = seed;
  return function (upperBound) {
    let web3 = new Web3();
    _seed = web3.utils.soliditySha3(_seed);
    return _seed % upperBound;
  };
};
