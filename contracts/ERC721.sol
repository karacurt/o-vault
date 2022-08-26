pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MyNft is
  AccessControlEnumerable,
  ERC721
{
  using Counters for Counters.Counter;

  bytes32 private constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
  bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 private constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  Counters.Counter private _tokenIdTracker;

  string public baseTokenURI;

  constructor(
    string memory name,
    string memory symbol,
    string memory _baseTokenURI
  ) ERC721(name, symbol) {
    baseTokenURI = _baseTokenURI;

    address msgSender = _msgSender();
    _setupRole(DEFAULT_ADMIN_ROLE, msgSender);
    _setupRole(MINTER_ROLE, msgSender);
    _setupRole(OPERATOR_ROLE, msgSender);
    _setupRole(PAUSER_ROLE, msgSender);
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`.
   */
  function _baseURI() internal view override returns (string memory) {
    return baseTokenURI;
  }

  /**
   * @notice Set the BaseURI to `uri`
   * @param uri The new BaseURI
   */
  function setBaseURI(string calldata uri) public onlyRole(OPERATOR_ROLE) {
    baseTokenURI = uri;
  }

  /**
   * @dev Mandatory override
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  /**
   * @dev Mandatory override
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(AccessControlEnumerable, ERC721)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function mint(address to) onlyRole(MINTER_ROLE) external {
    _safeMint(to, _tokenIdTracker.current());
    _tokenIdTracker.increment();
  }
 
}
