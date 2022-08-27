import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BigNumber, Contract } from "ethers";

export async function batchMint(
  quantity: Number,
  contract: Contract,
  minter: SignerWithAddress,
  to: string
): Promise<BigNumber[]> {
  const ids: BigNumber[] = [];
  for (let i = 0; i < quantity; i++) {
    const tx = await contract.connect(minter).mint(to);
    const receipt = await tx.wait();
    const id = receipt.events[0].args.tokenId;
    ids.push(id);
  }

  return ids;
}

export async function batchDeposit(
  ids: BigNumber[],
  owner: SignerWithAddress,
  contract: Contract,
  tokenAddress: string
) {
  for (const id of ids) {
    await contract.connect(owner).deposit(tokenAddress, id);
  }
}
