// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract Resolver {
    /* ========== DATA STRUCTURES ========== */

    struct Config {
        bytes32 contentHash; // SHA-256 hash of the file on IPFS
        bool serverAccess; // Permission for server access set by user
        address owner; // Wallet used to create profile (optional)
    }

    /* ========== STATE VARIABLES ========== */

    address private owner;
    address private serverSigner;
    mapping(bytes32 => Config) private resolvers; // hash of primary PII => Config
    mapping(bytes32 => bytes32) private secondaryResolvers; // hash of a secondary PII => hash of primary PII

    /* ========== MODIFIERS ========== */

    modifier onlyAuthorized(bytes32 hash) {
        require(resolvers[hash].contentHash != bytes4(0x0)); // hash must exist in mapping
        if (!resolvers[hash].serverAccess) {
            require(
                msg.sender == resolvers[hash].owner,
                "Caller must be owner"
            );
        } else {
            require(
                msg.sender == resolvers[hash].owner ||
                    msg.sender == serverSigner,
                "Caller must be owner or server"
            );
        }
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

    /* ========== MUTATIVE FUNCTIONS ========== */

    // PRIMARY
    function createResolver(
        bytes32 userHash,
        bytes32 contentHash,
        bool serverAccess
    ) external {
        require(userHash != bytes4(0x0));
        require(contentHash != bytes4(0x0));
        Config storage config = resolvers[userHash];
        config.contentHash = contentHash;
        config.serverAccess = serverAccess;
        if (msg.sender != serverSigner) {
            config.owner = msg.sender;
        }
        emit ResolverCreateEvent(userHash);
    }

    function updateResolverContentHash(bytes32 userHash, bytes32 newContentHash)
        external
        onlyAuthorized(userHash)
        returns (bool success)
    {
        require(newContentHash != bytes4(0x0));
        resolvers[userHash].contentHash = newContentHash;
        emit ResolverUpdateEvent(userHash, "contentHash");
        return true;
    }

    function updateResolverServerAccess(bytes32 userHash, bool newServerAccess)
        external
        onlyAuthorized(userHash)
        returns (bool success)
    {
        if (
            !newServerAccess &&
            resolvers[userHash].owner == address(0x0) &&
            msg.sender != serverSigner
        ) {
            resolvers[userHash].owner = msg.sender;
        }
        resolvers[userHash].serverAccess = newServerAccess;
        emit ResolverUpdateEvent(userHash, "serverAccess");
        return true;
    }

    function deleteResolver(bytes32 userHash)
        external
        onlyAuthorized(userHash)
        returns (bool success)
    {
        delete resolvers[userHash];
        emit ResolverDeleteEvent(userHash);
        return true;
    }

    function getContentHash(bytes32 userHash)
        external
        view
        returns (bytes32 contentHash)
    {
        bytes32 secondaryMappingHash = secondaryResolvers[userHash];
        if (secondaryMappingHash == bytes4(0x0)) {
            return resolvers[userHash].contentHash;
        } else {
            return resolvers[secondaryMappingHash].contentHash;
        }
    }

    // SECONDARY
    function createSecondaryResolver(
        bytes32 userHash,
        bytes32 primaryResolverHash
    ) external onlyAuthorized(primaryResolverHash) {
        require(userHash != bytes4(0x0));
        secondaryResolvers[userHash] = primaryResolverHash;
        emit SecondaryResolverCreateEvent(userHash);
    }

    function deleteSecondaryResolver(bytes32 userHash)
        external
        onlyAuthorized(secondaryResolvers[userHash])
        returns (bool success)
    {
        delete secondaryResolvers[userHash];
        emit SecondaryResolverDeleteEvent(userHash);
        return true;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function changeServerSigner(address _newServerSigner) external {
        require(msg.sender == owner, "msg.sender must be contract owner");
        require(_newServerSigner != address(0x0));
        serverSigner = _newServerSigner;
    }
}
