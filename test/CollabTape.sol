// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "forge-std/Test.sol";

contract CollabTapeTest is Test {
    CollabTape collabTape;

    function setUp() public {
        collabTape = new CollabTape();
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns(bytes4) {
        return this.onERC721Received.selector;
    }

    fallback() external payable {}
    receive() external payable {}
}
