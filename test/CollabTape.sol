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
    }

    function testMint(uint16 amount) public {
        (uint64 price, uint32 maxSupply, ,) = collabTape.saleConfig();
        vm.assume(amount <= maxSupply && amount > 0);

        _beginSale();

        uint valueToSend = uint(price) * uint(amount);

        collabTape.mint{value: valueToSend}(amount);
    }

    function testMintUpToMaxSupply() public {
        _beginSale();
        (uint64 price, uint32 maxSupply, ,) = collabTape.saleConfig();
        uint valueToSend = uint(price) * uint(maxSupply);
        collabTape.mint{value: valueToSend}(maxSupply);
    }

    function testTokenURI() public {
        collabTape.setBaseUri("ipfs://sup");

        _beginSale();
        (uint64 price, uint32 maxSupply, ,) = collabTape.saleConfig();
        uint valueToSend = uint(price) * uint(maxSupply);
        collabTape.mint{value: valueToSend}(maxSupply);

        string memory uri = collabTape.tokenURI(1);
        assertEq(uri, "ipfs://sup");
    }

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

    function onERC721Received(address, address, uint256, bytes memory) public virtual returns(bytes4) {
        return this.onERC721Received.selector;
    }

    fallback() external payable {}
    receive() external payable {}
}
