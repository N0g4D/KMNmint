// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@pinata/hardhat-plugin/contracts/interfaces/IPinata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./KMNA.sol";

contract KMNB is ERC721 {
    address public admin;
    uint256 public totalSupply;
    uint256 public maxMintPerTx = 5;

    //fee values
    uint256 public mintCostFirst15 = 0.00000005 ether;
    uint256 public mintCostRest = 0.0006 ether;
    uint256 public customNameCost = 0.0004 ether;

    //object of KMNA type (the address of the deployed contract) to check the balances of the users
    //private just to save gas :P
    KMNA private firstContract; 

    //associative array storing the custom names of the bought NFTs
    mapping(uint256 => string) public tokenNames; 

    //public address of the Pinata contract
    address public pinataContractAddress; 

    using Strings for uint256;

    event NFTMintedWithRules(address indexed owner, uint256 tokenId);
    event CustomNamePurchased(address indexed owner, uint256 tokenId, string name);
    event NameChangeRequested(address indexed owner, uint256 tokenId, string newName);
    event NFTMetadataUpdated(uint256 indexed tokenId, string newMetadataHash);

    constructor(address _firstContract, address _pinataContractAddress) ERC721("KMNtokenB", "KMNB") {
        admin = _msgSender();
        totalSupply = 40;
        firstContract = _firstContract;
        pinataContractAddress = _pinataContractAddress;
    }

    modifier onlyAdmin() {
        require(_msgSender() == admin, "Not authorized");
        _;
    }

    modifier onlyFirstContract() {
        require(firstContract.balanceOf(_msgSender())>0, "Must own NFT from first contract");
        _;
    }

    //modifier to allowe only the owner of the NFT to request the name change
    modifier onlyTokenOwner(uint256 tokenId) {
        require(_msgSender() == ownerOf(tokenId), "Not the owner of the NFT");
        _;
    }

    function mint() external payable onlyFirstContract {
        require(totalSupply > 0, "No more NFTs available");
        require(msg.value >= mintCostFirst15 || (msg.value >= mintCostRest && totalSupply > 25), "Insufficient funds");

        uint256 mintCost = (totalSupply > 25) ? mintCostRest : mintCostFirst15;
        _mint(_msgSender(), totalSupply);
        totalSupply--;

        if (msg.value > mintCost) {
            payable(_msgSender()).transfer(msg.value - mintCost);
        }

        emit NFTMintedWithRules(_msgSender(), totalSupply);
    }

    function purchaseCustomName(uint256 tokenId, string calldata name) external payable {
        require(ownerOf(tokenId) == _msgSender(), "Not the owner of the NFT");
        require(msg.value >= customNameCost, "Insufficient funds");

        tokenNames[tokenId] = name;

        if (msg.value > customNameCost) {
            payable(_msgSender()).transfer(msg.value - customNameCost);
        }

        emit CustomNamePurchased(_msgSender(), tokenId, name);
    }

    //loads a new json file on Pinata 
    function uploadJsonToPinata(string memory jsonData) public onlyAdmin{
        IPinata pinata = IPinata(pinataContractAddress);
        pinata.uploadJson(jsonData);
    }

    //requests a new name for a token
    function requestNameChange(uint256 tokenId, string calldata newName) external onlyTokenOwner(tokenId) {
        //stores the request
        nameChangeRequests[tokenId] = newName;

        emit NameChangeRequested(_msgSender(), tokenId, newName);
    }

    //approves a new custom name of a token
    function approveNameChange(uint256 tokenId) external onlyAdmin {
        string memory newName = nameChangeRequests[tokenId];

        //ensuring the request is not blank
        require(bytes(newName).length > 0, "Empty name change request");

        tokenNames[tokenId] = newName;
        delete nameChangeRequests[tokenId];

        emit CustomNamePurchased(ownerOf(tokenId), tokenId, newName);
    }

    //view function (doesn't alter the state of the BC) to get the request given the tokenId 
    function getNameChangeRequest(uint256 tokenId) external view returns (string memory) {
        return nameChangeRequests[tokenId];
    }

    function updateMetadata(uint256 tokenId, string calldata newMetadataHash) external onlyAdmin {
        require(_exists(tokenId), "Token does not exist");
        tokenMetadataHashes[tokenId] = newMetadataHash;
        emit NFTMetadataUpdated(tokenId, newMetadataHash);
    }
}
