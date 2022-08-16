# collabTAPE

### Whitelist

- Generated with initial 59 GENHEDS minters and owners of hedsTAPEs 1-6
- Array of addresses found in `whitelist.json`
- Merkleproofs corresponding to each address found in `proofs.json`
- Each whitelisted address can premint one time
- To premint, call `preMint` and pass in the corresponding proof of the calling address
  - Will have to convert each array element in the proof to a `BigNumber` to properly call from frontend

### TokenURI's/Reveal

- `tokenURI` will return `baseUri` concatenated with the `tokenId`, e.g. ipfs://abc.io/3
- Media returned from token metadata should be shuffled, i.e. the different NFT types should correspond to the tokenId's in a pseudo-random order
- Media should not be revealed until sale is completed, i.e. should return a static image initially then be updated after mint
- Recommended way to setup tokenUri's in this manner is to deploy a react app with [HashRouter](https://v5.reactrouter.com/web/api/HashRouter) to IPFS, alternatively can use a centralized app, e.g. heds.io (the baseUri can be updated by the owner so can always move to IPFS later)

### Todo Before Deployment

- Add `baseUri`
- Set `withdrawAddress`
- Update `merkleRoot` if whitelist/proofs are re-generated
  - Only necessary if we want more up to date ownership snapshot (current snapshot taken Aug. 15th)
- Update `name` & `symbol` if wanted
- Set `startTime` and `premintStartTime`
- Remove corresponding todo comments from contract
- Final review after above steps are completed (Kaden)
- Create release (Kaden)
