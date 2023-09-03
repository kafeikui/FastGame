import configJSON from "./web3/const/GameConfig.json";

export const getEnv = (key) => {
  switch (key) {
    case "websocketProvider":
      if (process.env.websocketProvider !== undefined) {
        return process.env.websocketProvider;
      }
      return configJSON.websocketProvider;
    case "devAccounts":
      if (process.env.devAccounts !== undefined) {
        return process.env.devAccounts;
      }
      return configJSON.devAccounts;
    case "contractAddress":
      if (process.env.contractAddress !== undefined) {
        return process.env.contractAddress;
      }
      return configJSON.contractAddress;
    case "demoETHValue":
      if (process.env.demoETHValue !== undefined) {
        return process.env.demoETHValue;
      }
      return configJSON.demoETHValue;
    default:
      throw new Error(`Env ${key} not found`);
  }
};
