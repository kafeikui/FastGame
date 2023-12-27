import contractJSON from "./const/GameLobby.json";
import Web3 from "web3";

const isDebugUI = false;

// ===============================
// utils
// ===============================
export const getRandomIndex = (seed) => {
  var _seed = seed;
  return function (upperBound) {
    let web3 = new Web3();
    _seed = web3.utils.sha3(_seed);
    return _seed % upperBound;
  };
};

export const getSalt = () => {
  let web3 = new Web3();
  // web3.utils.sha3;
  return web3.utils.randomHex(32);
};
// ===============================
// transactions
// ===============================
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

// createTable()
export const createTable = async (web3, contractAddress) => {
  if (web3 && !isDebugUI) {
    let instance = getContract(web3, contractAddress);
    let method = instance.methods.createTable();
    return sendTransaction(web3, method);
  }
};
// joinTable(uint256 tableId)
export const joinTable = async (web3, contractAddress, tableId) => {
  if (web3 && !isDebugUI) {
    let instance = getContract(web3, contractAddress);
    let method = instance.methods.joinTable(tableId);
    return sendTransaction(web3, method);
  }
};

// function claimVictory(uint256 tableId)
export const claimVictory = async (web3, contractAddress, tableId) => {
  if (web3 && !isDebugUI) {
    let instance = getContract(web3, contractAddress);
    let method = instance.methods.claimVictory(tableId);
    return sendTransaction(web3, method);
  }
};

// function commitPickedCards(uint256 tableId, uint256[] memory commitments)
export const commitPickedCards = async (
  web3,
  contractAddress,
  tableId,
  commitments
) => {
  if (web3 && !isDebugUI) {
    let instance = getContract(web3, contractAddress);
    let method = instance.methods.commitPickedCards(tableId, commitments);
    return sendTransaction(web3, method);
  }
};

// function commitSequence(uint256 tableId, uint256 jointCommitment)
export const commitSequence = async (
  web3,
  contractAddress,
  tableId,
  jointCommitment
) => {
  if (web3 && !isDebugUI) {
    let instance = getContract(web3, contractAddress);
    let method = instance.methods.commitSequence(tableId, jointCommitment);
    return sendTransaction(web3, method);
  }
};

// function revealSequence(uint256 tableId, RevealedCard[] memory sequence)
export const revealSequence = async (
  web3,
  contractAddress,
  tableId,
  sequence
) => {
  if (web3 && !isDebugUI) {
    let instance = getContract(web3, contractAddress);
    let method = instance.methods.revealSequence(tableId, sequence);
    return sendTransaction(web3, method);
  }
};

// function upgradeCard(uint256 tableId, RevealedCard[] memory material)
export const upgradeCard = async (web3, contractAddress, tableId, material) => {
  if (web3 && !isDebugUI) {
    let instance = getContract(web3, contractAddress);
    let method = instance.methods.upgradeCard(tableId, material);
    return sendTransaction(web3, method);
  }
};

// function reforgeCard(uint256 tableId, RevealedCard[] memory material)
export const reforgeCard = async (web3, contractAddress, tableId, material) => {
  if (web3 && !isDebugUI) {
    let instance = getContract(web3, contractAddress);
    let method = instance.methods.reforgeCard(tableId, material);
    return sendTransaction(web3, method);
  }
};

// function summitReforge(uint256 tableId, bytes32 requestId, uint8 nonce)
export const summitReforge = async (
  web3,
  contractAddress,
  tableId,
  requestId,
  nonce
) => {
  if (web3 && !isDebugUI) {
    let instance = getContract(web3, contractAddress);
    let method = instance.methods.summitReforge(tableId, requestId, nonce);
    return sendTransaction(web3, method);
  }
};

// ===============================
// views
// ===============================
// getPlayers(uint256 tableId) returns (address[] memory)
export const getPlayers = async (web3, contractAddress, tableId) => {
  if (web3 && !isDebugUI) {
    let instance = getContract(web3, contractAddress);
    let method = instance.methods.getPlayers(tableId);
    return callView(web3, method);
  }
};

// ===============================
// events
// ===============================
// event TableCreated(uint256 indexed tableId, address indexed player);
export const listenTableCreated = (web3, contractAddress, handler, player) => {
  if (web3 && !isDebugUI) {
    let instance = new web3.eth.Contract(contractJSON.abi, contractAddress);
    return instance.events
      .TableCreated({ filter: { player: player } })
      .on("data", function (event) {
        console.log("listenTableCreated", event);
        handler(event);
      });
  }
};

// event TableJoined(uint256 indexed tableId, address indexed player);
export const listenTableJoined = (web3, contractAddress, handler, tableId) => {
  if (web3 && !isDebugUI) {
    let instance = new web3.eth.Contract(contractJSON.abi, contractAddress);
    return instance.events
      .TableJoined({
        filter: { tableId: tableId },
      })
      .on("data", function (event) {
        console.log("listenTableJoined", event);
        handler(event);
      });
  }
};

// event GameStarted(uint256 indexed tableId, bool firstPlayerOffensive, uint256 nextCommitmentTime);
export const listenGameStarted = (web3, contractAddress, handler, tableId) => {
  if (web3 && !isDebugUI) {
    let instance = new web3.eth.Contract(contractJSON.abi, contractAddress);

    return instance.events
      .GameStarted({
        filter: { tableId: tableId },
      })
      .on("data", function (event) {
        console.log("listenGameStarted", event);
        handler(event);
      });
  }
};

