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
        collabTape.setBaseUri("ipfs://sup/");

        _beginSale();
        (uint64 price, uint32 maxSupply, ,) = collabTape.saleConfig();
        uint valueToSend = uint(price) * uint(maxSupply);
        collabTape.mint{value: valueToSend}(maxSupply);

        string memory uri = collabTape.tokenURI(1);
        assertEq(uri, "ipfs://sup/1");
    }

    ////////////////////////////////////////////////////////////////
    /*                       PREMINT TESTS                        */
    ////////////////////////////////////////////////////////////////

    bytes32[] proof = [bytes32(0x000000000000000000000000958e2ebb40147dfee318ab640d9f0e66783ec62d),bytes32(0x6c3e5d73a64070ce4e3e5d8915fbd4aa3fd21c0f519a6b31b6a30d10eb3e5bc0),bytes32(0xa4ee306409dddb6a3557ed21cb29e806382d9533ddf9f26e24cb38819d5b275a),bytes32(0xa2c6d1908296043321076341c8f9b8119cdaeccb018ddc62f71682acc130320e),bytes32(0x3a3d802ddb0d376a837c325b37bf8feebc268d8887cde3b9da705c84aff1b88d),bytes32(0x6dcaed559be101b0090aa03d83ceb6381739b9cf704a0226d153941835125ffc),bytes32(0x15d14afc29ff3ac81335e6c572420456da1525696994369d0a8fd9c78e10a7c1),bytes32(0xa6ded97ea47db44c1c391e0352539baefbb5155b54aed4a0ccae909561794253)];
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

    function testCannotPremintBeforeStartTime() public {
        collabTape.updatePremintStartTime(1650000000);
        vm.warp(1649999999);
        vm.expectRevert(abi.encodeWithSignature("BeforePremintStart()"));
        vm.prank(whitelistedAddress);
        collabTape.preMint(proof);
    }

    function testCannotPremintBeyondMaxSupply() public {
        _beginSale();
        (uint64 price, uint32 maxSupply, ,) = collabTape.saleConfig();
        uint valueToSend = uint(price) * uint(maxSupply);
        collabTape.mint{value: valueToSend}(maxSupply);

        _beginPremint();
        vm.expectRevert(ExceedsMaxSupply.selector);
        vm.prank(whitelistedAddress);
        collabTape.preMint(proof);
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual returns(bytes4) {
        return this.onERC721Received.selector;
    }

    fallback() external payable {}
    receive() external payable {}
}
