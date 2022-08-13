// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "ERC721A/ERC721A.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

error FailedTransfer();
error InsufficientFunds();
error ExceedsMaxSupply();
error BeforeSaleStart();

contract CollabTape is ERC721A, Ownable {
    struct SaleConfig {
        uint64 price;
        uint32 maxSupply;
        uint32 startTime;
        uint32 premintStartTime;
    }

    /// @notice NFT sale data
    /// @dev Sale data packed into single storage slot
    SaleConfig public saleConfig;

    // TODO: Add baseUri
    string public baseUri = "";
    // TODO: Update withdrawAddress
    address public withdrawAddress = 0xBEeFbeefbEefbeEFbeEfbEEfBEeFbeEfBeEfBeef;
    // TODO: Update merkleRoot
    bytes32 public constant merkleRoot = 0x0;

    // TODO: Update name/symbol if wanted
    constructor() ERC721A("collabTAPE", "CLBT") {
        saleConfig.price = 0.1 ether;
        saleConfig.maxSupply = 132;
        // TODO: Set startTime
        saleConfig.startTime = 0;
        // TODO: Set premintStartTime
        saleConfig.premintStartTime = 0;
    }

    /// @notice Mint a HedsTape token
    /// @param _amount Number of tokens to mint
    function mint(uint _amount) external payable {
        SaleConfig memory config = saleConfig;
        uint _price = uint(config.price);
        uint _maxSupply = uint(config.maxSupply);
        uint _startTime = uint(config.startTime);

        if (_amount * _price != msg.value) revert InsufficientFunds();
        if (_nextTokenId() + _amount > _maxSupply) revert ExceedsMaxSupply();
        if (block.timestamp < _startTime) revert BeforeSaleStart();

        _safeMint(msg.sender, _amount);
    }

    /// @notice Return tokenURI for a given token
    /// @dev Same tokenURI returned for all tokenId's
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (0 == _tokenId || _tokenId > _nextTokenId() - 1) revert
            URIQueryForNonexistentToken();
        return baseUri;
    }

    /// @notice Update baseUri - must be contract owner
    function setBaseUri(string calldata _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    /// @notice Update withdrawAddress - must be contract owner
    function setWithdrawAddress(address _withdrawAddress) external onlyOwner {
        withdrawAddress = _withdrawAddress;
    }

    /// @notice Update sale start time - must be contract owner
    function updateStartTime(uint32 _startTime) external onlyOwner {
        saleConfig.startTime = _startTime;
    }

    /// @notice Update max supply - must be contract owner
    function updateMaxSupply(uint32 _maxSupply) external onlyOwner {
        saleConfig.maxSupply = _maxSupply;
    }

    /// @notice Update premint start time - must be contract owner
    function updatePremintStartTime(uint32 _premintStartTime) external onlyOwner {
        saleConfig.premintStartTime = _premintStartTime;
    }

    /// @notice Withdraw contract balance - must be contract owner
    function withdraw() external onlyOwner {
        (bool success, ) = payable(withdrawAddress).call{value: address(this).balance}("");
        if (!success) revert FailedTransfer();
    }
}
