// src/app.controller.ts
import { Controller, Post, HttpException, HttpStatus } from '@nestjs/common';
import { AppService } from './app.service';
import { ethers } from 'ethers';
import axios from 'axios';

@Controller()
export class AppController {
  private readonly provider: ethers.providers.JsonRpcProvider;
  private readonly wallet: ethers.Wallet;
  private readonly mintKMNAContractAddress = 'YOUR_KMNA_CONTRACT_ADDRESS'; 
  private readonly backendWalletPrivateKey = 'YOUR_BACKEND_WALLET_PRIVATE_KEY'; 

  constructor(private readonly appService: AppService) {
    this.provider = new ethers.providers.JsonRpcProvider('YOUR_RPC_ENDPOINT'); //endpoint json-rpc of Sepolia
    this.wallet = new ethers.Wallet(this.backendWalletPrivateKey, this.provider);
  }

  @Post('mint-nft')
  async mintNFT() {
    try {
      // Call smart contract 1 to mint NFT
      const mintKMNAContract = new ethers.Contract(this.mintKMNAContractAddress, ['function mint()'], this.wallet);
      const transaction = await mintKMNAContract.mint();

      // Handle transaction fees
      const transactionReceipt = await transaction.wait();
      const gasUsed = transactionReceipt.gasUsed.mul(transaction.gasPrice);
      const feeAmount = ethers.utils.formatEther(gasUsed);

      // Log or process the fee amount as needed
      console.log(`Transaction fee: ${feeAmount} ETH`);

      return { success: true, transactionHash: transaction.hash };
    } catch (error) {
      console.error('Error minting NFT:', error);
      throw new HttpException('Failed to mint NFT', HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

  @Post('update-metadata')
  async updateMetadata() {
    try {
      // Listen to events on KMNB smart contract
      const mintNFTWithRulesContractAddress = 'YOUR_MINT_NFT_WITH_RULES_CONTRACT_ADDRESS'; address of KMNB
      const mintNFTWithRulesContract = new ethers.Contract(
        mintNFTWithRulesContractAddress,
        ['event NFTMetadataUpdated(uint256 tokenId, string newMetadataUrl)'],
        this.provider
      );

      mintNFTWithRulesContract.on('NFTMetadataUpdated', async (tokenId: number, newMetadataUrl: string) => {

        const pinataApiKey = 'YOUR_PINATA_API_KEY'; 
        const pinataApiSecret = 'YOUR_PINATA_API_SECRET'; 
        const pinataEndpoint = 'https://api.pinata.cloud/pinning/pinJSONToIPFS';

        const pinataMetadata = {
          tokenId,
          newMetadataUrl,
        };

        const pinataResponse = await axios.post(
          pinataEndpoint,
          pinataMetadata,
          {
            headers: {
              'Content-Type': 'application/json',
              'pinata_api_key': pinataApiKey,
              'pinata_secret_api_key': pinataApiSecret,
            },
          }
        );

        const pinataIpfsHash = pinataResponse.data.IpfsHash;

        // Log or process the Pinata IPFS hash as needed
        console.log(`Updated Pinata metadata IPFS hash: ${pinataIpfsHash}`);

        // Update metadata on smart contract
        const mintNFTWithRulesWallet = new ethers.Wallet(this.backendWalletPrivateKey, this.provider);
        const mintNFTWithRulesContractWithSigner = mintNFTWithRulesContract.connect(mintNFTWithRulesWallet);

        const transaction = await mintNFTWithRulesContractWithSigner.updateMetadata(tokenId, pinataIpfsHash);

        // Wait for the transaction to be mined
        await transaction.wait();

        return { success: true, tokenId, newMetadataUrl, pinataIpfsHash, transactionHash: transaction.hash };
      });

      return { success: true };
    } catch (error) {
      console.error('Error updating metadata:', error);
      throw new HttpException('Failed to update metadata', HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }
}
