// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../node_modules/@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

contract Resolver {
    /* ========== DATA STRUCTURES ========== */

    struct Config {
        string cid;
        bool allowServer;
        address owner;
    }

    /* ========== STATE VARIABLES ========== */

    address private owner;
    address private serverSigner;
    mapping(bytes32 => Config) private resolvers;
    mapping(bytes32 => bytes32) private secondaryResolvers;

    /* ========== MODIFIERS ========== */

    modifier onlyAuthorized(bytes32 idHash) {
        require(bytes(resolvers[idHash].cid).length != 0, "Unauthorized");
        if (!resolvers[idHash].allowServer) {
            require(msg.sender == resolvers[idHash].owner, "Unauthorized");
        } else {
            require(
                msg.sender == resolvers[idHash].owner ||
                    msg.sender == serverSigner,
                "Unauthorized"
            );
        }
        _;
    }

    modifier validateCid(bytes32 hash, bytes memory signature) {
        require(
            SignatureChecker.isValidSignatureNow(msg.sender, hash, signature),
            "Invalid"
        );
        _;
    }

    /* ========== EVENTS ========== */

    event ResolverCreateEvent(bytes32 indexed hash);
    event ResolverUpdateEvent(bytes32 indexed hash, string updateType);
    event ResolverDeleteEvent(bytes32 indexed hash);

    event SecondaryResolverCreateEvent(bytes32 indexed hash);
    event SecondaryResolverDeleteEvent(bytes32 indexed hash);

    /* ========== CONSTRUCTOR ========== */

    constructor(address _serverSigner) {
        owner = msg.sender;
        serverSigner = _serverSigner;
    }

    function resolve(bytes32 idHash)
        external
        view
        returns (Config memory resolver)
    {
        bytes32 secondaryMappingHash = secondaryResolvers[idHash];
        if (secondaryMappingHash == bytes4(0x0)) {
            return resolvers[idHash];
        } else {
            return resolvers[secondaryMappingHash];
        }
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function createResolver(
        bytes32 idHash,
        string calldata cid,
        bytes calldata signature,
        bool allowServer
    ) external validateCid(keccak256(abi.encodePacked(cid)), signature) {
        require(idHash != bytes4(0x0), "Invalid hash");
        require(bytes(resolvers[idHash].cid).length == 0, "Invalid hash");
        Config storage config = resolvers[idHash];
        config.cid = cid;
        config.allowServer = allowServer;
        if (msg.sender != serverSigner) {
            config.owner = msg.sender;
        }
        emit ResolverCreateEvent(idHash);
    }

    function updateResolverCid(
        bytes32 idHash,
        string calldata cid,
        bytes calldata signature
    )
        external
        onlyAuthorized(idHash)
        validateCid(keccak256(abi.encodePacked(cid)), signature)
        returns (bool success)
    {
        resolvers[idHash].cid = cid;
        emit ResolverUpdateEvent(idHash, "Cid");
        return true;
    }

    function updateResolverAllowServer(bytes32 idHash, bool allowServer)
        external
        onlyAuthorized(idHash)
        returns (bool success)
    {
        if (
            !allowServer &&
            resolvers[idHash].owner == address(0x0) &&
            msg.sender != serverSigner
        ) {
            resolvers[idHash].owner = msg.sender;
        }
        resolvers[idHash].allowServer = allowServer;
        emit ResolverUpdateEvent(idHash, "allowServer");
        return true;
    }

    function deleteResolver(bytes32 idHash)
        external
        onlyAuthorized(idHash)
        returns (bool success)
    {
        delete resolvers[idHash];
        emit ResolverDeleteEvent(idHash);
        return true;
    }

    function createSecondaryResolver(
        bytes32 idHash,
        bytes32 primaryResolverHash
    ) external onlyAuthorized(primaryResolverHash) {
        require(idHash != bytes4(0x0), "Invalid hash");
        require(secondaryResolvers[idHash] == bytes4(0x0), "Invalid");
        secondaryResolvers[idHash] = primaryResolverHash;
        emit SecondaryResolverCreateEvent(idHash);
    }

    function deleteSecondaryResolver(bytes32 idHash)
        external
        onlyAuthorized(secondaryResolvers[idHash])
        returns (bool success)
    {
        require(secondaryResolvers[idHash] != bytes4(0x0), "Invalid");
        delete secondaryResolvers[idHash];
        emit SecondaryResolverDeleteEvent(idHash);
        return true;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function changeServerSigner(address _newServerSigner) external {
        require(msg.sender == owner, "msg.sender must be contract owner");
        require(_newServerSigner != address(0x0), "Invalid address");
        serverSigner = _newServerSigner;
    }
}