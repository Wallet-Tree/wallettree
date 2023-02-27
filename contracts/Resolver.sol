// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Resolver {
    /* ========== DATA STRUCTURES ========== */

    struct Config {
        string cid;
        bool allowServer;
        address owner;
        bool isValue;
    }

    /* ========== STATE VARIABLES ========== */

    address private owner;
    address private serverSigner;
    mapping(bytes32 => Config) private resolvers;
    mapping(bytes32 => bytes32) private secondaryResolvers;

    /* ========== MODIFIERS ========== */

    modifier onlyAuthorized(bytes32 idHash) {
        Config storage resolver = resolvers[idHash];
        require(resolver.isValue == true, "Invalid resolver");
        if (!resolver.allowServer) {
            require(msg.sender == resolver.owner, "Unauthorized");
        } else {
            require(
                msg.sender == resolver.owner || msg.sender == serverSigner,
                "Unauthorized"
            );
        }
        _;
    }

    modifier validateCid(string calldata cid, bytes memory signature) {
        require(
            ECDSA.recover(
                ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(cid))),
                signature
            ) == serverSigner,
            "Invalid"
        );
        _;
    }

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
    ) external validateCid(cid, signature) {
        require(idHash != bytes4(0x0), "Invalid hash");
        Config storage resolver = resolvers[idHash];
        require(resolver.isValue == false, "Invalid request");
        resolver.cid = cid;
        resolver.allowServer = allowServer;
        if (msg.sender != serverSigner) {
            resolver.owner = msg.sender;
        }
        resolver.isValue = true;
    }

    function updateResolverCid(
        bytes32 idHash,
        string calldata cid,
        bytes calldata signature
    )
        external
        onlyAuthorized(idHash)
        validateCid(cid, signature)
        returns (bool success)
    {
        Config storage resolver = resolvers[idHash];
        resolver.cid = cid;
        return true;
    }

    function updateResolverAllowServer(
        bytes32 idHash,
        bool allowServer,
        address newOwner
    ) external onlyAuthorized(idHash) returns (bool success) {
        Config storage resolver = resolvers[idHash];
        if (!allowServer && resolver.owner == address(0x0)) {
            require(newOwner != address(0x0), "Owner must be valid address");
            resolver.owner = newOwner;
        }
        resolver.allowServer = allowServer;
        return true;
    }

    function deleteResolver(bytes32 idHash)
        external
        onlyAuthorized(idHash)
        returns (bool success)
    {
        delete resolvers[idHash];
        return true;
    }

    function createSecondaryResolver(
        bytes32 idHash,
        bytes32 primaryResolverHash
    ) external onlyAuthorized(primaryResolverHash) {
        require(idHash != bytes4(0x0), "Invalid hash");
        require(secondaryResolvers[idHash] == bytes4(0x0), "Invalid");
        secondaryResolvers[idHash] = primaryResolverHash;
    }

    function deleteSecondaryResolver(bytes32 idHash)
        external
        onlyAuthorized(secondaryResolvers[idHash])
        returns (bool success)
    {
        require(secondaryResolvers[idHash] != bytes4(0x0), "Invalid");
        delete secondaryResolvers[idHash];
        return true;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function changeServerSigner(address _newServerSigner) external {
        require(msg.sender == owner, "msg.sender must be contract owner");
        require(_newServerSigner != address(0x0), "Invalid address");
        serverSigner = _newServerSigner;
    }
}
