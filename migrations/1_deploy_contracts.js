const Resolver = artifacts.require("Resolver");

module.exports = function (deployer, network, accounts) {
  deployer.deploy(Resolver, accounts[0]);
};
