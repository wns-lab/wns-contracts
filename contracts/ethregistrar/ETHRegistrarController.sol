//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import {BaseRegistrarImplementation} from "./BaseRegistrarImplementation.sol";
import {StringUtils} from "./StringUtils.sol";
import {Resolver} from "../resolvers/Resolver.sol";
import {ReverseRegistrar} from "../registry/ReverseRegistrar.sol";
import {IETHRegistrarController} from "./IETHRegistrarController.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
// import {INameWrapper} from "../wrapper/INameWrapper.sol";
import {ERC20Recoverable} from "../utils/ERC20Recoverable.sol";

error CommitmentTooNew(bytes32 commitment);
error CommitmentTooOld(bytes32 commitment);
error NameNotAvailable(string name);
error DurationTooShort(uint256 duration);
error ResolverRequiredWhenDataSupplied();
error UnexpiredCommitmentExists(bytes32 commitment);
error InsufficientValue();
error Unauthorised(bytes32 node);
error MaxCommitmentAgeTooLow();
error MaxCommitmentAgeTooHigh();

/**
 * @dev A registrar controller for registering and renewing names at fixed cost.
 */
contract ETHRegistrarController is
    Ownable,
    IETHRegistrarController,
    IERC165,
    ERC20Recoverable
{
    using StringUtils for *;
    using Address for address;

    uint256 public constant MIN_REGISTRATION_DURATION = 28 days;
    bytes32 private constant ETH_NODE =
        0x587d09fe5fa45354680537d38145a28b772971e0f293af3ee0c536fc919710fb;
    uint64 private constant MAX_EXPIRY = type(uint64).max;
    BaseRegistrarImplementation immutable base;
    // IPriceOracle public immutable prices;
    // uint256 public immutable minCommitmentAge;
    // uint256 public immutable maxCommitmentAge;
    ReverseRegistrar public immutable reverseRegistrar;
    // INameWrapper public immutable nameWrapper;
    address public gravity;

    mapping(bytes32 => uint256) public commitments;

    modifier onlyGravity() {
        require(gravity == msg.sender);
        _;
    }

    event NameRegistered(
        bytes32 indexed label,
        address indexed owner,
        uint256 expires
    );

    event NameRenewed(
        bytes32 indexed label,
        uint256 expires
    );

    constructor(
        BaseRegistrarImplementation _base,
        // IPriceOracle _prices,
        // uint256 _minCommitmentAge,
        // uint256 _maxCommitmentAge,
        ReverseRegistrar _reverseRegistrar,
        address _gravity
        // INameWrapper _nameWrapper
    ) {
        // if (_maxCommitmentAge <= _minCommitmentAge) {
        //     revert MaxCommitmentAgeTooLow();
        // }

        // if (_maxCommitmentAge > block.timestamp) {
        //     revert MaxCommitmentAgeTooHigh();
        // }

        base = _base;
        // minCommitmentAge = _minCommitmentAge;
        // maxCommitmentAge = _maxCommitmentAge;
        reverseRegistrar = _reverseRegistrar;
        gravity = _gravity;
    }


    function available(string memory name) public view override returns (bool) {
        bytes32 label = keccak256(bytes(name));
        return base.available(uint256(label));
    }

    function register(
        bytes32 label,
        address owner,
        uint256 duration,
        address resolver,
        address addr
    ) public onlyGravity {

        uint256 tokenId = uint256(label);
        uint expires;

        if (resolver != address(0)) {

            expires = base.register(tokenId, address(this), duration);
            bytes32 nodehash = keccak256(abi.encodePacked(ETH_NODE, label));
            base.ens().setResolver(nodehash,resolver);

            if (addr != address(0)) {
                Resolver(resolver).setAddr(nodehash, addr);
            }

            base.reclaim(tokenId,owner);
            // base.transferFrom(address(this),owner,tokenId);

        } else {

            require(addr == address(0));
            expires = base.register(tokenId, owner, duration);

        }

        emit NameRegistered(label, owner, expires);
    }

    function renew(bytes32 label, uint256 duration)
        external
        onlyGravity
    {
        _renew(label, duration);
    }

    function _renew(
        bytes32 label,
        uint256 duration
    ) internal {
        // bytes32 labelhash = keccak256(bytes(name));
        uint256 tokenId = uint256(label);
        uint256 expires;

        expires = base.renew(tokenId, duration);

        emit NameRenewed(label, expires);
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


    function _setRecords(
        address resolverAddress,
        bytes32 label,
        bytes[] calldata data
    ) internal {
        // use hardcoded .eth namehash
        bytes32 nodehash = keccak256(abi.encodePacked(ETH_NODE, label));
        Resolver resolver = Resolver(resolverAddress);
        resolver.multicallWithNodeCheck(nodehash, data);
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
