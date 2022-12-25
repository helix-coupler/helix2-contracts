//SPDX-License-Identifier: WTFPL v6.9
pragma solidity >0.8.0 <0.9.0;

import "src/Interface/iNameResolver.sol";
import "src/Interface/iENS.sol";
import "src/Interface/iHelix2.sol";
import "src/Interface/iERC721.sol";
import "src/Interface/iName.sol";

/**
 * @dev : Helix2 Resolver Base
 * @notice : sshmatrix (BeenSick Labs)
 */
abstract contract NameResolverBase {
    /// Events
    error OnlyDev(address _dev, address _you);

    /// @dev : Modifier to allow only dev
    modifier onlyDev() {
        if (msg.sender != HELIX2.isDev()) {
            revert OnlyDev(HELIX2.isDev(), msg.sender);
        }
        _;
    }

    /// @dev : Helix2 Contract Interface
    iHELIX2 public HELIX2;
    iNAME public NAMES;
    mapping (bytes4 => bool) public supportsInterface;

    /**
     * @dev : setInterface
     * @param sig : signature
     * @param value : boolean
     */
    function setInterface(bytes4 sig, bool value) external payable onlyDev {
        require(sig != 0xffffffff, "INVALID_INTERFACE_SELECTOR");
        supportsInterface[sig] = value;
    }

    /**
     * @dev : withdraw ether only to Dev (or multi-sig)
     */
    function withdrawEther() external payable {
        (bool ok,) = HELIX2.isDev().call{value: address(this).balance}("");
        require(ok, "ETH_TRANSFER_FAILED");
    }

    /**
     * @dev : to be used in case some tokens get locked in the contract
     * @param token : token to release
     * @param value : token balance to withdraw
     */
    function withdrawToken(address token, uint256 value) external payable {
        require(token != address(this), "RESOLVER_LOCKED");
        iERC721(token).transferFrom(address(this), HELIX2.isDev(), value);
    }

    // @dev : Revert on fallback
    fallback() external payable {
        revert();
    }

    /// @dev : Revert on receive
    receive() external payable {
        revert();
    }
}

/**
 * @dev : Helix2 Resolver
 */
