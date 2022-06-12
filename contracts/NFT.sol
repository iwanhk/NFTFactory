// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NFT is Ownable, ERC721A {
    using Strings for uint256;

    uint256 public immutable ordinaryNumber;
    uint256 public immutable uniqueNumber;
    uint256 public immutable fitNumber;
    struct SaleConfig {
        uint32 publicSaleStartTime;
        uint64 publicPriceWei;
    }


    SaleConfig public saleConfig;

    // metadata URI
    string private _baseTokenURI;

    constructor(
        uint256 _ordinaryNumber,
        uint256 _uniqueNumber,
        uint256 _fitNumber
    ) ERC721A("Cuttlefish", "CFK") {
        require(_fitNumber>0 && _ordinaryNumber>=_fitNumber && _uniqueNumber>0, "Invalid arg");

        ordinaryNumber = _ordinaryNumber;
        uniqueNumber = _uniqueNumber;
        fitNumber= _fitNumber;

        // _safeMint(msg.sender, _ordinaryNumber);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // *****************************************************************************
    // Public Functions

    function fit(uint256[] calldata tokenIds) external callerIsUser {
        require(
            totalSupply() <= uniqueNumber+ ordinaryNumber, "Reached max supply" );
        require(tokenIds.length== fitNumber, "fitNumber");

        for(uint256 i=0; i< tokenIds.length; i++){
            transferFrom(msg.sender, owner(), tokenIds[i]);
        }

        _safeMint(msg.sender, 1);
    }

    function isPublicSaleOn() public view returns(bool) {
        require(
            saleConfig.publicSaleStartTime != 0,
            "Public Sale Time is TBD."
        );

        return block.timestamp >= saleConfig.publicSaleStartTime;
    }

    // Owner Controls

    // Public Views
    // *****************************************************************************
    function numberMinted(address minter) external view returns(uint256) {
        return _numberMinted(minter);
    }

    function getFreeToken(uint256 total) external view returns (uint256[] memory ret){
        ret= new uint256[](total);

        uint256 j=0;
        for(uint256 i=0; i< ordinaryNumber; i++){
            if(ownerOf(i)== owner()){
                ret[j++]=i;
                if(j== total){
                    break;
                }
            }
        }
        if(j< total){
            revert("No enough free tokens");
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Non exists token");
        if(tokenId< ordinaryNumber){
            return string(abi.encodePacked(_baseTokenURI, "ordinary.json"));
        }
        return string(abi.encodePacked(_baseTokenURI, (tokenId-ordinaryNumber).toString(), ".json"));
    }

    // Contract Controls (onlyOwner)
    // *****************************************************************************
    function mint() external onlyOwner{
        _safeMint(msg.sender, ordinaryNumber);
    }
    function sale(address _to, uint256[] calldata tokenIds) external onlyOwner{
        require(isPublicSaleOn(), "Public sale has not begun yet");

        for(uint256 i=0; i< tokenIds.length; i++){
            transferFrom(msg.sender, _to, tokenIds[i]);
        }
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{ value: address(this).balance } ("");
        require(success, "Transfer failed.");
    }

    function setupNonAuctionSaleInfo(
        uint64 publicPriceWei,
        uint32 publicSaleStartTime
    ) public onlyOwner {
        saleConfig = SaleConfig(
            publicSaleStartTime,
            publicPriceWei
        );
    }

    // Internal Functions
    // *****************************************************************************

    function refundIfOver(uint256 price) internal {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function _baseURI() internal view virtual override returns(string memory) {
        return _baseTokenURI;
    }
}
