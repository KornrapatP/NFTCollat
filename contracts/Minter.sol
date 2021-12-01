pragma solidity ^0.5.2;

import "./interfaces/IERC721AuctionData.sol";
import "./libraries/SafeMath.sol";
import "./libraries/Address.sol";
import "./interfaces/IERC721.sol";

contract Minter {
    using SafeMath for uint256;
    using Address for address;

    address public auctionNFTContract;
    uint256 public nextMint;

    modifier onlyEOA {
        require(msg.sender == tx.origin, "ONLY_EOA");
        _;
    }
    
    constructor(address _auctionNFTContract) public {
        auctionNFTContract = _auctionNFTContract;
        nextMint = 0;
    }
    
    // This function sends the collateral NFT from caller to this contract and mint an NFT on the auctionNFTContract to caller as proof of position.
    function depositNFTAndStartAuction(address NFTContractAddress, uint interestRate, uint256 tokenId) public onlyEOA returns (uint256) {
        require(NFTContractAddress != auctionNFTContract, "NO_LEVERAGE");
        IERC721(NFTContractAddress).transferFrom(msg.sender, address(this), tokenId);
        IERC721AuctionData(auctionNFTContract).mint(msg.sender, nextMint, NFTContractAddress, tokenId, interestRate);
        nextMint += 1;
    }
    
    // This function handles the bidding logic and modify appropriate fields in the auctionNFTContract. *Payable means this func can receive ETH
    function bidNFT(uint256 tokenId) public payable onlyEOA returns (bool) {
        IERC721AuctionData(auctionNFTContract).bid(tokenId, msg.value, msg.sender);
    }
    
    // This fucntion handles the withdrawing logic, modify appropriate fields in the auctionNFTContract, and send amountToWithdraw to caller.
    function withdrawBid(uint256 tokenId, uint256 amountToWithdraw) public onlyEOA returns (bool) {
        IERC721AuctionData(auctionNFTContract).withdraw(msg.sender, amountToWithdraw, tokenId);
        address(msg.sender).transfer(amountToWithdraw);
    }
    
    // This fucntion handles the borrowing logic, modify appropriate fields in the auctionNFTContract, and send amountToBorrow to caller.
    function borrow(uint tokenId, uint256 amountToBorrow, address lender) public onlyEOA returns (bool) {
        require(msg.sender == IERC721AuctionData(auctionNFTContract).ownerOf(tokenId), "NOT_OWNER");
        IERC721AuctionData(auctionNFTContract).borrow(amountToBorrow, tokenId, lender, block.timestamp);
        address(msg.sender).transfer(amountToBorrow);
    }
    
    // This function handles repaying logic, accepting the repay amount, burn the NFT on the auctionNFTContract, send collateral NFT to caller, and distribute money back to bidders.
    function repay(uint tokenId) payable public onlyEOA returns (bool) {
        uint256 amountToRepay = IERC721AuctionData(auctionNFTContract).getTotalDebt(tokenId);
        require(msg.value >= amountToRepay, "INSUFFICIENT_REPAY_AMOUNT");
        IERC721AuctionData(auctionNFTContract).repay(tokenId);
        address(msg.sender).transfer(msg.value - amountToRepay);
        IERC721(IERC721AuctionData(auctionNFTContract).getNFTContract(tokenId)).transferFrom(address(this), IERC721AuctionData(auctionNFTContract).ownerOf(tokenId), IERC721AuctionData(auctionNFTContract).getNFTTokenID(tokenId));
    }
    
    // This function handles liquidation logic, sends the collateral NFT to winning bidder, sends all money back to bidders, and burn NFT on the auctionNFTContract
    function liquidate(uint tokenId) public onlyEOA returns (bool) {
        uint256 amountToRepay = IERC721AuctionData(auctionNFTContract).getTotalDebt(tokenId);
        address winner = IERC721AuctionData(auctionNFTContract).getWinner(tokenId);
        uint256 amount = IERC721AuctionData(auctionNFTContract).getBidAmounts(tokenId, winner);
        uint256 liq = amountToRepay * 11 / 10;
        require(liq >= amount, "NOT_LIQUIDABLE");
        address(msg.sender).transfer(amount - amountToRepay);
        IERC721(IERC721AuctionData(auctionNFTContract).getNFTContract(tokenId)).transferFrom(address(this), winner, IERC721AuctionData(auctionNFTContract).getNFTTokenID(tokenId));
    }
}