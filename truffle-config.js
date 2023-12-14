const HDWalletProvider = require("@truffle/hdwallet-provider");
require("dotenv").config();

const privateKey = process.env["PRIVATE_KEY"];
const infuraProjectId = process.env["INFURA_PROJECT_ID"];

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*",
    },
    polygon_infura_mainnet: {
      provider: () =>
        new HDWalletProvider(
          privateKey,
          "https://polygon-mainnet.infura.io/v3/" + infuraProjectId
        ),
      network_id: 137,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true,
      chainId: 137,
      gasPrice: 470000000000,
    },
    polygon_infura_testnet: {
      provider: () =>
        new HDWalletProvider(
          privateKey,
          "https://polygon-mumbai.infura.io/v3/" + infuraProjectId
        ),
      network_id: 80001,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true,
      chainId: 80001,
    },
  },
  compilers: {
    solc: {
      version: "0.8.16",
    },
  },
};
