pragma solidity ^0.5.2;

import "./interfaces/IERC721AuctionData.sol";
import "./libraries/SafeMath.sol";
import "./libraries/Address.sol";
import "./interfaces/IERC721.sol";
import "./interfaces/IUniswapPair.sol";
import "./interfaces/INFTXMarketplaceZap.sol";

contract Minter {
    using SafeMath for uint256;
    using Address for address;

    address public auctionNFTContract;
    uint256 public nextMint;
    address public constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    address public constant KLOWN = 0xbB6F7D658c792bFf370947D31888048b685D42d4; // demo

    modifier onlyEOA {
        require(msg.sender == tx.origin, "ONLY_EOA");
        _;
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
    
    constructor(address _auctionNFTContract) public {
        auctionNFTContract = _auctionNFTContract;
        nextMint = 0;
    }
    
    // This function sends the collateral NFT from caller to this contract and mint an NFT on the auctionNFTContract to caller as proof of position.
    function depositNFTAndStartAuction(address NFTContractAddress, uint interestRate, uint256 tokenId, uint256 loanAmount) public onlyEOA returns (uint256) {
        require(NFTContractAddress != auctionNFTContract, "NO_LEVERAGE");
        IERC721(NFTContractAddress).transferFrom(msg.sender, address(this), tokenId);
        IERC721AuctionData(auctionNFTContract).mint(msg.sender, nextMint, NFTContractAddress, tokenId, interestRate, loanAmount);
        nextMint += 1;
        if (loanAmount != 0) {
            // Look up vault on NFTX

            // GET price to determine loan
            //demo
            address KLOWN_WETH = 0x9d951AC1f38307A0cbc331a491f84213c53aF11A;
            (uint256 r0, uint256 r1, uint32 time) = IUniswapV2Pair(KLOWN_WETH).getReserves();
            uint256 amountETH = getAmountOut(1000000000000000000, r0, r1);
            amountETH = amountETH / 10 * 8;
            require(loanAmount <= amountETH, "ILLEGAL_LOAN");
            address(msg.sender).transfer(loanAmount);
        }
    }
    
    // This function handles the bidding logic and modify appropriate fields in the auctionNFTContract. *Payable means this func can receive ETH
    function bidNFT(uint256 tokenId) public payable onlyEOA returns (bool) {
        IERC721AuctionData(auctionNFTContract).bid(tokenId, msg.value, msg.sender);
    }
    
    // This fucntion handles the withdrawing logic, modify appropriate fields in the auctionNFTContract, and send amountToWithdraw to caller.
    function withdrawBid(uint256 tokenId) public onlyEOA returns (bool) {
        require(msg.sender != IERC721AuctionData(auctionNFTContract).getWinner(tokenId), "POSITION_LOCK");
        uint256 amountToWithdraw = IERC721AuctionData(auctionNFTContract).withdraw(msg.sender, tokenId);
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
        IERC721AuctionData(auctionNFTContract).repay(tokenId, amountToRepay);
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

    function repayInstant(uint tokenId) public payable onlyEOA returns (bool) {
        uint256 amountDue = IERC721AuctionData(auctionNFTContract).getDebtShareinETH(tokenId);
        require(msg.value >= amountDue, "INSUFFICIENT_AMOUNT");
        IERC721AuctionData(auctionNFTContract).repayInstant(tokenId);
        IERC721(IERC721AuctionData(auctionNFTContract).getNFTContract(tokenId)).transferFrom(address(this), IERC721AuctionData(auctionNFTContract).ownerOf(tokenId), IERC721AuctionData(auctionNFTContract).getNFTTokenID(tokenId));
    }

    function liquidateInstant(uint tokenId) public onlyEOA returns (bool) {
        address KLOWN_WETH = 0x9d951AC1f38307A0cbc331a491f84213c53aF11A;
        (uint256 r0, uint256 r1, uint32 time) = IUniswapV2Pair(KLOWN_WETH).getReserves();
        uint256 amountETH = getAmountOut(9500000000000000000, r0, r1);
        uint loanAmount = IERC721AuctionData(auctionNFTContract).getDebtShareinETH(tokenId);
        require(loanAmount * 11 / 10 >= amountETH, "NOT_LIQUIDABLE");
        uint256 NFTId = IERC721AuctionData(auctionNFTContract).getNFTTokenID(tokenId);
        IERC721(IERC721AuctionData(auctionNFTContract).getNFTContract(tokenId)).approve(0x36B799160CdC2d9809d108224D1967cC9B7d321C, NFTId);
        uint256[] memory nftContract = new uint[](1);
        nftContract[0] = NFTId;
        address[] memory path = new address[](2);
        path[0] = KLOWN;
        path[1] = WETH;
        INFTXMarketplaceZap(0x36B799160CdC2d9809d108224D1967cC9B7d321C).mintAndSell721(7, nftContract, amountETH, path, address(this));
        address(msg.sender).transfer(amountETH - loanAmount);
        IERC721AuctionData(auctionNFTContract).repayInstant(tokenId);
    }
}