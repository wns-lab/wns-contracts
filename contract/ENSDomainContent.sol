pragma solidity ^0.8.0;

contract WNSDomainContent {

    mapping(bytes1 => bool) public base_allow;
    
    constructor(string memory _strallow) {
        bytes memory b_strallow = bytes(_strallow);

        for (uint i = 0; i < b_strallow.length; i++) {
            base_allow[b_strallow[i]] = true;
        }

    }

    function check_domain(string memory name) public view returns (bool) {
        bytes memory name_hash = bytes(name);

        for (uint i = 0; i < name_hash.length; i++) {
            // str_allow[b_strallow[i]] = true;
            if (!base_allow[name_hash[i]]) {
                return false;
            }
        }

        return true;
    }

    function toLower(string memory str) public pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);

        for (uint i = 0; i < bStr.length; i++) {
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {

                bLower[i] = bytes1(uint8(bStr[i]) + 32);

            } else {
                bLower[i] = bStr[i];
            }
        }
        
        return string(bLower);
    }

}
