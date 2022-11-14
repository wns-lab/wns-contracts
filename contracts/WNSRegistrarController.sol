pragma solidity >=0.8.4;

import "./BaseRegistrarImplementation.sol";
import "./StringUtils.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/Resolver.sol";
import "@ensdomains/ens-contracts/contracts/registry/ReverseRegistrar.sol";
import "./IETHRegistrarController.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @dev A registrar controller for registering and renewing names at fixed cost.
 */
contract WNSRegistrarController is Ownable, IWNSRegistrarController {
    using StringUtils for *;
    using Address for address;

    bytes32 private constant WEB3_NODE =
        0x587d09fe5fa45354680537d38145a28b772971e0f293af3ee0c536fc919710fb;
    
    Gravity gravity;

    BaseRegistrarImplementation immutable base;
    ReverseRegistrar public immutable reverseRegistrar;

    event NameRegistered(
        string name,
        bytes32 indexed label,
        address indexed owner,
        uint256 expires
    );
    event NameRenewed(
        string name,
        bytes32 indexed label,
        uint256 expires
    );

    modifier onlyGravity(address caller) {
        require(caller == gravity);
        _;
    }

    constructor(
        BaseRegistrarImplementation _base,
        ReverseRegistrar _reverseRegistrar,
        Gravity _gravity
    ) {
        gravity = _gravity;
        base = _base;
        reverseRegistrar = _reverseRegistrar;
    }

    function valid(string memory name) public pure returns (bool) {
        return name.strlen() >= 3;
    }

    function register(
        string calldata name,
        address owner,
        uint256 duration,
        address resolver,
        bool reverseRecord
    ) public payable override onlyGravity {
        uint256 expires = base.register(
            name,
            owner,
            duration,
            resolver
        );

        _setRecords(resolver, keccak256(bytes(name)), data);

        if (reverseRecord) {
            _setReverseRecord(name, resolver, msg.sender);
        }

        emit NameRegistered(
            name,
            keccak256(bytes(name)),
            owner,
            expires
        );
    }

    function renew(string calldata name, uint256 duration)
        external
        payable
        override
        onlyGravity
    {
        bytes32 label = keccak256(bytes(name));

        uint256 expires = base.renew(uint256(label), duration);

        emit NameRenewed(name, label, expires);
    }

    function supportsInterface(bytes4 interfaceID)
        external
        pure
        returns (bool)
    {
        return
            interfaceID == type(IERC165).interfaceId ||
            interfaceID == type(IETHRegistrarController).interfaceId;
    }

    /* Internal functions */
    function _setRecords(
        address resolver,
        bytes32 label,
        bytes[] calldata data
    ) internal {
        // use hardcoded .eth namehash
        bytes32 nodehash = keccak256(abi.encodePacked(ETH_NODE, label));
        for (uint256 i = 0; i < data.length; i++) {
            // check first few bytes are namehash
            bytes32 txNamehash = bytes32(data[i][4:36]);
            require(
                txNamehash == nodehash,
                "ETHRegistrarController: Namehash on record do not match the name being registered"
            );
            resolver.functionCall(
                data[i],
                "ETHRegistrarController: Failed to set Record"
            );
        }
    }

    function _setReverseRecord(
        string memory name,
        address resolver,
        address owner
    ) internal {
        reverseRegistrar.setNameForAddr(
            msg.sender,
            owner,
            resolver,
            string.concat(name, ".eth")
        );
    }
}
