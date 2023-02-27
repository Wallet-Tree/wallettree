const Resolver = artifacts.require("Resolver");
const sha3 = require("web3-utils").sha3;

const idHash =
  "0x037bb1d4f2ca353dd169d74841729e1fd5d7fb642a74d283428373f0ecc751dd";
const cid = "QmToRYGxF8b38rGiPYcvJZ2MAAa1bhUzqoHgYfEkGveq1Q";
const signature =
  "0xe90044898483fc3ee96bde69b355b2d13128caf2f11b74796102a6d87c8595d738f816453dc4c9aa66dfaeac5e6f42ceffac7b871182c43c2fc70fe6c75e53131c";
const zeroAddress = "0x0000000000000000000000000000000000000000";

const newCid = "";
const newSignature = "";

contract("Resolver", (accounts) => {
  let instance;

  beforeEach(async () => {
    ens = await Resolver.deployed();
  });

  it("should create a primary resolver", async () => {
    await instance.createResolver(idHash, cid, signature, true, {
      from: accounts[0],
    });

    let resolver = instance.resolve(idHash, { from: accounts[0] });

    assert.equal(resolver.cid, cid);
    assert.equal(resolver.allowServer, true);
    assert.equal(resolver.owner, zeroAddress);
    assert.equal(resolver.isValue, true);
  });

  it("should update a primary resolver cid", async () => {
    const success = await instance.updateResolverCid(
      idHash,
      newCid,
      newSignature,
      { from: accounts[0] }
    );

    let resolver = instance.resolve(idHash, { from: accounts[0] });

    assert.equal(success, true);
    assert.equal(resolver.cid, newCid);
  });

  it("should get a primary resolver", async () => {
    let resolver = instance.resolve(idHash, { from: accounts[0] });

    assert.equal(resolver.isValue, true);
    assert.equal(resolver.cid, cid);
  });

  // TODO: add individual cases (i.e. passing no owner on false)
  it("should update a primary resolver allow server", async () => {
    const newAllowServer = false;
    const newOwner = accounts[1];
    const success = await instance.updateResolverAllowServer(
      idHash,
      newAllowServer,
      newOwner
    );

    let resolver = instance.resolve(idHash, { from: accounts[0] });

    assert.equal(success, true);
    assert.equal(resolver.allowServer, newAllowServer);
    assert.equal(resolver.owner, newOwner);
  });

  it("should delete a primary resolver", async () => {
    const success = await instance.deleteResolver(idHash, {
      from: accounts[0],
    });

    let resolver = instance.resolve(idHash, { from: accounts[0] });

    assert.equal(success, true);
    assert.equal(resolver.isValue, false);
    // optionally check other values
  });

  // TODO: add individual cases (i.e. passing invalid hash)
  it("should create a secondary resolver", async () => {
    const phone = "+11234567890";
    const secondaryHash = sha3(phone);
    await instance.createSecondaryResolver(secondaryHash, idHash, {
      from: accounts[0],
    });

    let resolver = instance.resolve(secondaryHash, { from: accounts[0] });

    assert.equal(resolver.isValue, true);
    assert.equal(resolver.cid, cid);
    // optionally check other values
  });

  it("should get a secondary resolver", async () => {
    const phone = "+11234567890";
    const secondaryHash = sha3(phone);
    let resolver = instance.resolve(secondaryHash, { from: accounts[0] });

    assert.equal(resolver.isValue, true);
    assert.equal(resolver.cid, cid);
  });

  it("should delete a secondary resolver", async () => {
    const phone = "+11234567890";
    const secondaryHash = sha3(phone);
    const success = await instance.deleteSecondaryResolver(secondaryHash, {
      from: accounts[0],
    }); // this might come back non-existent?

    let resolver = instance.resolve(secondaryHash, { from: accounts[0] });

    assert.equal(success, true);
    assert.equal(resolver.isValue, false);
  });

  // TODO: add individual cases (i.e. passing empty address)
  it("should update the server signer", async () => {
    const newServerSigner = "0x7D504D497b0ca5386F640aDeA2bb86441462d109";
    await instance.changeServerSigner(newServerSigner, { from: accounts[0] }); // this call MUST be from contract owner

    assert.equal(instance.serverSigner, newServerSigner);
  });

  it("should fail authorization", async () => {
    await instance.updateResolverCid(idHash, newCid, newSignature, {
      from: accounts[3], // non-owner or server signer account
    });
    // TODO: assert failure here due to require()
  });

  it("should fail validation", async () => {
    let modifiedSignature = signature;
    modifiedSignature[10] = "A"; // random value change

    await instance.createResolver(idHash, cid, modifiedSignature, true, {
      from: accounts[0],
    });

    // TODO: assert failure here due to require()
  });
});
