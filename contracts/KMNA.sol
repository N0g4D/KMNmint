// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//OpenZeppelin integration: taking the standard model of a basic ERC721 token contract
import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; 

contract KMNA is ERC721 { //extending the OZ contract
    address public admin; //
    uint256 public totalSupply;
    mapping(address => bool) public hasMinted;

    //example of an event. An event is a signal sent from the contract and visible outside (on Etherscan for example) 
    // as a confirmation of something happened. It's seeable analyzing the emitting transaction 
    event NFTMinted(address indexed owner, uint256 tokenId); 

    //mints with the example value of total supply of 100
    constructor() ERC721("KMNtokenA", "KMNA") { 
        admin = _msgSender(); //using the function from the context library to avoid reentrance attacks
        totalSupply = 100;
    }

    //example of a modifier. A modifier is a property applicable to a function to run some instructions before the body
    modifier onlyAdmin() {
        require(_msgSender() == admin, "Not authorized");
        _;
    }

    function mint() external {
        require(!hasMinted[_msgSender()], "Already minted"); //limits 1 NFT per wallet
        require(totalSupply > 0, "No more NFTs available"); //checks if all of the 40 NFTs have already been printed

        _mint(_msgSender(), totalSupply); //ERC721.sol mint function
        hasMinted[_msgSender()] = true;
        totalSupply--;

        emit NFTMinted(_msgSender(), totalSupply);
    }
}
