pragma solidity >=0.8.4;

interface IWNSRegistrarController {
    function registerFromWNS(
        bytes32,
        address,
        address,
        uint256,
        uint256,
        address
    ) external payable;

    function renew(string calldata, uint256) external payable;
}
