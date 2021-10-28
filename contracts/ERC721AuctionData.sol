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

    struct auction {
        uint256 winningBid;
        address winner;
        mapping(address => uint256) bidders;
        uint256 borrowAmount;
        address NFTContract;
        uint256 NFTTokenID;
        uint256 interestRate; // per Second, unit 10^-10 FIXME
        uint256 timeStamp;
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
    function bid(uint256 tokenId, uint256 amountETH, address bidder) public onlyMinter exists(tokenId) returns (bool) {
        if (auctionData[tokenId].winningBid < amountETH) {
            auctionData[tokenId].winner = bidder;
            auctionData[tokenId].winningBid = amountETH;
        }
        auctionData[tokenId].bidders[bidder] = auctionData[tokenId].bidders[bidder].add(amountETH);
        return true;
    }

    function borrow(uint256 amount, uint256 tokenId, uint256 timestamp) public onlyMinter exists(tokenId) returns (bool) {
        auctionData[tokenId].borrowAmount = amount;  
        auctionData[tokenId].timeStamp = timestamp;
        return true;
    }

    function withdraw(address to, uint256 newBalance, uint256 tokenId) public onlyMinter exists(tokenId) returns (bool) {
        auctionData[tokenId].bidders[to] = newBalance;
        return true;
    }

    // burn this NFT
    function repay(uint256 tokenId) public onlyMinter exists(tokenId) returns (bool) {
        // _; //FIXME
    }
    
    function getMinter() public view returns (address) {
        return minter;
    }
    function getWinner(uint256 tokenId) public view returns (address) {
        return auctionData[tokenId].winner;
    }
    function getBidAmounts(uint256 tokenId, address bidder) public view returns (uint256) {
        return auctionData[tokenId].bidders[bidder];
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
    function getInterestRate(uint256 tokenId) public view returns (uint256) {
        return auctionData[tokenId].interestRate;
    }
    function getTimestamp(uint256 tokenId) public view returns (uint256) {
        return auctionData[tokenId].timeStamp;
    }
}