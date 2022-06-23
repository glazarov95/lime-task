const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
beforeEach(async function () {
  [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
});

describe("addProduct", function () {
  it("Should add new product", async function () {
    const Store = await ethers.getContractFactory("Store", owner);
    const store = await Store.deploy();
    await store.deployed();

    await store.addProduct("Book", 10);

    await expect(store.getProductById(0)).to.be.not.revertedWith(
      "This product does not exist!"
    );
  });
});

describe("addProductNotOwner", function () {
  it("Should throw an error", async function () {
    const Store = await ethers.getContractFactory("Store", owner);
    const store = await Store.deploy();
    await store.deployed();

    await expect(
      store.connect(addr1).addProduct("Book", 10)
    ).to.be.revertedWith("Not invoked by the owner!");
  });
});

describe("buyProduct", function () {
  it("Should buy product", async function () {
    const Store = await ethers.getContractFactory("Store", owner);
    const store = await Store.deploy();
    await store.deployed();

    await store.addProduct("Book", 10);

    await store.buyProduct(0);

    const buyers = await store.getProductBuyersById(0);
    assert(buyers[0] == owner.address);
  });
});

describe("buyProduct", function () {
  it("Should buy product", async function () {
    const Store = await ethers.getContractFactory("Store", owner);
    const store = await Store.deploy();
    await store.deployed();

    await store.addProduct("Book", 10);

    await store.buyProduct(0);

    const product = await store.getProductById(0);
    assert(product.quantity == 9);
  });
});

describe("refundProduct", function () {
  it("Should refund product", async function () {
    const Store = await ethers.getContractFactory("Store", owner);
    const store = await Store.deploy();
    await store.deployed();

    await store.addProduct("Book", 10);
    await store.buyProduct(0);
    await store.refundProduct(0);

    const product = await store.getProductById(0);
    assert(product.quantity == 10);
  });
});

describe("notRefundProduct", function () {
  it("Should not refund product, due to refund policy", async function () {
    const Store = await ethers.getContractFactory("Store", owner);
    const store = await Store.deploy();
    await store.deployed();
    await store.setRefundPolicyNumber(1);
    await store.addProduct("Book", 10);

    await store.buyProduct(0);
    await store.connect(addr1).buyProduct(0);

    await expect(store.refundProduct(0)).to.be.revertedWith(
      "Sorry, your request for refund has been denied."
    );
  });
});

describe("buyProductTwice", function () {
  it("Should not be able to buy product twice", async function () {
    const Store = await ethers.getContractFactory("Store", owner);
    const store = await Store.deploy();
    await store.deployed();

    await store.addProduct("Book", 10);

    await store.buyProduct(0);
    await expect(store.buyProduct(0)).to.be.revertedWith(
      "You cannot buy the same product more than once!"
    );
  });
});

describe("refundNotBoughtProduct", function () {
  it("Should not be able to refund not bought product", async function () {
    const Store = await ethers.getContractFactory("Store", owner);
    const store = await Store.deploy();
    await store.deployed();

    await store.addProduct("Book", 10);

    await expect(store.refundProduct(0)).to.be.revertedWith(
      "You've already returned your product or didn't even bought it."
    );
  });
});

describe("updateProduct", function () {
  it("Should update product quantity", async function () {
    const Store = await ethers.getContractFactory("Store", owner);
    const store = await Store.deploy();
    await store.deployed();

    await store.addProduct("Book", 10);

    await store.updateProductQuantity(0, 20);

    const product = await store.getProductById(0);
    assert(product.quantity == 20);
  });
});

