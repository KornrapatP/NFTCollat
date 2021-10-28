pragma solidity ^0.5.2;

import "./interfaces/IERC721AuctionData.sol";
import "./libraries/SafeMath.sol";
import "./libraries/Address.sol";

contract Minter {
    using SafeMath for uint256;
    using Address for address;

    address public auctionNFTContract;
    
    constructor(address _auctionNFTContract) public{
        auctionNFTContract = _auctionNFTContract;
    }
    
    // This function sends the collateral NFT from caller to this contract and mint an NFT on the auctionNFTContract to caller as proof of position.
    function depositNFTAndStartAuction(address NFTContractAddress, uint256 tokenId) public returns (uint256) {
        
    }
    
    // This function handles the bidding logic and modify appropriate fields in the auctionNFTContract. *Payable means this func can receive ETH
    function bidNFT(uint256 tokenId) public payable returns (bool) {
        
    }
    
    // This fucntion handles the withdrawing logic, modify appropriate fields in the auctionNFTContract, and send amountToWithdraw to caller.
    function withdrawBid(uint256 tokenId, uint256 amountToWithdraw) public returns (bool) {
        
    }
    
    // This fucntion handles the borrowing logic, modify appropriate fields in the auctionNFTContract, and send amountToBorrow to caller.
    function borrow(uint tokenId, uint256 amountToBorrow) public returns (bool) {
        
    }
    
    // This function handles repaying logic, accepting the repay amount, burn the NFT on the auctionNFTContract, send collateral NFT to caller, and distribute money back to bidders.
    function repay(uint tokenId) payable public returns (bool) {
        
    }
    
    // This function handles liquidation logic, sends the collateral NFT to winning bidder, sends all money back to bidders, and burn NFT on the auctionNFTContract
    function liquidate(uint tokenId) public returns (bool) {
        
    }
}