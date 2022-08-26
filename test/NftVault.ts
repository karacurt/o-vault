import { expect } from "chai";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";
import { ContractFactory, Contract } from "ethers";

interface TrustedTokens {
  address: string;
  isTrusted: boolean;
}

describe("NftVault", function () {
  let deployer: SignerWithAddress;
  let operator: SignerWithAddress;
  let player1: SignerWithAddress;
  let player2: SignerWithAddress;

  let Vault: ContractFactory;
  let vault: Contract;

  let Nft: ContractFactory;
  let nft: Contract;

  const zeroAddress = ethers.constants.AddressZero;

  before(async function () {
    [deployer, operator, player1, player2] = await ethers.getSigners();
  });

  beforeEach(async function () {
    Nft = await ethers.getContractFactory("ERC721");
    nft = await Nft.deploy("NonFungibleToken", "NFT", "https://nft.com/");

    Vault = await ethers.getContractFactory("NftVault");
    vault = await Vault.deploy(operator.address);
    await vault.deployed();

    const trustedTokens: TrustedTokens[] = [
      { address: nft.address, isTrusted: true },
    ];

    await vault.connect(operator).setTrustedTokens(trustedTokens);

    await nft.connect(operator).mint(player1.address, 1);
  });

  describe("Deployment", function () {
    it("should NOT deploy if operator is invalid", async function () {
      const contract = await ethers.getContractFactory("NftVault");
      await expect(contract.deploy([zeroAddress])).to.be.revertedWith(
        "INV_ADDRESS"
      );
    });
  });

  describe("Deposits", function () {
    const nftId = 1;
    it("should deposit NFT", async function () {
      await expect(vault.deposit(nft.address, 1)).to.emit(vault, "Deposit");
    });
  });

  describe("Withdrawals", function () {
    const nftId = 1;
    it("should withdraw NFT", async function () {
      await expect(vault.deposit(nft.address, nftId)).to.emit(vault, "Deposit");
      await expect(vault.withdraw(nft.address, nftId)).to.emit(
        vault,
        "Withdraw"
      );
    });
    it("should NOT withdraw NFT if balance is 0", async function () {
      await expect(vault.withdraw(nft.address, nftId)).to.be.revertedWith(
        "INV_BALANCE"
      );
    });
    it("should let admin withdraw on behaf of player", async function () {
      await expect(vault.deposit(nft.address, nftId)).to.emit(vault, "Deposit");
      await expect(
        vault.connect(operator).withdraw(nft.address, nftId)
      ).to.emit(vault, "Withdraw");
    });
  });
});
