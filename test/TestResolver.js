const Resolver = artifacts.require("Resolver");
const sha3 = require("web3-utils").sha3;
const Web3 = require("web3");

const zeroAddress = "0x0000000000000000000000000000000000000000";
const privateKey =
  "e686d4a369d679ad259b8fa7b18b33775ecbc05807acc1a7753e6dc2c8b893a2";
const newPrivateKey =
  "3121da84c5c64f392b84b01370e05228c60a4ea1cbe166b622ccb295823f67a2";

const primaryIdentifier = "test@wallettree.me";
const hashedIdentifier = sha3(primaryIdentifier);

const secondaryIdentifier = "+11234567890";
const hashedSecondaryIdentifier = sha3(secondaryIdentifier);

const cid = "QmToRYGxF8b38rGiPYcvJZ2MAAa1bhUzqoHgYfEkGveq1Q";
const newCid = "QmRaLjEpi5HwpPariGUEvvFNXhYgsbbUhjruSXoQbeiE37";

contract("Resolver", (accounts) => {
  let instance;
  let web3;

  beforeEach(async () => {
    instance = await Resolver.deployed();
    web3 = new Web3();
  });

  it("should create a primary resolver", async () => {
    const hashedCid = sha3(cid);
    const { signature } = web3.eth.accounts.sign(hashedCid, privateKey);

    await instance.createResolver(hashedIdentifier, cid, signature, true, {
      from: accounts[0],
    });

    let resolver = await instance.resolve(hashedIdentifier, {
      from: accounts[0],
    });

    assert.equal(resolver.cid, cid);
    assert.equal(resolver.allowServer, true);
    assert.equal(resolver.owner, zeroAddress);
    assert.equal(resolver.isValue, true);
  });

  it("should update a primary resolver cid", async () => {
    const hashedCid = sha3(newCid);
    const { signature } = web3.eth.accounts.sign(hashedCid, privateKey);

    await instance.updateResolverCid(hashedIdentifier, newCid, signature, {
      from: accounts[0],
    });

    let resolver = await instance.resolve(hashedIdentifier, {
      from: accounts[0],
    });

    assert.equal(resolver.cid, newCid);
  });

  it("should get a primary resolver", async () => {
    let resolver = await instance.resolve(hashedIdentifier, {
      from: accounts[0],
    });

    assert.equal(resolver.isValue, true);
    assert.equal(resolver.cid, newCid);
  });

  // TODO: add individual cases (i.e. passing no owner on false)
  it("should update a primary resolver allow server", async () => {
    // Disable
    const newAllowServer = false;
    const newOwner = accounts[1];
    await instance.updateResolverAllowServer(
      hashedIdentifier,
      newAllowServer,
      newOwner,
      { from: accounts[0] }
    );

    let disabledServerResolver = await instance.resolve(hashedIdentifier, {
      from: accounts[0],
    });

    // assert.equal(success, true);
    assert.equal(disabledServerResolver.allowServer, newAllowServer);
    assert.equal(disabledServerResolver.owner, newOwner);

    // Enable
    await instance.updateResolverAllowServer(
      hashedIdentifier,
      !newAllowServer,
      zeroAddress,
      { from: newOwner }
    );

    let enabledServerResolver = await instance.resolve(hashedIdentifier, {
      from: accounts[0],
    });

    // assert.equal(success, true);
    assert.equal(enabledServerResolver.allowServer, !newAllowServer);
    assert.equal(enabledServerResolver.owner, newOwner);
  });

  // TODO: add individual cases (i.e. passing invalid hash)
  it("should create a secondary resolver", async () => {
    await instance.createSecondaryResolver(
      hashedSecondaryIdentifier,
      hashedIdentifier,
      {
        from: accounts[0],
      }
    );

    let resolver = await instance.resolve(hashedSecondaryIdentifier, {
      from: accounts[0],
    });

    assert.equal(resolver.isValue, true);
    assert.equal(resolver.cid, newCid);
    // optionally check other values
  });

  it("should get a secondary resolver", async () => {
    let resolver = await instance.resolve(hashedSecondaryIdentifier, {
      from: accounts[0],
    });

    assert.equal(resolver.isValue, true);
    assert.equal(resolver.cid, newCid);
  });

  it("should delete a secondary resolver", async () => {
    await instance.deleteSecondaryResolver(hashedSecondaryIdentifier, {
      from: accounts[0],
    }); // this might come back non-existent?

    let resolver = await instance.resolve(hashedSecondaryIdentifier, {
      from: accounts[0],
    });

    assert.equal(resolver.isValue, false);
  });

  // TODO: add individual cases (i.e. passing empty address)
  it("should update the server signer", async () => {
    const newServerSigner = accounts[2];
    await instance.changeServerSigner(newServerSigner, { from: accounts[0] }); // this call MUST be from contract owner

    // assert.equal(instance.serverSigner, newServerSigner);
  });

  it("should fail authorization", async () => {
    const hashedCid = sha3(cid);
    const { signature } = web3.eth.accounts.sign(hashedCid, newPrivateKey);
    const nonServerSigner = accounts[7];

    await instance.updateResolverCid(hashedIdentifier, cid, signature, {
      from: nonServerSigner,
    });
    // TODO: assert failure here due to require()
  });

  it("should fail validation", async () => {
    const hashedCid = sha3(cid);
    const alteration = "X";
    const { signature } = web3.eth.accounts.sign(
      hashedCid + alteration,
      newPrivateKey
    );

    await instance.updateResolverCid(hashedIdentifier, cid, signature, {
      from: accounts[2],
    });
    // TODO: assert failure here due to require()
  });

  it("should delete a primary resolver", async () => {
    await instance.deleteResolver(hashedIdentifier, {
      from: accounts[2],
    });

    let resolver = await instance.resolve(hashedIdentifier, {
      from: accounts[0],
    });

    assert.equal(resolver.isValue, false);
    // optionally check other values
  });
});
