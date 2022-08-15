const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");
const fs = require("fs");
const ethers = require("ethers");
require("dotenv").config();
const { paddedBuffer } = require("./utils");
const { genHeds, contracts } = require("./constants");
const { hedsTapeAbi } = require("./hedsTapeAbi");

const generateWhitelist = async () => {
  let whitelist = genHeds;

  for (const contractData of contracts) {
    const contract = new ethers.Contract(
      contractData.address,
      hedsTapeAbi,
      new ethers.providers.JsonRpcProvider(
        `https://mainnet.infura.io/v3/${process.env.INFURA_KEY}`
      )
    );

    for (let i = 1; i < contractData.totalSupply; i++) {
      const owner = await contract.ownerOf(i);
      whitelist.push(owner);
    }
  }

  return [...new Set(whitelist)];
};

const main = async () => {
  const whitelist = await generateWhitelist();
  const tree = new MerkleTree(whitelist.map(paddedBuffer), keccak256, {
    sort: true,
  });
  const root = tree.getRoot().toString("hex");
  const proofs = {};
  for (const address of whitelist) {
    const leaf = paddedBuffer(address);
    const proof = tree.getHexProof(leaf);
    proofs[address.toLowerCase()] = proof;
  }
  fs.writeFileSync("root.json", JSON.stringify(root));
  fs.writeFileSync("proofs.json", JSON.stringify(proofs));
};

main();
