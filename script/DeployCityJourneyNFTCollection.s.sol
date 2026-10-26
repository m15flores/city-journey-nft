// SPDX-License-Identifier: MIT

pragma solidity 0.8.34;

import "forge-std/Script.sol";
import "../src/CityJourneyNFT.sol";

contract DeployCityJourneyNFTCollection is Script {
    function run() external returns (CityJourneyNFT) {
        uint256 deployerPrivateKey_ = vm.envUint("PRIVATE_KEY");
        address deployerAddress_ = vm.addr(deployerPrivateKey_);
        vm.startBroadcast(deployerPrivateKey_);

        string memory name_ = "City Journey NFT";
        string memory symbol_ = "CJNFT";
        uint256 totalSupply_ = 10;
        string memory baseUri_ = "ipfs://bafybeihep6adyhwq6dzvn2a5vtcem2gdc5uebbctyv4l3cam7z5kwvcqty/";
        CityJourneyNFT nftCollection = new CityJourneyNFT(name_, symbol_, deployerAddress_, totalSupply_, baseUri_);

        vm.stopBroadcast();
        return nftCollection;
    }
}
