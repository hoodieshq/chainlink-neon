const Web3 = require("web3");
const fs = require("fs");

const web3 = new Web3(new Web3.providers.HttpProvider("https://devnet.neonevm.org/"));
const aggregatorV3InterfaceABI = JSON.parse(fs.readFileSync("./AggregatorV3Interface.json"));

const contract = new web3.eth.Contract(aggregatorV3InterfaceABI, process.env.ORACLE_ADDRESS)

contract.methods.version().call().then((version) => { console.log("version:", version) })
contract.methods.description().call().then((description) => { console.log("description:", description) })
contract.methods.decimals().call().then((decimals) => { console.log("decimals:", decimals) })
contract.methods.latestRoundData().call().then(({ roundId, answer, startedAt, updatedAt, answeredInRound }) => {
  console.log("latestRoundData:", { roundId, answer, startedAt, updatedAt, answeredInRound })
})

contract.methods.getRoundData(process.env.ROUND).call()
  .then(({ roundId, answer, startedAt, updatedAt, answeredInRound }) => {
  console.log("getRoundData:", { roundId, answer, startedAt, updatedAt, answeredInRound })
  })
  .catch(console.log)
