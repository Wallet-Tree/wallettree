const Resolver = artifacts.require("Resolver");

contract("Resolver", (accounts) => {
  it("should create a primary resolver", async () => {
    const resolverInstance = await Resolver.deployed();
    const contentHash = "QmRAQB6YaCyidP37UdDnjFY5vQuiBrcqdyoW1CuDgwxkD4";
    await resolverInstance.createResolver(
      "joshua@wallettree.me",
      contentHash,
      true,
      { from: accounts[0] }
    );
    const result = await resolverInstance.getContentHash(
      "joshua@wallettree.me",
      { from: accounts[0] }
    );
    assert.equal(result, contentHash, "Resolver was not correctly set");
  });

  // it("should update a primary resolver", async () => {});

  // it("should delete a primary resolver", async () => {});

  // it("should create a secondary resolver", async () => {});

  // it("should delete a secondary resolver", async () => {});

  // it("should update the server signer", async () => {});

  // it("should get a primary resolver", async () => {});

  // it("should get a secondary resolver", async () => {});

  // it("should get a content hash", async () => {});

  // it("should fail authorization", async () => {});
});
