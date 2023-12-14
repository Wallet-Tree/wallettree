const Resolver = artifacts.require("Resolver");

module.exports = function (deployer, network, accounts) {
  deployer.deploy(Resolver, '0x07be5e624af733f40a115e96e776d0f588279fd8');
};

/**
 * dev: 0x07be5e624af733f40a115e96e776d0f588279fd8
 * staging: 0x07be5e624af733f40a115e96e776d0f588279fd8
 * prod: 0xe539cdfdeb4a68e1b7aeb5c879f86b183c51d2d8
 */
