pragma solidity ^0.5.2;

import "./ERC721.sol";
import "./interfaces/IERC721AuctionData.sol";

/**
 * @title ERC721AuctionData
 * @dev ERC721 minting logic
 */
contract ERC721AuctionData is ERC721, IERC721AuctionData {
    using SafeMath for uint256;
    using Address for address;

    address private minter;
    address public minterSetter;

    struct bidData {
        uint256 amount;
        uint256 interest;
    }

    struct auction {
        address NFTContract;
        uint256 NFTTokenID;
        address winner;
        mapping(address => bidData) bidders;
        uint256 borrowAmount;
        uint256 timeStamp;
        uint256 totalAmount;
    }

    // Maps tokenID to auction object
    mapping(uint256 => auction) private auctionData;

    modifier onlyMinter {
        require(msg.sender == minter, "NOT_MINTER");
        _;
    }

    modifier onlyMinterSetter {
        require(msg.sender == minterSetter, "NOT_MINTER_SETTER");
        _;
    }

    modifier exists(uint256 tokenId) {
        require(_exists(tokenId), "NO_SUCH_TOKEN");
        _;
    }

    constructor(address _minter, address _minterSetter) ERC721() public {
        minter = _minter;
        minterSetter = _minterSetter;
    }
    
    function setMinter(address _minter) public onlyMinterSetter {
        minter = _minter;
    }

    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param tokenId The token id to mint.
     * @param addressNFT The address of collateral NFT contract
     * @param tokenIdNFT The tokenID of collateral NFT
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 tokenId, address addressNFT, uint256 tokenIdNFT) public onlyMinter returns (bool) {
        _mint(to, tokenId);
        auctionData[tokenId].NFTContract = addressNFT;
        auctionData[tokenId].NFTTokenID = tokenIdNFT;
        return true;
    }

    // minter contract should pass in the correct variables
    function bid(uint256 tokenId, uint256 amountETH, uint256 interestRate, address bidder) public onlyMinter exists(tokenId) returns (bool) {
        require(auctionData[tokenId].winner != bidder, "CHANGES_NOT_ALLOW");
        auctionData[tokenId].bidders[bidder].amount = auctionData[tokenId].bidders[bidder].amount.add(amountETH);
        auctionData[tokenId].bidders[bidder].interest = interestRate;
        return true;
    }

    function borrow(uint256 amount, uint256 tokenId, address lender, uint256 timestamp) public onlyMinter exists(tokenId) returns (bool) {
        require((lender == auctionData[tokenId].winner && 11*(auctionData[tokenId].borrowAmount + amount)/10 <= auctionData[tokenId].bidders[lender].amount) || (auctionData[tokenId].winner == address(0) && 11*amount/10 <= auctionData[tokenId].bidders[lender].amount), "ILLEGAL_LOAN");
        if (lender == auctionData[tokenId].winner) {
            auctionData[tokenId].borrowAmount += amount;
        } else {
            auctionData[tokenId].winner = lender;
            auctionData[tokenId].borrowAmount = amount;
        }
        return true;
    }

    function withdraw(address to, uint256 amountToWithdraw, uint256 tokenId) public onlyMinter exists(tokenId) returns (bool) {
        auctionData[tokenId].bidders[to].amount = auctionData[tokenId].bidders[to].amount.sub(amountToWithdraw);
        return true;
    }

    // burn this NFT
    function repay(uint256 tokenId) public onlyMinter exists(tokenId) returns (bool) {
        auctionData[tokenId].winner = address(1);
        auctionData[tokenId].borrowAmount = 0;
        return true;
    }
    
    function getMinter() public view returns (address) {
        return minter;
    }
    function getWinner(uint256 tokenId) public view returns (address) {
        return auctionData[tokenId].winner;
    }
    function getBidAmounts(uint256 tokenId, address bidder) public view returns (uint256) {
        return auctionData[tokenId].bidders[bidder].amount;
    }
    function getBidInterest(uint256 tokenId, address bidder) public view returns (uint256) {
        return auctionData[tokenId].bidders[bidder].interest;
    }
    function getBorrowAmount(uint256 tokenId) public view returns (uint256) {
        return auctionData[tokenId].borrowAmount;
    }
    function getNFTContract(uint256 tokenId) public view returns (address) {
        return auctionData[tokenId].NFTContract;
    }
    function getNFTTokenID(uint256 tokenId) public view returns (uint256) {
        return auctionData[tokenId].NFTTokenID;
    }
    function getTimestamp(uint256 tokenId) public view returns (uint256) {
        return auctionData[tokenId].timeStamp;
    }
}