//SPDX-License-Identifier: WTFPL v6.9
pragma solidity >0.8.0 <0.9.0;

import "src/interface/iResolver.sol";
import "src/interface/iENS.sol";
import "src/interface/iHelix2.sol";
import "src/interface/iERC721.sol";

/**
 * @notice : Helix2 Resolver Base
 * @author: sshmatrix (BeenSick Labs)
 */
abstract contract ResolverBase {
    error OnlyDev(address _dev, address _you);

    /// @dev : Modifier to allow only dev
    modifier onlyDev() {
        if (msg.sender != HELIX2.Dev()) {
            revert OnlyDev(HELIX2.Dev(), msg.sender);
        }
        _;
    }

    /// @dev : Helix2 Contract Interface
    iHELIX2 public HELIX2;
    mapping(bytes4 => bool) public supportsInterface;

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
        (bool ok,) = HELIX2.Dev().call{value: address(this).balance}("");
        require(ok, "ETH_TRANSFER_FAILED");
    }

    /**
     * @dev : to be used in case some tokens get locked in the contract
     * @param token : token to release
     * @param value : token balance to withdraw
     */
    function withdrawToken(address token, uint256 value) external payable {
        require(token != address(this), "RESOLVER_LOCKED");
        iERC721(token).transferFrom(address(this), HELIX2.Dev(), value);
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
contract Resolver is ResolverBase {

    struct PublicKey { bytes32 x; bytes32 y; }
    mapping(bytes32 => bytes) internal _contenthash;
    mapping(bytes32 => mapping(string => string)) internal _text;
    mapping(bytes32 => mapping(uint256 => bytes)) internal _addrs;
    mapping(bytes32 => PublicKey) public pubkey;

    event NewTextRecord(bytes32 indexed bond, string indexed key, string value);
    event NewAddr(bytes32 indexed bond, address addr);
    event NewAddr2(bytes32 indexed bond, uint256 coinType, bytes newAddress);
    event NewContenthash(bytes32 indexed bond, bytes _contenthash);
    event NewPubkey(bytes32 indexed bond, bytes32 x, bytes32 y);

    /// @notice : encoder: https://gist.github.com/sshmatrix/6ed02d73e439a5773c5a2aa7bd0f90f9
    /// @dev : default contenthash (encoded from IPNS hash)
    //  IPNS : k51qzi5uqu5dkco782zzu13xwmoz6yijezzk326uo0097cr8tits04eryrf5n3
    function DefaultContenthash() external view returns (bytes memory) {
        return _contenthash[bytes32(0)];
    }

    constructor(address _helix2) {
        HELIX2 = iHELIX2(_helix2);
        supportsInterface[iResolver.addr.selector] = true;
        supportsInterface[iResolver.addr2.selector] = true;
        supportsInterface[iResolver.contenthash.selector] = true;
        supportsInterface[iResolver.pubkey.selector] = true;
        supportsInterface[iResolver.text.selector] = true;
        _contenthash[bytes32(0)] =
            hex"e5010172002408011220a7448dcfc00e746c22e238de5c1e3b6fb97bae0949e47741b4e0ae8e929abd4f";
    }

    /**
     * @dev : verify ownership of bond
     * @param bond : bond
     */
    modifier onlyOwner(bytes32 bond) {
        require(msg.sender == HELIX2.owner(bond), "NOT_AUTHORISED");
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
     * @dev : return default contenhash if no contenthash set
     * @param bond : bond
     */
    function contenthash(bytes32 bond) public view returns (bytes memory _hash) {
        _hash = _contenthash[bond];
        if (_hash.length == 0) {
            _hash = _contenthash[bytes32(0)];
        }
    }

    /**
     * @dev : change contenthash
     * @param bond: bond
     * @param _hash: new contenthash
     */
    function setContenthash(bytes32 bond, bytes memory _hash) external onlyOwner(bond) {
        _contenthash[bond] = _hash;
        emit NewContenthash(bond, _hash);
    }

    /**
     * @dev : change address
     * @param bond : bond
     * @param _addr : new address
     */
    function setAddress(bytes32 bond, address _addr) external onlyOwner(bond) {
        _addrs[bond][60] = abi.encodePacked(_addr);
        emit NewAddr(bond, _addr);
    }
    
    /**
     * @dev : change address for <coin>
     * @param bond : bond
     * @param coinType : <coin>
     */
    function setAddressCoin(bytes32 bond, uint256 coinType, bytes memory _addr) external onlyOwner(bond) {
        _addrs[bond][coinType] = _addr;
        emit NewAddr2(bond, coinType, _addr);
    }

    /**
     * @dev : default to owner if no address is set for Ethereum [60]
     * @param bond : bond
     * @return : resolved address
     */
    function addr(bytes32 bond) external view returns (address payable) {
        bytes memory _addr = _addrs[bond][60];
        if (_addr.length == 0) {
            return payable(HELIX2.owner(bond));
        }
        return payable(address(uint160(uint256(bytes32(_addr)))));
    }

    /**
     * @dev : resolve address for <coin>; if no ethereum address [60] is set, resolve to owner
     * @param bond : bond
     * @param coinType : <coin>
     * @return _addr : resolved address
     */
    function addr2(bytes32 bond, uint256 coinType) external view returns (address payable) {
        bytes memory _addr = _addrs[bond][coinType];
        if (_addr.length == 0 && coinType == 60) {
            _addr = abi.encodePacked(HELIX2.owner(bond));
        }
        return payable(address(uint160(uint256(bytes32(_addr)))));
    }

    /**
     * @dev : change public key record
     * @param bond : bond
     * @param x : x-coordinate on elliptic curve
     * @param y : y-coordinate on elliptic curve
     */
    function setPubkey(bytes32 bond, bytes32 x, bytes32 y) external onlyOwner(bond) {
        pubkey[bond] = PublicKey(x, y);
        emit NewPubkey(bond, x, y);
    }

    /**
     * @dev : set default text record <onlyDev>
     * @param key : key to change
     * @param value : value to set
     */
    function setDefaultText(string calldata key, string calldata value) external onlyDev {
        _text[bytes32(0)][key] = value;
        emit NewTextRecord(bytes32(0), key, value);
    }

    /**
     * @dev : change text record
     * @param bond : bond
     * @param key : key to change
     * @param value : value to set
     */
    function setText(bytes32 bond, string calldata key, string calldata value) external onlyOwner(bond) {
        _text[bond][key] = value;
        emit NewTextRecord(bond, key, value);
    }

    /**
     * @dev : get text records
     * @param bond : bond
     * @param key : key to query
     * @return value : value
     */
    function text(bytes32 bond, string calldata key) external view returns (string memory value) {
        return _text[bond][key];
    }
}
