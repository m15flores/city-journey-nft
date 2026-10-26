// SPDX-License-Identifier: MIT

pragma solidity 0.8.34;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract CityJourneyNFT is ERC721, Ownable {
    using Strings for uint256;

    struct CityData {
        string cityName;
        int256 latitude;
        int256 longitude;
        uint256 fromDate;
        uint256 toDate;
    }

    mapping(uint256 => CityData) public cityData;

    uint256 public currentTokenId;
    uint256 public totalSupply;
    string public baseUri;

    event MintNFT(address userAddress_, uint256 tokenId_, string cityName_);

    constructor(
        string memory name_,
        string memory symbol_,
        address owner_,
        uint256 totalSupply_,
        string memory baseUri_
    ) ERC721(name_, symbol_) Ownable(owner_) {
        totalSupply = totalSupply_;
        baseUri = baseUri_;
    }

    function mint(string memory cityName_, int256 latitude_, int256 longitude_, uint256 fromDate_, uint256 toDate_)
        external
        onlyOwner
    {
        require(currentTokenId < totalSupply, "Sold Out.");

        cityData[currentTokenId] = CityData({
            cityName: cityName_, latitude: latitude_, longitude: longitude_, fromDate: fromDate_, toDate: toDate_
        });

        _safeMint(msg.sender, currentTokenId);
        uint256 tokenId_ = currentTokenId;
        currentTokenId++;

        emit MintNFT(msg.sender, tokenId_, cityName_);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireOwned(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string.concat(baseURI, tokenId.toString(), ".json") : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);

        require(from == address(0), "Soulbound: non-transferable.");

        return super._update(to, tokenId, auth);
    }
}
