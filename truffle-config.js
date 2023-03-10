const HDWalletProvider = require("@truffle/hdwallet-provider");
const fs = require("fs");

const cwd = process.cwd();

module.exports = {
  networks: {
    devnet: {
      provider: () => {
        const mnemonic = fs.readFileSync(cwd + "/.secret").toString().trim();
        return new HDWalletProvider({
          mnemonic,
          providerOrUrl: "https://devnet.neonevm.org",
        });
      },
      network_id: "245022926",
    },
  },

  // Set default mocha options here, use special reporters, etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.8.19",      // Fetch exact version from solc-bin (default: truffle's version)
      // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
      // settings: {          // See the solidity docs for advice about optimization and evmVersion
      //  optimizer: {
      //    enabled: false,
      //    runs: 200
      //  },
      //  evmVersion: "byzantium"
      // }
    }
  },
};
