pragma solidity ^0.5.2;

interface INFTXMarketplaceZap {
    function mintAndSell721(
    uint256 vaultId, 
    uint256[] calldata ids, 
    uint256 minWethOut, 
    address[] calldata path,
    address to
  ) external;
}