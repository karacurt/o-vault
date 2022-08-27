
pragma solidity ^0.8.9;
import './interfaces/IERC721.sol';

contract NftVault {

    bytes32 private constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    mapping(address => bytes32) private trustedOperators;
    address admin;

    mapping(address => bool) public trustedTokens;
    address[] public trustedTokenAddresses;

    mapping(address => mapping(uint256 => address)) internal tokenToIdToOwner;
    mapping(address => mapping(address => TokenInfo)) internal playerTokens;
    mapping(address => uint256) internal playerToBalance;
    uint256 public vaultBalance;

    address[] public holders;
    mapping(address => uint256) private holderToIndex;

    struct TokenInfo {
        uint256[] ids;
        mapping(uint256 => uint256) idToIndex;
    }

    struct TrustedTokens {
        address nftAddress;
        bool isTrusted;
    }

    event DepositedNft(address indexed depositor, address indexed
    nftAddress, uint tokenId);

    event WithdrewNft(address indexed owner, address indexed nftAddress,
    uint tokenId);

    event WithdrewNftByAdmin(address indexed owner, address indexed nftAddress, uint tokenId);

    constructor() public {
        admin = msg.sender;
    }

    modifier isAdmin {
        require(msg.sender == admin, 'INV_ADMIN');
        _;
    }

    modifier isTrustedToken(address _nftAddress) {
        require(trustedTokens[_nftAddress], 'INV_TRUSTED_TOKEN');
        _;
    }

    function setTrustedTokens(TrustedTokens[]  calldata _trustedTokens) external isAdmin {
        delete trustedTokenAddresses;
        for(uint i = 0; i < _trustedTokens.length; i++){
            require(_trustedTokens[i].nftAddress != address(0),'INV_ADDRESS');
            trustedTokens[_trustedTokens[i].nftAddress] = _trustedTokens[i].isTrusted;
            trustedTokenAddresses.push(_trustedTokens[i].nftAddress);
        }
    }

    function _addPlayerInfo(uint256 _id, address _ownerAddress, address _tokenAddress) internal {
        uint256[] storage ids = playerTokens[_ownerAddress][_tokenAddress].ids;

        if (ids.length == 0) {
        ids.push(0);
        }

        ids.push(_id);
        playerTokens[_ownerAddress][_tokenAddress].idToIndex[_id] = ids.length - 1;
    }

    function _deletePlayerInfo(uint256 _id, address _ownerAddress, address _tokenAddress) internal {
        uint256[] storage ids = playerTokens[_ownerAddress][_tokenAddress].ids;
        uint256 index = playerTokens[_ownerAddress][_tokenAddress].idToIndex[_id];
        require(index < ids.length && index != 0, "Invalid index");

        uint256 lastId = ids[ids.length - 1];

        if (lastId != _id) {
        ids[index] = lastId;
        playerTokens[_ownerAddress][_tokenAddress].idToIndex[lastId] = index;
        }

        ids.pop();
        delete playerTokens[_ownerAddress][_tokenAddress].idToIndex[_id];
    }

    function _addHolder(address _holderAddress) internal {
       if(holderToIndex[_holderAddress] != 0) return;

        if (holders.length == 0) {
            holders.push(address(0));
        }

        holders.push(_holderAddress);
        holderToIndex[_holderAddress] = holders.length - 1;
    }

    function _deleteHolder(address _holderAddress) internal {
        uint256 index = holderToIndex[_holderAddress];
        require(index < holders.length && index != 0, "Invalid index");

        address lastHolder = holders[holders.length - 1];

        if (lastHolder != _holderAddress) {
        holders[index] = lastHolder;
        holderToIndex[lastHolder] = index;
        }

        holders.pop();
        delete holderToIndex[_holderAddress];
    }

    function balance() public view returns (uint) {
        return vaultBalance;
    }

    function balanceOf(address _owner) public view returns (uint) {
        return playerToBalance[_owner];
    }
    
    function deposit(address _nftAddress, uint256 _tokenId) external isTrustedToken(_nftAddress){
        address tokenOwner = IERC721(_nftAddress).ownerOf(_tokenId);
        require(msg.sender == tokenOwner, 'INV_OWNER');
        require(tokenOwner != address(this), "ALREADY_DEPOSITED");
        
        tokenToIdToOwner[_nftAddress][_tokenId] = msg.sender;
        _addPlayerInfo(_tokenId, msg.sender, _nftAddress);

        if(playerToBalance[msg.sender] == 0) {
            _addHolder(msg.sender);
        }

        playerToBalance[msg.sender]++;
        vaultBalance++;

        emit DepositedNft(msg.sender, _nftAddress, _tokenId);

        IERC721(_nftAddress).transferFrom(msg.sender, address(this), _tokenId);
    }
 
    function withdraw(address _nftAddress, uint256 _tokenId) public isTrustedToken(_nftAddress) {
        address tokenOwner = tokenToIdToOwner[_nftAddress][_tokenId];
        require(tokenOwner != address(0), "NOT_DEPOSITED");

        if(msg.sender != admin){
            require(tokenOwner == msg.sender, "INV_OWNER");
        }

        tokenToIdToOwner[_nftAddress][_tokenId] = address(0);
        _deletePlayerInfo(_tokenId, tokenOwner, _nftAddress);

        playerToBalance[tokenOwner]--;
        vaultBalance--;

        if( playerToBalance[tokenOwner] == 0){
            _deleteHolder(tokenOwner);
        }

        emit WithdrewNft(tokenOwner, _nftAddress, _tokenId);

        IERC721(_nftAddress).transferFrom(address(this), tokenOwner, _tokenId);
    }

    function withdrawByAdmin(address _nftAddress, uint256 _tokenId) external isAdmin {
        withdraw(_nftAddress, _tokenId);
    }
   
    function withdrawAll() external{
        for(uint i = 0; i < trustedTokenAddresses.length; i++){
            address nftAddress = trustedTokenAddresses[i];
            uint256[] memory _ids = playerTokens[msg.sender][nftAddress].ids;
            for(uint j = 1; j < _ids.length; j++){
                uint256 id = _ids[j];
                withdraw(nftAddress, id);
            }
        }  
    }
    
    function withdrawAllByAdmin() external isAdmin {
        for(uint h = 0; h < holders.length; h++){
            address holder = holders[h];
            for(uint i = 0; i < trustedTokenAddresses.length; i++){
                address nftAddress = trustedTokenAddresses[i];
                uint256[] memory _ids = playerTokens[holder][nftAddress].ids;
                    for(uint j = 1; j < _ids.length; j++){
                        uint256 id = _ids[j];
                        withdraw(nftAddress, id);
                    }
            }  
        }
    } 
}