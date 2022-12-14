//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;


interface IETHRegistrarController {

    function available(string memory) external returns (bool);


    // function commit(bytes32) external;

    function register(
        bytes32 label,
        address owner,
        uint256 duration,
        address resolver,
        address addr
    ) external;

    function renew(bytes32 label, uint256 duration) external;
}
