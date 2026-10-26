// SPDX-License-Identifier: MIT

pragma solidity 0.8.34;

import "forge-std/Test.sol";
import "../src/CityJourneyNFT.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CityJourneyNFTTest is Test {
    using Strings for uint256;

    uint256 constant INITIAL_TOTAL_SUPPLY = 3;
    string constant NAME = "City Journey NFT Test";
    string constant SYMBOL = "CJNFTT";
    string constant BASE_URI = "ipfs://test-uri/";

    string constant TEST_CITY_NAME = "CityTest";
    int256 constant TEST_LATITUDE = 0;
    int256 constant TEST_LONGITUDE = 0;
    uint256 constant TEST_FROM_DATE = 1_700_000_000;
    uint256 constant TEST_TO_DATE = 1_710_000_000;

    address owner;
    address randomUser;
    uint256 totalSupply;
    CityJourneyNFT nftCollection;

    function setUp() public {
        owner = makeAddr("owner");
        randomUser = makeAddr("randomUser");
        totalSupply = INITIAL_TOTAL_SUPPLY;
        nftCollection = new CityJourneyNFT(NAME, SYMBOL, owner, totalSupply, BASE_URI);
    }

    function test_Mint() public {
        vm.prank(owner);
        nftCollection.mint(TEST_CITY_NAME, TEST_LATITUDE, TEST_LONGITUDE, TEST_FROM_DATE, TEST_TO_DATE);

        assertEq(nftCollection.ownerOf(0), owner);
        (
            string memory storedCityName_,
            int256 storedLatitude_,
            int256 storedLongitude_,
            uint256 storedFromDate_,
            uint256 storedToDate_
        ) = nftCollection.cityData(0);
        assertEq(storedCityName_, TEST_CITY_NAME);
        assertEq(storedLatitude_, TEST_LATITUDE);
        assertEq(storedLongitude_, TEST_LONGITUDE);
        assertEq(storedFromDate_, TEST_FROM_DATE);
        assertEq(storedToDate_, TEST_TO_DATE);
    }

    function test_MultipleCitiesDistinctData() public {
        string memory cityName2_ = "CityTest2";
        int256 latitude2_ = 1;
        int256 longitude2_ = 2;
        uint256 fromDate2_ = 1_600_000_000;
        uint256 toDate2_ = 1_630_000_000;

        vm.startPrank(owner);

        nftCollection.mint(TEST_CITY_NAME, TEST_LATITUDE, TEST_LONGITUDE, TEST_FROM_DATE, TEST_TO_DATE);
        nftCollection.mint(cityName2_, latitude2_, longitude2_, fromDate2_, toDate2_);

        assertEq(nftCollection.ownerOf(0), owner);
        {
            (
                string memory storedCityName_,
                int256 storedLatitude_,
                int256 storedLongitude_,
                uint256 storedFromDate_,
                uint256 storedToDate_
            ) = nftCollection.cityData(0);
            assertEq(storedCityName_, TEST_CITY_NAME);
            assertEq(storedLatitude_, TEST_LATITUDE);
            assertEq(storedLongitude_, TEST_LONGITUDE);
            assertEq(storedFromDate_, TEST_FROM_DATE);
            assertEq(storedToDate_, TEST_TO_DATE);
        }

        {
            (
                string memory storedCityName2_,
                int256 storedLatitude2_,
                int256 storedLongitude2_,
                uint256 storedFromDate2_,
                uint256 storedToDate2_
            ) = nftCollection.cityData(1);
            assertEq(storedCityName2_, cityName2_);
            assertEq(storedLatitude2_, latitude2_);
            assertEq(storedLongitude2_, longitude2_);
            assertEq(storedFromDate2_, fromDate2_);
            assertEq(storedToDate2_, toDate2_);
        }

        vm.stopPrank();
    }

    function test_RevertWhen_MintCallerNotOwner() public {
        vm.startPrank(randomUser);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, randomUser));
        nftCollection.mint(TEST_CITY_NAME, TEST_LATITUDE, TEST_LONGITUDE, TEST_FROM_DATE, TEST_TO_DATE);

        vm.stopPrank();
    }

    function test_RevertWhen_MintSoldOut() public {
        vm.startPrank(owner);
        for (uint256 i = 0; i < INITIAL_TOTAL_SUPPLY; i++) {
            nftCollection.mint(TEST_CITY_NAME, TEST_LATITUDE, TEST_LONGITUDE, TEST_FROM_DATE, TEST_TO_DATE);
        }

        vm.expectRevert("Sold Out.");
        nftCollection.mint(TEST_CITY_NAME, TEST_LATITUDE, TEST_LONGITUDE, TEST_FROM_DATE, TEST_TO_DATE);

        vm.stopPrank();
    }

    function test_RevertWhen_TransferAttempted() public {
        vm.startPrank(owner);

        nftCollection.mint(TEST_CITY_NAME, TEST_LATITUDE, TEST_LONGITUDE, TEST_FROM_DATE, TEST_TO_DATE);
        uint256 mintedTokenId_ = nftCollection.currentTokenId() - 1;

        vm.expectRevert("Soulbound: non-transferable.");
        nftCollection.transferFrom(owner, randomUser, mintedTokenId_);

        vm.stopPrank();
    }

    function test_RevertWhen_SafeTransferFromAttempted() public {
        vm.startPrank(owner);

        nftCollection.mint(TEST_CITY_NAME, TEST_LATITUDE, TEST_LONGITUDE, TEST_FROM_DATE, TEST_TO_DATE);
        uint256 mintedTokenId_ = nftCollection.currentTokenId() - 1;

        vm.expectRevert("Soulbound: non-transferable.");
        nftCollection.safeTransferFrom(owner, randomUser, mintedTokenId_);

        vm.stopPrank();
    }

    // Verifies the soulbound _update override doesn't break the standard
    // Transfer event on mint — this is what a broken require condition would actually corrupt, not just whether mint() succeeds.
    function test_Mint_EmitsTransferEvent() public {
        vm.expectEmit(true, true, true, true);
        emit IERC721.Transfer(address(0), owner, 0);

        vm.prank(owner);
        nftCollection.mint(TEST_CITY_NAME, TEST_LATITUDE, TEST_LONGITUDE, TEST_FROM_DATE, TEST_TO_DATE);
    }

    function test_TokenURI() public {
        vm.startPrank(owner);

        nftCollection.mint(TEST_CITY_NAME, TEST_LATITUDE, TEST_LONGITUDE, TEST_FROM_DATE, TEST_TO_DATE);
        uint256 mintedTokenId_ = nftCollection.currentTokenId() - 1;
        string memory tokenURI_ = nftCollection.tokenURI(mintedTokenId_);
        string memory expectedURI_ = string.concat(BASE_URI, mintedTokenId_.toString(), ".json");

        assertEq(tokenURI_, expectedURI_);

        vm.stopPrank();
    }

    function test_RevertWhen_TokenURIForNonexistentToken() public {
        vm.startPrank(owner);

        uint256 notMintedTokenId_ = nftCollection.currentTokenId();
        vm.expectRevert();
        nftCollection.tokenURI(notMintedTokenId_);

        vm.stopPrank();
    }
}
