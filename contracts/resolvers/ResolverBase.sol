// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./profiles/IVersionableResolver.sol";

abstract contract ResolverBase is ERC165, IVersionableResolver {
    mapping(bytes32 => uint64) public recordVersions;

    function isAuthorised() internal view virtual returns (bool);

    modifier authorised() {
        require(isAuthorised());
        _;
    }

    /**
     * Increments the record version associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     */

    function clearRecords(bytes32 node) public virtual  {
        recordVersions[node]++;
        emit VersionChanged(node, recordVersions[node]);
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceID == type(IVersionableResolver).interfaceId ||
            super.supportsInterface(interfaceID);
    }
}