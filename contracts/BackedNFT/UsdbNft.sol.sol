// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./NonBlockingReceiver.sol";
import "./ERC721A.sol";
import "./ERC721APausable.sol";

abstract contract ERC721URIStorage is ERC721A {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) internal _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}


/// @title A LayerZero USDBNonFungibleToken
/// @author Kris
/// @notice You can use this to mint NFT and transfer across chain
/// @dev All function calls are currently implemented without side effects
contract USDBNFT is ERC721A,ERC721URIStorage, ERC721APausable, 
Ownable, AccessControl, NonblockingReceiver, ILayerZeroUserApplicationConfig {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public _totalSupply;
    string public baseTokenURI;
    uint256 maxMint;

    uint256 gas = 350000;

    event ReceiveNFT(
        uint16 _srcChainId,
        address _from,
        uint256 _tokenId,
        uint256 counter
    );


    /// @notice Constructor for the USDBNonFungibleToken
    /// @param _baseTokenURI the Uniform Resource Identifier (URI) for tokenId token
    /// @param _layerZeroEndpoint handles message transmission across chains
    /// @param _maxMint the max number of mints on this chain
    constructor(
        string memory _baseTokenURI,
        address _layerZeroEndpoint,
        uint256 _maxMint
    )
    ERC721A("USDB Backed NFT", "USDB-NFT"){
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, msg.sender);

        setBaseURI(_baseTokenURI);
        endpoint = ILayerZeroEndpoint(_layerZeroEndpoint);
        maxMint = _maxMint;
    }

    /// @notice Set the baseTokenURI
    /// @param _baseTokenURI to set
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /// @notice Get the base URI
    function _baseURI() override public view returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
     /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _beforeTokenTransfers(address from, address to, uint256 tokenId, uint256 quantity) internal whenNotPaused override(ERC721A, ERC721APausable) {
        super._beforeTokenTransfers(from, to, tokenId, quantity);
    }
    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /// @notice Mint your USDBNonFungibleToken
    function mint(address wallet, string memory uri) whenNotPaused external returns(uint256) {
        require(hasRole(MINTER_ROLE, _msgSender()), "USDBNFT: must have minter role to mint");
        require(_totalSupply + 1 <= maxMint, "USDBNFT: Max limit reached");
        uint256 tokenId = _tokenIds.current();
        _safeMint(wallet, 1);

        //string memory tokenURISuffix = string(abi.encodePacked(toString(tokenId),  ".json"));
        setTokenURI(tokenId, uri);
        _tokenIds.increment();
        _totalSupply = _totalSupply.add(1);

        return _tokenIds.current();
    }
    function setRole(address minter) public onlyOwner {
        _setupRole(MINTER_ROLE, minter);
    } 
    function _burn(uint256 tokenId) internal override(ERC721A, ERC721URIStorage) {
        super._burn(tokenId);
    }
    function currentTokenId() external view returns (uint256) {
        return _tokenIds.current();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
    function ownerOfNftToken(uint256 tokenId) public view returns(address) {
        return ownerOf(tokenId);
    }
    /// @notice Burn USDBNFT_tokenId on source chain and mint on destination chain
    /// @param _chainId the destination chain id you want to transfer too
    /// @param USDBNFT_tokenId the id of the USDBNFT you want to transfer
    function transferUsdbNft(
        uint16 _chainId,
        uint256 USDBNFT_tokenId
    ) public payable {
        require(msg.sender == ownerOf(USDBNFT_tokenId), "Message sender must own the USDBNFT.");
        require(trustedSourceLookup[_chainId].length != 0, "This chain is not a trusted source source.");

        // burn USDBNFT on source chain
        _burn(USDBNFT_tokenId);

        //sub counts of USDBNFT on source chain
        _totalSupply = _totalSupply.sub(1);
        // encode payload w/ sender address and USDBNFT token id
        bytes memory payload = abi.encode(msg.sender, USDBNFT_tokenId);

        // encode adapterParams w/ extra gas for destination chain
        // This example uses 500,000 gas. Your implementation may need more.
        uint16 version = 1;
        bytes memory adapterParams = abi.encodePacked(version, gas);

        // use LayerZero estimateFees for cross chain delivery
        (uint quotedLayerZeroFee, ) = endpoint.estimateFees(_chainId, address(this), payload, false, adapterParams);

        require(msg.value >= quotedLayerZeroFee, "Not enough gas to cover cross chain transfer.");

        endpoint.send{value:msg.value}(
            _chainId,                      // destination chainId
            trustedSourceLookup[_chainId], // destination address of OmnichainNFT
            payload,                       // abi.encode()'ed bytes
            payable(msg.sender),           // refund address
            address(0x0),                  // future parameter
            adapterParams                  // adapterParams
        );
    }
    /// @notice Override the _LzReceive internal function of the NonblockingReceiver
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    /// @dev safe mints the ONFT on your destination chain
    function _LzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal override  {
        (address _dstUsdbNftAddress, uint256 usdbNft_tokenId) = abi.decode(_payload, (address, uint256));
        // mint the tokens
        _safeMint(_dstUsdbNftAddress, usdbNft_tokenId);
        _totalSupply = _totalSupply.add(1);
        emit ReceiveNFT(_srcChainId, _dstUsdbNftAddress, usdbNft_tokenId, _totalSupply);
    }
    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParams
    ) external view returns (uint256 nativeFee, uint256 zroFee) {
        return
            endpoint.estimateFees(
                _dstChainId,
                _userApplication,
                _payload,
                _payInZRO,
                _adapterParams
            );
    }
    //---------------------------DAO CALL----------------------------------------
    // generic config for user Application
    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint256 _configType,
        bytes calldata _config
    ) external override onlyOwner {
        endpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external override onlyOwner {
        endpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external override onlyOwner {
        endpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override onlyOwner {
        endpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    function renounceOwnership() public override onlyOwner {}
}