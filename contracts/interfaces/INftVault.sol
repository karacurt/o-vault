
interface INftVault {
event DepositedNft(address indexed depositor, address indexed
nftAddress, uint tokenId);
event WithdrewNft(address indexed owner, address indexed nftAddress,
uint tokenId);
event WithdrewNftByAdmin(address indexed owner, address indexed
nftAddress, uint tokenId);
// @notice Deposits an NFT into this vault
// @param nftAddress The address of the NFT contract
// @param tokenId The nft id being deposited
function deposit(address nftAddress, uint tokenId) external;
// @notice Withdraws an NFT from this vault. The withdrawer should bethe
// owner of this nft, otherwise the transaction should be reverted.
// @param nftAddress The address of the nft being withdrawn
// @param tokenId The id of the NFT being withdrawn
function withdraw(address nftAddress, uint tokenId) external;
// @notice This function is only allowed to be called by the admin of this
// contract. The admin is whoever deployed it.
// @param nftAddress The address of the nft being withdrawn
// @param tokenId The id of the NFT being withdrawn
function withdrawByAdmin(address nftAddress, uint tokenId) external;
// @noltice Withdraw all NFTs that are stored in this contract from the caller
function withdrawAll() external;
// @noltice Withdraw all NFTs that are stored in this contract to all holders.
// After calling this function, the vault should be empty.
function withdrawAllByAdmin() external;
}