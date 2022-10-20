pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';

contract ReservedNodes is Ownable {
    bool public allReservedNodesLocked = true;
    mapping(bytes32 => bool) public reservedNodes;

    event ReservedNodeAdded(bytes32 node);
    event ReservedNodeRemoved(bytes32 node);

    constructor(bytes32[] nodes) {
        reservedNodes = nodes;
    }

    function isReserved(bytes32 node) public view virtual returns (bool) {
        return reservedNodes[node];
    }

    function addReservedNode(bytes32 node) external virtual onlyOwner {
        if (reservedNodes[node] == false) {
            reservedNodes[node] = true;
            emit ReservedNodeAdded(node);
        }
    }

    function removeReservedNode(bytes32 node) external virtual onlyOwner {
        if (reservedNodes[node] == true) {
            reservedNodes[node] = false;
            emit ReservedNodeRemoved(node);
        }
    }

    function isLocked() external view virtual returns (bool) {
        return allReservedNodesLocked;
    }

    function unLockAllReservedNodes() external virtual onlyOwner {
        allReservedNodesLocked = false;
    }
}



