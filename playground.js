const Web3 = require("web3");
const fs = require("fs");

const web3 = new Web3(new Web3.providers.HttpProvider("https://proxy.devnet.neonlabs.org/solana"));
const { abi } = JSON.parse(fs.readFileSync("./build/contracts/ChainlinkOracle.json"));

// web3.eth.getBlockNumber().then((result) => {
//   console.log("Latest Ethereum Block is ",result);
// });

// web3.eth.getBalance('0xc0a3EF89a16FeC26bA5eb59Ed0e47Fd38b9A2eb1').then(console.log)

const contract = new web3.eth.Contract(abi, '0x8622028fc7450A5294F29Bc7c0806783d977946F')
contract.methods.feedAddress().call().then(console.log)
