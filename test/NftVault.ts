import { expect } from "chai";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";
import { ContractFactory, Contract } from "ethers";
import { batchDeposit, batchMint } from "../fixture/NftVaultFixture";

interface TrustedTokens {
  nftAddress: string;
  isTrusted: boolean;
}

describe("NftVault", function () {
  let admin: SignerWithAddress;
  let player1: SignerWithAddress;
  let player2: SignerWithAddress;

  let Vault: ContractFactory;
  let vault: Contract;

  let Nft: ContractFactory;
  let nft: Contract;

  before(async function () {
    [admin, player1, player2] = await ethers.getSigners();
  });

  beforeEach(async function () {
    Nft = await ethers.getContractFactory("MyNft");
    nft = await Nft.connect(admin).deploy(
      "NonFungibleToken",
      "NFT",
      "https://nft.com/"
    );
    await nft.deployed();

    Vault = await ethers.getContractFactory("NftVault");
    vault = await Vault.connect(admin).deploy();
    await vault.deployed();

    const trustedTokens: TrustedTokens[] = [
      { nftAddress: nft.address, isTrusted: true },
    ];

    await vault.connect(admin).setTrustedTokens(trustedTokens);

    await nft.connect(admin).mint(player1.address);
    await nft.connect(player1).setApprovalForAll(vault.address, true);
  });

  describe("Deployment", function () {
    it("should  deploy", async function () {
      const contract = await ethers.getContractFactory("NftVault");
      await expect(contract.deploy()).to.be.fulfilled;
    });
  });

  describe("Deposits", function () {
    const nftId = 0;
    it("should deposit NFT", async function () {
      await expect(vault.connect(player1).deposit(nft.address, nftId)).to.emit(
        vault,
        "DepositedNft"
      );
    });
  });

  describe("Withdrawals", function () {
    const nftId = 0;
    it("should withdraw NFT", async function () {
      await expect(vault.connect(player1).deposit(nft.address, nftId)).to.emit(
        vault,
        "DepositedNft"
      );
      await expect(vault.connect(player1).withdraw(nft.address, nftId)).to.emit(
        vault,
        "WithdrewNft"
      );
    });
    it("should NOT withdraw NFT if balance is 0", async function () {
      await expect(
        vault.connect(player1).withdraw(nft.address, nftId)
      ).to.be.revertedWith("NOT_DEPOSITED");
    });
    it("should let admin withdraw on behaf of player", async function () {
      await expect(vault.connect(player1).deposit(nft.address, nftId)).to.emit(
        vault,
        "DepositedNft"
      );
      await expect(
        vault.connect(admin).withdrawByAdmin(nft.address, nftId)
      ).to.emit(vault, "WithdrewNft");
    });
  });

  describe.only("Withdrawal All", function () {
    beforeEach(async function () {
      const ids = await batchMint(10, nft, admin, player1.address);
      await batchDeposit(ids, player1, vault, nft.address);
    });
    it("should zero out balance if admin withdraw all", async function () {
      await expect(vault.connect(admin).withdrawAllByAdmin()).to.emit(
        vault,
        "WithdrewNft"
      );
      const vaultBalance = await vault.balance();
      expect(vaultBalance).to.be.equal(0);
    });
    it("should NOT let a non-admin withdraw all ", async function () {
      await expect(
        vault.connect(player2).withdrawAllByAdmin()
      ).to.be.revertedWith("INV_ADMIN");
    });
    it("should withdraw all tokens from a player", async function () {
      const playerBalanceBefore = await vault.balanceOf(player1.address);
      expect(playerBalanceBefore).to.be.not.equal(0);

      await expect(vault.connect(player1).withdrawAll()).to.emit(
        vault,
        "WithdrewNft"
      );
      const playerBalanceAfter = await vault.balanceOf(player1.address);
      expect(playerBalanceAfter).to.be.equal(0);
    });
  });
});
