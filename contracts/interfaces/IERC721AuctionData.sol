pragma solidity ^0.5.2;

import "./IERC721.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721AuctionData is IERC721 {
    
    function getMinter() public view returns (address);
    
    function getWinningBid(uint256 tokenId) public view returns (uint256);
    
    function getWinner(uint256 tokenId) public view returns (address);
    function getBidAmounts(uint256 tokenId, address bidder) public view returns (uint256);
    function getBorrowAmount(uint256 tokenId) public view returns (uint256);
    function getNFTContract(uint256 tokenId) public view returns (address);
    function getNFTTokenID(uint256 tokenId) public view returns (uint256);
    function getInterestRate(uint256 tokenId) public view returns (uint256);
    function getTimestamp(uint256 tokenId) public view returns (uint256);

    function mint(address to, uint256 tokenId, address addressNFT, uint256 tokenIdNFT) public returns (bool);

    // minter contract should pass in the correct variables
    function bid(uint256 tokenId, uint256 amountETH, address bidder) public returns (bool);

    function borrow(uint256 amount, uint256 tokenId, uint256 timestamp) public returns (bool);

    function withdraw(address to, uint256 newBalance, uint256 tokenId) public returns (bool);

    function repay(uint256 tokenId) public returns (bool);
}