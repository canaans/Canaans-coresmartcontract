const { ethers, upgrades } = require("hardhat");
const { expect } = require("chai");
const { keccak256, defaultAbiCoder, toUtf8Bytes } = ethers.utils;
const {
  log,
  waitingForReceipt,
  generateWallets,
  getMintMsgHash,
  generateSignatures,
  assertRevert,
  generateRandomId,
} = require("./utils");

describe("Rabbi", () => {
  let maintainer, contractAddress, provider, factory;
  let wallets, validators;
  let multisigThreshold,
    chainId,
    DOMAIN_SEPARATOR,
    unlockTypeHash,
    changeValidatorsTypeHash;
  let abi, iface;
  let nft_abi, nft_iface;
  let nft;
  let signer;

  before(async function () {
    // disable timeout
    this.timeout(0);

    [signer] = await ethers.getSigners();
    adminAddress = signer.address;

    // get validators
    wallets = generateWallets(7);
    validators = wallets.map((wallet) => wallet.address);
    multisigThreshold = 5;
    chainId = await signer.getChainId();

    // deploy Maintainer
    factory = await ethers.getContractFactory(
      "contracts/Maintainer.sol:Maintainer"
    );
    maintainer = await upgrades.deployProxy(factory, [
      validators,
      multisigThreshold,
    ]);
    await maintainer.deployTransaction.wait(1);

    contractAddress = maintainer.address;
    provider = maintainer.provider;

    abi = require("../artifacts/contracts/Maintainer.sol/Maintainer.json").abi;
    iface = new ethers.utils.Interface(abi);

    //deploy NFT Contract
    const NFTFactory = await ethers.getContractFactory(
      "contracts/nft.sol:CANAANS"
    );

    nft = await upgrades.deployProxy(NFTFactory, [maintainer.address]);
    await nft.deployTransaction.wait(1);

    nft_abi = require("../artifacts/contracts/nft.sol/CANAANS.json").abi;
    nft_iface = new ethers.utils.Interface(nft_abi);

  });

  describe("correct case", async function () {
    // disable timeout
    this.timeout(0);

    it("check SIGNATURE_SIZE, NAME, DOMAIN_SEPARATOR", async () => {
      expect(await maintainer.SIGNATURE_SIZE()).to.eq(65);

      const name = "Validator Maintainer";
      expect(await maintainer.NAME_712()).to.eq(name);

      mintTypeHash = keccak256(
        toUtf8Bytes("mintRabbi(address to,bytes32 seed,uint256 expiredTime)")
      );
      expect(await nft.MINT_TYPEHASH()).to.eq(mintTypeHash);

      DOMAIN_SEPARATOR = keccak256(
        defaultAbiCoder.encode(
          ["bytes32", "bytes32", "bytes32", "uint256", "address"],
          [
            keccak256(
              toUtf8Bytes(
                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
              )
            ),
            keccak256(toUtf8Bytes(name)),
            keccak256(toUtf8Bytes("1")),
            chainId,
            maintainer.address,
          ]
        )
      );
      expect(await maintainer.DOMAIN_SEPARATOR()).to.eq(DOMAIN_SEPARATOR);
    });
    it("should work well for Mint", async function () {
      const expiredTime = Math.floor(Date.now() / 1000) + 86400;
      const msgHash = getMintMsgHash(
        DOMAIN_SEPARATOR,
        mintTypeHash,
        signer.address,
        mintTypeHash, //seed
        expiredTime
      );

      // 2. generate signatures
      let signatures = generateSignatures(
        msgHash,
        wallets.slice(0, multisigThreshold)
      );

      const result = await nft.mintRabbi(signer.address, mintTypeHash, expiredTime, signatures);
      const attr = await nft.Attributes(0); // TokenId
      expect(attr.Faith).to.greaterThan(60).lessThan(110);
      expect(attr.Mana).to.greaterThan(60).lessThan(110);
      expect(attr.Power).to.greaterThan(60).lessThan(110);
    });
  });
});
