//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "./ComponentNFT.sol";

struct AssemblableNFTSettings {
    string      name;           // ERC721: name
    string      symbol;         // ERC721: symbol
    address[]   payees;         // PaymentSplitter: payees 
    uint[]      shares;         // PaymentSplitter: shares
    string      itemsURI;       // ERC1155: URI of all ERC1155 items 

    string      baseURI;        // Prefix of tokenURI
    uint32      maxSupply;      // Max supply of ERC721 tokens
    uint        tokenPrice;     // Price of ERC721 tokens
    bytes4      featureSpace;   // Combination of max feature number of every attribute
}

/**
 @title An simple example of assemblable NFT
 */
contract AssemblableNFT is ERC721Enumerable, PaymentSplitter {

    using Strings for uint32;

    /// @dev Token counter
    uint private _counter;

    /// @notice NFT assembly number
    mapping (uint => bytes4) public assemblyCodeOf; 

    /// @dev Component contract
    ComponentInterface public componentContract;

    /// @dev Settings
    struct Settings {
        string      baseURI;        // Base URI of ERC721 tokens
        uint32      maxSupply;      // Max supply of ERC721 tokens
        uint        tokenPrice;     // Price of ERC721 tokens
        bytes4      featureSpace;   // Combination of max feature number of every attribute
    }
    Settings public settings;

    constructor(
        AssemblableNFTSettings memory initSettings
    )
        ERC721(initSettings.name, initSettings.symbol)
        PaymentSplitter(initSettings.payees, initSettings.shares)
    {
        _counter = 0;
        settings.baseURI = initSettings.baseURI;
        settings.maxSupply = initSettings.maxSupply;
        settings.tokenPrice = initSettings.tokenPrice;
        settings.featureSpace = initSettings.featureSpace;
        componentContract = ComponentInterface(address(new ComponentNFT(initSettings.itemsURI)));

        console.log("Deploying a Assemblable NFT");
        console.log("    name:", name());
        console.log("    symbol:", symbol());
        console.log("    baseURI:", settings.baseURI);
        console.log("    maxSupply:", settings.maxSupply);
        console.log("    tokenPrice:", settings.tokenPrice);
    }

    /// @notice Use assembly number to map URI instead of tokenId
    function tokenURI(uint tokenId) public view override returns (string memory) {
        require(
            _exists(tokenId),
            "nonexistent token"
        );
        return string(abi.encodePacked(settings.baseURI, uint32(assemblyCodeOf[tokenId]).toHexString(4)));
    }

    /// @notice Mint token with some random assembly number
    function mint() external payable {
        require(
            _counter < settings.maxSupply,
            "mint: sold out"
        );
        require(
            !Address.isContract(_msgSender()),
            "mint: from contract"
        );
        require(
            msg.value >= settings.tokenPrice,
            "mint: not enough fund"
        );
        _safeMint(_msgSender(), _counter);
        
        // for example blockhash as assembly number
        bytes4 featureSpace = settings.featureSpace;
        bytes4 assemblyCode = bytes4(blockhash(block.number-1) ^ bytes20(_msgSender()));
        bytes4 assemblyCodeAfter = 0x00000000;
        for (uint8 i = 0; i < 4; i++) {
            assemblyCodeAfter >>= 8;
            assemblyCodeAfter |= bytes1(uint8(assemblyCode[i])%uint8(featureSpace[i]));
        }
        assemblyCodeOf[_counter] = assemblyCodeAfter;
        _counter++;
    }

    /// @notice Disassemble an NFT and get component NFTs
    function disassemble(uint tokenId, bytes4 componentCode) external {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "disassemble: not owner"
        );

        bytes4 assemblyCode = assemblyCodeOf[tokenId];
        bytes4 assemblyCodeAfter = 0x00000000;
        bytes4 mask = 0xFF000000;
        for (uint8 i = 0; i < 4; i++) {
            if (componentCode[i] == 0x00) {
                assemblyCodeAfter |= assemblyCode & mask;
            }
            else if (assemblyCode[i] != componentCode[i]) {
                revert(
                    "disassemble: not disassemblable"
                );
            }
            mask >>= 8;
        }
        assemblyCodeOf[tokenId] = assemblyCodeAfter;

        componentContract.mint(_msgSender(), componentCode);
    }

    /// @dev Assemble an NFT with component NFTs
    function assemble(uint tokenId, bytes4 componentCode) external {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "assemble: not owner"
        );

        bytes4 assemblyCode = assemblyCodeOf[tokenId];
        bytes4 assemblyCodeAfter = 0x00000000;
        bytes4 mask = 0xFF000000;
        for (uint8 i = 0; i < 4; i++) {
            if (componentCode[i] == 0x00) {
                assemblyCodeAfter |= assemblyCode & mask;
            }
            else {
                assemblyCodeAfter |= componentCode & mask;
            }
            mask >>= 8;
        }
        assemblyCodeOf[tokenId] = assemblyCodeAfter;

        componentContract.burn(_msgSender(), componentCode);
    }
}