// event CardPoolGenerated(
//   uint256 indexed tableId,
//   bytes32 indexed requestId,
//   uint8 indexed currentRound,
//   uint32[] cardPool,
//   uint256 randomness
// );
export const listenCardPoolGenerated = (
  web3,
  contractAddress,
  handler,
  tableId
) => {
  if (web3 && !isDebugUI) {
    let instance = new web3.eth.Contract(contractJSON.abi, contractAddress);
    return instance.events
      .CardPoolGenerated({
        filter: { tableId: tableId },
      })
      .on("data", function (event) {
        console.log("listenCardPoolGenerated", event);
        handler(event);
      });
  }
};

// event CardDrawn(uint256 indexed tableId, address indexed player, uint8 round, uint8 inning, RevealedCard[] cards);
export const listenCardDrawn = (
  web3,
  contractAddress,
  handler,
  tableId,
  player
) => {
  if (web3 && !isDebugUI) {
    let instance = new web3.eth.Contract(contractJSON.abi, contractAddress);
    return instance.events
      .CardDrawn({
        filter: { tableId: tableId, player: player },
      })
      .on("data", function (event) {
        console.log("listenCardDrawn", event);
        handler(event);
      });
  }
};

// event SequenceCommitted(
//   uint256 indexed tableId, address indexed player, uint8 round, uint8 inning, uint256 commitment
// );
export const listenSequenceCommitted = (
  web3,
  contractAddress,
  handler,
  tableId,
  player
) => {
  if (web3 && !isDebugUI) {
    let instance = new web3.eth.Contract(contractJSON.abi, contractAddress);
    return instance.events
      .SequenceCommitted({
        filter: { tableId: tableId, player: player },
      })
      .on("data", function (event) {
        console.log("listenSequenceCommitted", event);
        handler(event);
      });
  }
};

// event SequenceRevealed(
//   uint256 indexed tableId, address indexed player, uint8 round, uint8 inning, RevealedCard[] cards
// );
export const listenSequenceRevealed = (
  web3,
  contractAddress,
  handler,
  tableId,
  player
) => {
  if (web3 && !isDebugUI) {
    let instance = new web3.eth.Contract(contractJSON.abi, contractAddress);
    return instance.events
      .SequenceRevealed({
        filter: { tableId: tableId, player: player },
      })
      .on("data", function (event) {
        console.log("listenSequenceRevealed", event);
        handler(event);
      });
  }
};

// event CardReforgeGenerated(
//   uint256 indexed tableId,
//   address indexed player,
//   bytes32 indexed requestId,
//   uint256 qualityToReforge,
//   uint256 randomness
// );
export const listenCardReforgeGenerated = (
  web3,
  contractAddress,
  handler,
  tableId,
  player
) => {
  if (web3 && !isDebugUI) {
    let instance = new web3.eth.Contract(contractJSON.abi, contractAddress);
    return instance.events
      .CardReforgeGenerated({
        filter: { tableId: tableId, player: player },
      })
      .on("data", function (event) {
        console.log("listenCardReforgeGenerated", event);
        handler(event);
      });
  }
};

// event InningEnded(
//   uint256 indexed tableId, uint8 indexed round, uint8 indexed inning, address winner, uint256 randomness
// );
export const listenInningEnded = (web3, contractAddress, handler, tableId) => {
  if (web3 && !isDebugUI) {
    let instance = new web3.eth.Contract(contractJSON.abi, contractAddress);
    return instance.events
      .InningEnded({
        filter: { tableId: tableId },
      })
      .on("data", function (event) {
        console.log("listenInningEnded", event);
        handler(event);
      });
  }
};

// event RoundEnded(uint256 indexed tableId, uint8 indexed round);
export const listenRoundEnded = (web3, contractAddress, handler, tableId) => {
  if (web3 && !isDebugUI) {
    let instance = new web3.eth.Contract(contractJSON.abi, contractAddress);
    return instance.events
      .RoundEnded({
        filter: { tableId: tableId },
      })
      .on("data", function (event) {
        console.log("listenRoundEnded", event);
        handler(event);
      });
  }
};

// event GameEnded(uint256 indexed tableId, address indexed winner);
export const listenGameEnded = (web3, contractAddress, handler, tableId) => {
  if (web3 && !isDebugUI) {
    let instance = new web3.eth.Contract(contractJSON.abi, contractAddress);
    return instance.events
      .GameEnded({
        filter: { tableId: tableId },
      })
      .on("data", function (event) {
        console.log("listenGameEnded", event);
        handler(event);
      });
  }
};

// ===============================
// internals
// ===============================
function getContract(web3, contractAddress) {
  return new web3.eth.Contract(contractJSON.abi, contractAddress);
}

async function sendTransaction(web3, method) {
  let account = web3.eth.accounts.wallet[0].address;
  console.log(method._method.name);
  let gas_estimate = 2000000;
  try {
    gas_estimate = await method.estimateGas({ from: account });
    gas_estimate = Math.round(gas_estimate * 1.2);
  } catch (e) {
    console.log(e);
  }

  //   var gasprice = await web3.eth.getGasPrice();
  //  gasprice = Math.round(gasprice * 1.2);
  try {
    let receipt = await method.send({
      from: account,
      gas: web3.utils.toHex(gas_estimate),
      //   web3.utils.toHex(gasprice),
    });
    console.log(receipt);
  } catch (e) {
    // console.log(e);
    console.error(
      `Context changed, try for another time with the latest gas estimation. \n${e}`
    );

    // try for another time with the latest gas estimation
    gas_estimate = await method.estimateGas({ from: account });
    gas_estimate = Math.round(gas_estimate * 1.2);

    try {
      let receipt = await method.send({
        from: account,
        gas: web3.utils.toHex(gas_estimate),
        //   web3.utils.toHex(gasprice),
      });
      console.log(receipt);
    } catch (e) {
      // error still exists, print it out
      console.log(e);
    }
  }
}

async function callView(web3, method) {
  let account = web3.eth.accounts.wallet[0].address;

  return method.call({
    from: account,
  });
}
