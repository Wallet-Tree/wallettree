const Resolver = artifacts.require("Resolver");

module.exports = function (deployer) {
  deployer.deploy(Resolver);
};
