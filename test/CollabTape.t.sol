// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "forge-std/Test.sol";
import "../src/CollabTape.sol";

contract CollabTapeTest is Test {
    CollabTape collabTape;

    function setUp() public {
        collabTape = new CollabTape();
    }

    function _beginSale() internal {
        collabTape.updateStartTime(1650000000);
        vm.warp(1650000000);
    }

    function _beginPremint() internal {
        collabTape.updatePremintStartTime(1650000000);
        vm.warp(1650000000);
    }

    ////////////////////////////////////////////////////////////////
    /*                AUTHORIZED FUNCTION TESTS                   */
    ////////////////////////////////////////////////////////////////

    function testUpdateStartTimeAsOwner() public {
        collabTape.updateStartTime(1650000000);
        (, , uint32 newStartTime, ) = collabTape.saleConfig();

        assertEq(newStartTime, 1650000000);
    }

    function testCannotUpdateStartTimeAsNotOwner() public {
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        vm.prank(address(0));
        collabTape.updateStartTime(1650000000);
    }

    function testUpdatePremintStartTimeAsOwner() public {
        collabTape.updatePremintStartTime(1650000000);
        (, , , uint32 newPremintStartTime) = collabTape.saleConfig();

        assertEq(newPremintStartTime, 1650000000);
    }

    function testCannotUpdatePremintStartTimeAsNotOwner() public {
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        vm.prank(address(0));
        collabTape.updatePremintStartTime(1650000000);
    }

    function testUpdateMaxSupplyAsOwner() public {
        collabTape.updateMaxSupply(1650000000);
        (, uint32 newMaxSupply, ,) = collabTape.saleConfig();

        assertEq(newMaxSupply, 1650000000);
    }

    function testCannotUpdateMaxSupplyAsNotOwner() public {
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        vm.prank(address(0));
        collabTape.updateMaxSupply(1650000000);
    }

    function testSetBaseUriAsOwner() public {
        collabTape.setBaseUri("new base uri");
        string memory newBaseUri = collabTape.baseUri();
        assertEq(newBaseUri, "new base uri");
    }

    function testCannotSetBaseUriAsNotOwner() public {
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        vm.prank(address(0));
        collabTape.setBaseUri("new base uri");
    }

    function testUpdateWithdrawAddressAsOwner() public {
        collabTape.setWithdrawAddress(address(0xbeef));
        address newWithdrawAddress = collabTape.withdrawAddress();
        assertEq(newWithdrawAddress, address(0xbeef));
    }

    function testCannotUpdateWithdrawAddressAsNotOwner() public {
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        vm.prank(address(0));
        collabTape.setWithdrawAddress(address(0xbeef));
    }

    ////////////////////////////////////////////////////////////////
    /*                        MINT TESTS                          */
    ////////////////////////////////////////////////////////////////

    function testCannotMintBeforeStartTime() public {
        collabTape.updateStartTime(1650000000);
        vm.warp(1649999999);
        (uint64 price, , ,) = collabTape.saleConfig();
        vm.expectRevert(abi.encodeWithSignature("BeforeSaleStart()"));
        collabTape.mint{value: price}(1);
    }

    function testCannotMintInsufficientFunds() public {
        _beginSale();
        (uint64 price, , ,) = collabTape.saleConfig();
        vm.expectRevert(abi.encodeWithSignature("InsufficientFunds()"));
        collabTape.mint{value: price - 1}(1);
    }

    function testCannotMintBeyondMaxSupply() public {
        _beginSale();
        (uint64 price, uint32 maxSupply, ,) = collabTape.saleConfig();
        uint valueToSend = uint(price) * uint(maxSupply + 1);
        vm.expectRevert(abi.encodeWithSignature("ExceedsMaxSupply()"));
        collabTape.mint{value: valueToSend}(maxSupply + 1);
    }

    function testMint() public {
        _beginSale();
        (uint64 price, , ,) = collabTape.saleConfig();
        collabTape.mint{value: price}(1);

        uint256 balance = collabTape.balanceOf(address(this));
        assertEq(balance, 1);
    }

    function testMint(uint16 amount) public {
        (uint64 price, uint32 maxSupply, ,) = collabTape.saleConfig();
        vm.assume(amount <= maxSupply && amount > 0);

        _beginSale();

        uint valueToSend = uint(price) * uint(amount);

        collabTape.mint{value: valueToSend}(amount);

        uint256 balance = collabTape.balanceOf(address(this));
        assertEq(balance, amount);
    }

    function testMintUpToMaxSupply() public {
        _beginSale();
        (uint64 price, uint32 maxSupply, ,) = collabTape.saleConfig();
        uint valueToSend = uint(price) * uint(maxSupply);
        collabTape.mint{value: valueToSend}(maxSupply);

        uint256 balance = collabTape.balanceOf(address(this));
        assertEq(balance, maxSupply);
    }

    ////////////////////////////////////////////////////////////////
    /*                      WITHDRAW TESTS                        */
    ////////////////////////////////////////////////////////////////

    function testWithdraw() public {
        _beginSale();
        (uint64 price, uint32 maxSupply, ,) = collabTape.saleConfig();
        uint amount = uint(price) * uint(maxSupply);
        address withdrawAddress = collabTape.withdrawAddress();
        collabTape.mint{value: amount}(maxSupply);

        assertEq(address(collabTape).balance, amount);

        uint balanceBefore = address(withdrawAddress).balance;
        collabTape.withdraw();
        uint balanceAfter = address(withdrawAddress).balance;

        assertEq(balanceAfter - balanceBefore, amount);
    }

    function testCannotWithdrawNotOwner() public {
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        vm.prank(address(1));
        collabTape.withdraw();
    }

    ////////////////////////////////////////////////////////////////
    /*                      TOKENURI TESTS                        */
    ////////////////////////////////////////////////////////////////

    function testTokenURI() public {
        collabTape.setBaseUri("ipfs://sup");

        _beginSale();
        (uint64 price, uint32 maxSupply, ,) = collabTape.saleConfig();
        uint valueToSend = uint(price) * uint(maxSupply);
        collabTape.mint{value: valueToSend}(maxSupply);

        string memory uri = collabTape.tokenURI(1);
        assertEq(uri, "ipfs://sup");
    }

    ////////////////////////////////////////////////////////////////
    /*                       PREMINT TESTS                        */
    ////////////////////////////////////////////////////////////////

    bytes32[] proof = [bytes32(0x00000000000000000000000096acf191c0112806f9709366bad77642b99b21a9),bytes32(0x2b59fca3b3910643b3b3ff3b9a17f517387be19c38774b28d7842ac71b4ec404),bytes32(0xba4f04023db136f4d00c8558a8853be50bf7645ceb4e7c41e09c250b12bfea32),bytes32(0x644b4462efc7ff5d834399fffab9529bc1cbcc1aeaa9b1d443392d7e1b4739e2),bytes32(0x01e00cc1656efe5cd6c96e9f949f4b7cf1a2dfd528c1e1b1ab3e95daef92cdf9),bytes32(0x7d894bde8018c314d640a78ae2cf6440f4bee00b901c59654052f5b810a0dcd4),bytes32(0x7a832f703c19cbfe8609d789fef0a5ad07266c1914cb8bc0fbc52fd1d50f082e),bytes32(0xc5f2aa4f53098f9e78441d3764a69a4a2cbd495765d49c02308d528b5717e357)];
    address whitelistedAddress = 0x958E2EBB40147DFeE318aB640D9f0e66783eC62d;

    function testWhitelistedAddressCanPremint() public {
        _beginPremint();
        vm.prank(whitelistedAddress);
        collabTape.preMint(proof);

        uint256 balance = collabTape.balanceOf(whitelistedAddress);
        assertEq(balance, 1);
    }

    function testNonWhitelistedAddressCannotPremint() public {
        _beginPremint();
        vm.prank(address(0xBEEF));

        vm.expectRevert(InvalidProof.selector);
        collabTape.preMint(proof);
    }

    function testWhitelistedAddressCannotPremintTwice() public {
        _beginPremint();
        vm.prank(whitelistedAddress);
        collabTape.preMint(proof);

        vm.expectRevert(AlreadyClaimed.selector);
        vm.prank(whitelistedAddress);
        collabTape.preMint(proof);
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual returns(bytes4) {
        return this.onERC721Received.selector;
    }

    fallback() external payable {}
    receive() external payable {}
}
