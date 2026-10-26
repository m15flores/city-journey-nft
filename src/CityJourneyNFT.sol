// SPDX-License-Identifier: MIT

pragma solidity 0.8.34;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @notice Soulbound ERC-721 collection where each token represents a city the owner has lived in,
 * with the city name, coordinates and dates stored on-chain.
 * @dev Tokens are non-transferable: `_update` is overridden so only mints (`from == address(0)`) succeed.
 * Token URIs are built as `baseUri` + token id + ".json".
 */
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

    /**
     * @dev Emitted when token `tokenId_` for city `cityName_` is minted to `userAddress_`.
     */
    event MintNFT(address userAddress_, uint256 tokenId_, string cityName_);

    /**
     * @notice Initializes the collection with its name, symbol, owner, supply cap and base URI.
     * @param name_ Token collection name.
     * @param symbol_ Token collection symbol.
     * @param owner_ Address allowed to mint.
     * @param totalSupply_ Maximum number of tokens that can be minted.
     * @param baseUri_ Base URI used to build each token URI.
     */
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

    /**
     * @notice Mints the next token to the caller and stores its city data. Only callable by the owner.
     * @dev Token ids start at 0 and increase by one per mint. Reverts once `totalSupply` tokens exist.
     * @param cityName_ Name of the city.
     * @param latitude_ Latitude in degrees multiplied by 1e6.
     * @param longitude_ Longitude in degrees multiplied by 1e6.
     * @param fromDate_ Start date as a Unix timestamp in seconds.
     * @param toDate_ End date as a Unix timestamp in seconds.
     */
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

    /**
     * @notice Returns the metadata URI of a minted token.
     * @dev Built as `baseUri` + `tokenId` + ".json", or an empty string if `baseUri` is empty.
     * @param tokenId Id of the token; must exist.
     * @return The metadata URI of `tokenId`.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireOwned(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string.concat(baseURI, tokenId.toString(), ".json") : "";
    }

    /**
     * @dev Returns `baseUri`, used by {tokenURI} as the prefix of every token URI.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    /**
     * @dev Overrides the hook OpenZeppelin uses for mints, transfers and burns, and reverts unless
     * the token does not exist yet, so only mints are allowed and tokens are soulbound.
     */
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);

        require(from == address(0), "Soulbound: non-transferable.");

        return super._update(to, tokenId, auth);
    }
}
