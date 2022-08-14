const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");
const fs = require("fs");
const { paddedBuffer } = require("./utils");
const { genHeds, contracts } = require("./constants");

const generateWhitelist = async () => {
  let whitelist = genHeds;
};

const main = async () => {
  const whitelist = generateWhitelist();
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
  fs.writeFileSync("proofs.json", `Root: ${root}`);
  fs.writeFileSync("proofs.json", "\n");
  fs.writeFileSync("proofs.json", JSON.stringify(proofs));
};

main();
