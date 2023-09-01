import contractJSON from "./const/CardGame.json";
import Web3 from "web3";

export const getRandomIndex = (seed) => {
  var _seed = seed;
  return function (upperBound) {
    let web3 = new Web3();
    _seed = web3.utils.sha3(_seed);
    return _seed % upperBound;
  };
};

export async function sendETH(web3, from, to, amount) {
  let gas_estimate = await web3.eth.estimateGas({
    from,
    to,
    value: amount,
  });
  gas_estimate = Math.round(gas_estimate * 1.2);
  return web3.eth.sendTransaction({
    from,
    to,
    value: amount,
    gas: gas_estimate,
  });
}

// ===============================
// transactions
// ===============================
// createTable()
export const createTable = async (web3, contractAddress) => {
  if (web3) {
    let instance = getContract(web3, contractAddress);
    let method = instance.methods.createTable();
    return sendTransaction(web3, method);
  }
};
// joinTable(uint256 tableId)
export const joinTable = async (web3, contractAddress, tableId) => {
  if (web3) {
    let instance = getContract(web3, contractAddress);
    let method = instance.methods.joinTable(tableId);
    return sendTransaction(web3, method);
  }
};
// determineRuleType(uint256 tableId, uint8 ruleType)
export const determineRuleType = async (
  web3,
  contractAddress,
  tableId,
  ruleType
) => {
  if (web3) {
    let instance = getContract(web3, contractAddress);
    let method = instance.methods.determineRuleType(tableId, ruleType);
    return sendTransaction(web3, method);
  }
};

// commitHands(uint256 tableId, string[] memory hands)
export const commitHands = async (web3, contractAddress, tableId, hands) => {
  if (web3) {
    let instance = getContract(web3, contractAddress);
    let method = instance.methods.commitHands(tableId, hands);
    return sendTransaction(web3, method);
  }
};

// commit(uint256 tableId, bytes32 commitment)
export const commit = async (web3, contractAddress, tableId, commitment) => {
  if (web3) {
    let instance = getContract(web3, contractAddress);
    let method = instance.methods.commit(tableId, commitment);
    return sendTransaction(web3, method);
  }
};

// play(uint256 tableId, uint256 index, string memory card)
export const playCard = async (web3, contractAddress, tableId, index, card) => {
  if (web3) {
    let instance = getContract(web3, contractAddress);
    let method = instance.methods.play(tableId, index, card);
    return sendTransaction(web3, method);
  }
};

// getRandomSeed(uint256 tableId)
export const getRandomSeed = async (web3, contractAddress, tableId) => {
  if (web3) {
    let instance = new web3.eth.Contract(contractJSON.abi, contractAddress);
    let method = instance.methods.getRandomSeed(tableId);
    return sendTransaction(web3, method);
  }
};

// ===============================
// views
// ===============================
// getPlayers(uint256 tableId) returns (address[] memory)
export const getPlayers = async (web3, contractAddress, tableId) => {
  if (web3) {
    let instance = getContract(web3, contractAddress);
    let method = instance.methods.getPlayers(tableId);
    return callView(web3, method);
  }
};

// getCurrentState(uint256 tableId) returns (uint256, uint256)
export const getCurrentState = async (web3, contractAddress, tableId) => {
  if (web3) {
    let instance = getContract(web3, contractAddress);
    let method = instance.methods.getCurrentState(tableId);
    return callView(web3, method);
  }
};

