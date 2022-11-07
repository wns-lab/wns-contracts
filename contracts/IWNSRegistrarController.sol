pragma solidity >=0.8.4;

interface IWNSRegistrarController {
    function registerFromWNS(
        uint256,
        string calldata,
        address,
        uint256,
        address,
        bool
    ) external payable;

    function renew(string calldata, uint256) external payable;
}
