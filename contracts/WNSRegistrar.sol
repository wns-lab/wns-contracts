pragma solidity ^0.8.0;

import '@ensdomains/ens-contracts/contracts/ethregistrar/IBaseRegistrar.sol';
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WNSRegistrar is ERC721, IBaseRegistrar, Ownable {
    // Authorises a controller, who can register and renew domains.
    function addController(address controller) external {

    }

    // Revoke controller permission for an address.
    function removeController(address controller) external {

    }

    // Set the resolver for the TLD this registrar manages.
    function setResolver(address resolver) external {

    }

    /**
     * @dev Register a name.
     */
    function register(
        uint256 id,
        address owner,
        uint256 duration
    ) external returns (uint256) {

    }

    function renew(uint256 id, uint256 duration) external returns (uint256) {

    }

    /**
     * @dev Reclaim ownership of a name in ENS, if you own it in the registrar.
     */
    function reclaim(uint256 id, address owner) external {

    }
}