// ===============================
// events
// ===============================
export const listenRandomSeedRequest = (
  web3,
  contractAddress,
  handler,
  tableId
) => {
  if (web3) {
    let instance = new web3.eth.Contract(contractJSON.abi, contractAddress);

    return instance.events
      .RandomnessRequested({
        filter: { tableId: tableId },
      })
      .on("data", function (event) {
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

//     event CardPoolGenerated(uint256 indexed tableId, bytes32 indexed requestId, uint256[] cardPool);
export const listenCardPoolGenerated = (
  web3,
  contractAddress,
  handler,
  tableId
) => {
  if (web3) {
    let instance = new web3.eth.Contract(contractJSON.abi, contractAddress);
    return instance.events
      .CardPoolGenerated({
        filter: { tableId: tableId },
      })
      .on("data", function (event) {
        console.log(event);
        handler(event);
      });
  }
};
//     event RoundEnded(uint256 indexed tableId, uint256 indexed set, uint256 indexed round);
export const listenRoundEnded = (web3, contractAddress, handler, tableId) => {
  if (web3) {
    let instance = new web3.eth.Contract(contractJSON.abi, contractAddress);
    return instance.events
      .RoundEnded({
        filter: { tableId: tableId },
      })
      .on("data", function (event) {
        console.log(event);
        handler(event);
      });
  }
};

//     event SetEnded(uint256 indexed tableId, uint256 indexed set, address winner);
export const listenSetEnded = (web3, contractAddress, handler, tableId) => {
  if (web3) {
    let instance = new web3.eth.Contract(contractJSON.abi, contractAddress);
    return instance.events
      .SetEnded({
        filter: { tableId: tableId },
      })
      .on("data", function (event) {
        console.log(event);
        handler(event);
      });
  }
};

//     event TableCreated(uint256 indexed tableId, address indexed player);
export const listenTableCreated = (web3, contractAddress, handler, player) => {
  if (web3) {
    let instance = new web3.eth.Contract(contractJSON.abi, contractAddress);
    return instance.events
      .TableCreated({ filter: { player: player } })
      .on("data", function (event) {
        console.log(event);
        handler(event);
      });
  }
};

//     event TableJoined(uint256 indexed tableId, address indexed player);
export const listenTableJoined = (web3, contractAddress, handler, tableId) => {
  if (web3) {
    let instance = new web3.eth.Contract(contractJSON.abi, contractAddress);
    return instance.events
      .TableJoined({
        filter: { tableId: tableId },
      })
      .on("data", function (event) {
        console.log(event);
        handler(event);
      });
  }
};
//     event GameEnded(uint256 indexed tableId, address indexed winner);
export const listenGameEnded = (web3, contractAddress, handler, tableId) => {
  if (web3) {
    let instance = new web3.eth.Contract(contractJSON.abi, contractAddress);
    return instance.events
      .GameEnded({
        filter: { tableId: tableId },
      })
      .on("data", function (event) {
        console.log(event);
        handler(event);
      });
  }
};
//     event RuleTypeDetermined(uint256 indexed tableId, uint8 ruleType);
export const listenRuleTypeDetermined = (
  web3,
  contractAddress,
  handler,
  tableId
) => {
  if (web3) {
    let instance = new web3.eth.Contract(contractJSON.abi, contractAddress);
    return instance.events
      .RuleTypeDetermined({
        filter: { tableId: tableId },
      })
      .on("data", function (event) {
        console.log(event);
        handler(event);
      });
  }
};
//     event HandsCommitted(uint256 indexed tableId, address indexed player, string[] hands);
export const listenHandsCommitted = (
  web3,
  contractAddress,
  handler,
  tableId,
  player
) => {
  if (web3) {
    let instance = new web3.eth.Contract(contractJSON.abi, contractAddress);
    return instance.events
      .HandsCommitted({
        filter: { tableId: tableId, player: player },
      })
      .on("data", function (event) {
        console.log(event);
        handler(event);
      });
  }
};
//     event CardCommitted(uint256 indexed tableId, address indexed player, uint256 indexed round, bytes32 commitment);
export const listenCardCommitted = (
  web3,
  contractAddress,
  handler,
  tableId,
  player
) => {
  if (web3) {
    let instance = new web3.eth.Contract(contractJSON.abi, contractAddress);
    return instance.events
      .CardCommitted({
        filter: { tableId: tableId, player: player },
      })
      .on("data", function (event) {
        console.log(event);
        handler(event);
      });
  }
};
//     event CardPlayed(
//         uint256 indexed tableId, address indexed player, uint256 set, uint256 round, uint256 index, string card
//     );
export const listenCardPlayed = (
  web3,
  contractAddress,
  handler,
  tableId,
  player
) => {
  if (web3) {
    let instance = new web3.eth.Contract(contractJSON.abi, contractAddress);
    return instance.events
      .CardPlayed({
        filter: { tableId: tableId, player: player },
      })
      .on("data", function (event) {
        console.log(event);
        handler(event);
      });
  }
};

function getContract(web3, contractAddress) {
  return new web3.eth.Contract(contractJSON.abi, contractAddress);
}

async function sendTransaction(web3, method) {
  let account = web3.eth.accounts.wallet[0].address;
  console.log(method._method.name);
  // let gas_estimate = await method.estimateGas({ from: account });
  // gas_estimate = Math.round(gas_estimate * 1.2);

  //   var gasprice = await web3.eth.getGasPrice();
  //  gasprice = Math.round(gasprice * 1.2);
  return method
    .send({
      from: account,
      // gas: web3.utils.toHex(gas_estimate),
      gas: 1000000,
      //   web3.utils.toHex(gasprice),
    })
    .on("transactionHash", function (hash) {
      console.log(hash);
    })
    .on("receipt", function (receipt) {
      console.log(receipt);
    })
    .on("error", async function (error) {
      console.error(
        `Context changed, try for another time with the latest gas estimation. \n${error}`
      );
      // try for another time with gas estimation on that block number
      // gas_estimate = await method.estimateGas({ from: account });
      // gas_estimate = Math.round(gas_estimate * 1.2);

      method
        .send({
          from: account,
          // gas: web3.utils.toHex(gas_estimate),
          gas: 1000000,
          //   web3.utils.toHex(gasprice),
        })
        .on("transactionHash", function (hash) {
          console.log(hash);
        })
        .on("receipt", function (receipt) {
          console.log(receipt);
        })
        .on("error", function (error) {
          // error still exists, print it out
          console.error(error);
        });
    });
}

async function callView(web3, method) {
  let account = web3.eth.accounts.wallet[0].address;

  return method.call({
    from: account,
  });
}
