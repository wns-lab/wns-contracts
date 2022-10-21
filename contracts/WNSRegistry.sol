pragma solidity ^0.8.0;

import '@ensdomains/ens-contracts/contracts/registry/ENSRegistry.sol';

contract WNSRegistry is ENSRegistry {
    address public reservedNodes;

    modifier isNotReserved(bytes32 node) {
        require(reservedNodes.isLocked == false || reservedNodes.isReserved(node) == false);
        _;
    }

    constructor(address reservedNodesContract) public {
        records[0x0].owner = msg.sender;
        reservedNodes = reservedNodesContract;
    }

    function setOwner(bytes32 node, address owner)
        public
        virtual
        override
        authorised(node)
        isNotReserved(node)
    {
        super.setOwner(node, owner);
    }
}