contract NameResolver is NameResolverBase {

    struct PublicKey { bytes32 x; bytes32 y; }
    mapping(bytes32 => bytes) internal _contenthash;
    mapping(bytes32 => mapping(string => string)) internal _text;
    mapping(bytes32 => mapping(uint256 => bytes)) internal _addrs;
    mapping(bytes32 => PublicKey) public pubkey;

    event NewTextRecord(bytes32 indexed namehash, string indexed key, string value);
    event NewAddr(bytes32 indexed namehash, address addr);
    event NewAddr2(bytes32 indexed namehash, uint256 coinType, bytes newAddress);
    event NewContenthash(bytes32 indexed namehash, bytes _contenthash);
    event NewPubkey(bytes32 indexed namehash, bytes32 x, bytes32 y);

    /// @notice : encoder: https://gist.github.com/sshmatrix/6ed02d73e439a5773c5a2aa7bd0f90f9
    /// @dev : default contenthash (encoded from IPNS hash)
    //  IPNS : k51qzi5uqu5dkco782zzu13xwmoz6yijezzk326uo0097cr8tits04eryrf5n3
    function DefaultContenthash() external view returns (bytes memory) {
        return _contenthash[bytes32(0)];
    }

    constructor(address _helix2) {
        HELIX2 = iHELIX2(_helix2);
        supportsInterface[iNameResolver.addr.selector] = true;
        supportsInterface[iNameResolver.addr2.selector] = true;
        supportsInterface[iNameResolver.contenthash.selector] = true;
        supportsInterface[iNameResolver.pubkey.selector] = true;
        supportsInterface[iNameResolver.text.selector] = true;
        _contenthash[bytes32(0)] =
            hex"e5010172002408011220a7448dcfc00e746c22e238de5c1e3b6fb97bae0949e47741b4e0ae8e929abd4f";
    }

    /**
     * @dev : verifies ownership of namehash
     * @param namehash : hash of name
     */
    modifier onlyOwner(bytes32 namehash) {
        require(msg.sender == NAMES.owner(namehash), "NOT_AUTHORISED");
        _;
    }

    /**
     * @dev : sets default contenthash
     * @param _content : default contenthash to set
     */
    function setDefaultContenthash(bytes memory _content) external onlyDev {
        _contenthash[bytes32(0)] = _content;
    }

    /**
     * @dev : returns default contenhash if no contenthash set
     * @param namehash : hash of name
     */
    function contenthash(bytes32 namehash) public view returns (bytes memory _hash) {
        _hash = _contenthash[namehash];
        if (_hash.length == 0) {
            _hash = _contenthash[bytes32(0)];
        }
    }

    /**
     * @dev : changes contenthash
     * @param namehash: namehash
     * @param _hash: new contenthash
     */
    function setContenthash(bytes32 namehash, bytes memory _hash) external onlyOwner(namehash) {
        _contenthash[namehash] = _hash;
        emit NewContenthash(namehash, _hash);
    }

    /**
     * @dev : changes address
     * @param namehash : hash of name
     * @param _addr : new address
     */
    function setAddress(bytes32 namehash, address _addr) external onlyOwner(namehash) {
        _addrs[namehash][60] = abi.encodePacked(_addr);
        emit NewAddr(namehash, _addr);
    }
    
    /**
     * @dev : changes address for <coin>
     * @param namehash : hash of name
     * @param coinType : <coin>
     */
    function setAddressCoin(bytes32 namehash, uint256 coinType, bytes memory _addr) external onlyOwner(namehash) {
        _addrs[namehash][coinType] = _addr;
        emit NewAddr2(namehash, coinType, _addr);
    }

    /**
     * @dev : defaults to owner if no address is set for Ethereum [60]
     * @param namehash : hash of name
     * @return : resolved address
     */
    function addr(bytes32 namehash) external view returns (address payable) {
        bytes memory _addr = _addrs[namehash][60];
        if (_addr.length == 0) {
            return payable(NAMES.owner(namehash));
        }
        return payable(address(uint160(uint256(bytes32(_addr)))));
    }

    /**
     * @dev : resolves address for <coin>; if no ethereum address [60] is set, resolve to owner
     * @param namehash : hash of name
     * @param coinType : <coin>
     * @return _addr : resolved address
     */
    function addr2(bytes32 namehash, uint256 coinType) external view returns (address payable) {
        bytes memory _addr = _addrs[namehash][coinType];
        if (_addr.length == 0 && coinType == 60) {
            _addr = abi.encodePacked(NAMES.owner(namehash));
        }
        return payable(address(uint160(uint256(bytes32(_addr)))));
    }

    /**
     * @dev : changes public key record
     * @param namehash : hash of name
     * @param x : x-coordinate on elliptic curve
     * @param y : y-coordinate on elliptic curve
     */
    function setPubkey(bytes32 namehash, bytes32 x, bytes32 y) external onlyOwner(namehash) {
        pubkey[namehash] = PublicKey(x, y);
        emit NewPubkey(namehash, x, y);
    }

    /**
     * @dev : sets default text record <onlyDev>
     * @param key : key to change
     * @param value : value to set
     */
    function setDefaultText(string calldata key, string calldata value) external onlyDev {
        _text[bytes32(0)][key] = value;
        emit NewTextRecord(bytes32(0), key, value);
    }

    /**
     * @dev : changes text record
     * @param namehash : hash of name
     * @param key : key to change
     * @param value : value to set
     */
    function setText(bytes32 namehash, string calldata key, string calldata value) external onlyOwner(namehash) {
        _text[namehash][key] = value;
        emit NewTextRecord(namehash, key, value);
    }

    /**
     * @dev : queries text records
     * @param namehash : hash of name
     * @param key : key to query
     * @return value of text record
     */
    function text(bytes32 namehash, string calldata key) external view returns (string memory value) {
        return _text[namehash][key];
    }
}
