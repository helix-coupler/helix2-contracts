//SPDX-License-Identifier: WTFPL v6.9
pragma solidity >0.8.0 <0.9.0;

import "src/Names/iName.sol";
import "src/Bonds/iBond.sol";
import "src/Bonds/iBondResolver.sol";
import "src/Interface/iENS.sol";
import "src/Interface/iHelix2.sol";

/**
 * @dev : Helix2 Resolver Base
 * @notice : sshmatrix (BeenSick Labs)
 */

abstract contract BondResolverBase {
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
    iBOND public BONDS;
    mapping(bytes4 => bool) public supportsInterface;

    /**
     * @dev : setInterface
     * @param sig : signature
     * @param value : boolean
     */
    function setInterface(bytes4 sig, bool value) external onlyDev {
        require(sig != 0xffffffff, "INVALID_INTERFACE_SELECTOR");
        supportsInterface[sig] = value;
    }

    /**
     * @dev : withdraw ether only to Dev (or multi-sig)
     */
    function withdrawEther() external {
        (bool ok, ) = HELIX2.isDev().call{value: address(this).balance}("");
        require(ok, "ETH_TRANSFER_FAILED");
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
contract BondResolver is BondResolverBase {
    struct PublicKey {
        bytes32 x;
        bytes32 y;
    }
    mapping(bytes32 => bytes) internal _contenthash;
    mapping(bytes32 => mapping(string => string)) internal _text;
    mapping(bytes32 => mapping(uint256 => bytes)) internal _addrs;
    mapping(bytes32 => PublicKey) public pubkey;

    event NewTextRecord(
        bytes32 indexed bondhash,
        string indexed key,
        string value
    );
    event NewAddr(bytes32 indexed bondhash, address addr);
    event NewAddr2(
        bytes32 indexed bondhash,
        uint256 coinType,
        bytes newAddress
    );
    event NewContenthash(bytes32 indexed bondhash, bytes _contenthash);
    event NewPubkey(bytes32 indexed bondhash, bytes32 x, bytes32 y);

    /// @notice : encoder: https://gist.github.com/sshmatrix/6ed02d73e439a5773c5a2aa7bd0f90f9
    /// @dev : default contenthash (encoded from IPNS hash)
    //  IPNS : k51qzi5uqu5dkco782zzu13xwmoz6yijezzk326uo0097cr8tits04eryrf5n3
    function DefaultContenthash() external view returns (bytes memory) {
        return _contenthash[bytes32(0)];
    }

    constructor(address _helix2) {
        HELIX2 = iHELIX2(_helix2);
        supportsInterface[iBondResolver.addr.selector] = true;
        supportsInterface[iBondResolver.addr2.selector] = true;
        supportsInterface[iBondResolver.contenthash.selector] = true;
        supportsInterface[iBondResolver.pubkey.selector] = true;
        supportsInterface[iBondResolver.text.selector] = true;
        _contenthash[
            bytes32(0)
        ] = hex"e5010172002408011220a7448dcfc00e746c22e238de5c1e3b6fb97bae0949e47741b4e0ae8e929abd4f";
    }

    /**
     * @dev : verifies ownership of bondhash
     * @param bondhash : hash of bond
     */
    modifier onlyOwner(bytes32 bondhash) {
        require(block.timestamp < BONDS.expiry(bondhash), "BOND_EXPIRED"); // expiry check
        require(
            msg.sender == NAMES.owner(BONDS.cation(bondhash)),
            "NOT_AUTHORISED"
        );
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
     * @param bondhash : hash of bond
     */
    function contenthash(
        bytes32 bondhash
    ) public view returns (bytes memory _hash) {
        require(block.timestamp < BONDS.expiry(bondhash), "BOND_EXPIRED"); // expiry check
        _hash = _contenthash[bondhash];
        if (_hash.length == 0) {
            _hash = _contenthash[bytes32(0)];
        }
    }

    /**
     * @dev : defaults to address of cation if no address is set for Ethereum [60]
     * @param bondhash : hash of bond
     * @return : resolved address
     */
    function addr(bytes32 bondhash) external view returns (address payable) {
        require(block.timestamp < BONDS.expiry(bondhash), "BOND_EXPIRED"); // expiry check
        bytes memory _addr = _addrs[bondhash][60];
        if (_addr.length == 0) {
            return payable(NAMES.owner(BONDS.cation(bondhash)));
        }
        return payable(address(uint160(uint256(bytes32(_addr)))));
    }

    /**
     * @dev : queries text records
     * @param bondhash : hash of bond
     * @param key : key to query
     * @return value of text record
     */
    function text(
        bytes32 bondhash,
        string calldata key
    ) external view returns (string memory value) {
        require(block.timestamp < BONDS.expiry(bondhash), "BOND_EXPIRED"); // expiry check
        return _text[bondhash][key];
    }

    /**
     * @dev : resolves address for <coin>; if no ethereum address [60] is set, resolve to address of cation
     * @param bondhash : hash of bond
     * @param coinType : <coin>
     * @return _addr : resolved address
     */
    function addr2(
        bytes32 bondhash,
        uint256 coinType
    ) external view returns (address payable) {
        require(block.timestamp < BONDS.expiry(bondhash), "BOND_EXPIRED"); // expiry check
        bytes memory _addr = _addrs[bondhash][coinType];
        if (_addr.length == 0 && coinType == 60) {
            _addr = abi.encodePacked(NAMES.owner(BONDS.cation(bondhash)));
        }
        return payable(address(uint160(uint256(bytes32(_addr)))));
    }

    /**
     * @dev : changes contenthash
     * @param bondhash: bondhash
     * @param _hash: new contenthash
     */
    function setContenthash(
        bytes32 bondhash,
        bytes memory _hash
    ) external onlyOwner(bondhash) {
        _contenthash[bondhash] = _hash;
        emit NewContenthash(bondhash, _hash);
    }

    /**
     * @dev : changes address
     * @param bondhash : hash of bond
     * @param _addr : new address
     */
    function setAddress(
        bytes32 bondhash,
        address _addr
    ) external onlyOwner(bondhash) {
        _addrs[bondhash][60] = abi.encodePacked(_addr);
        emit NewAddr(bondhash, _addr);
    }

    /**
     * @dev : changes address for <coin>
     * @param bondhash : hash of bond
     * @param coinType : <coin>
     */
    function setAddressCoin(
        bytes32 bondhash,
        uint256 coinType,
        bytes memory _addr
    ) external onlyOwner(bondhash) {
        _addrs[bondhash][coinType] = _addr;
        emit NewAddr2(bondhash, coinType, _addr);
    }

    /**
     * @dev : changes public key record
     * @param bondhash : hash of bond
     * @param x : x-coordinate on elliptic curve
     * @param y : y-coordinate on elliptic curve
     */
    function setPubkey(
        bytes32 bondhash,
        bytes32 x,
        bytes32 y
    ) external onlyOwner(bondhash) {
        pubkey[bondhash] = PublicKey(x, y);
        emit NewPubkey(bondhash, x, y);
    }

    /**
     * @dev : sets default text record
     * @param key : key to change
     * @param value : value to set
     */
    function setDefaultText(
        string calldata key,
        string calldata value
    ) external onlyDev {
        _text[bytes32(0)][key] = value;
        emit NewTextRecord(bytes32(0), key, value);
    }

    /**
     * @dev : changes text record
     * @param bondhash : hash of bond
     * @param key : key to change
     * @param value : value to set
     */
    function setText(
        bytes32 bondhash,
        string calldata key,
        string calldata value
    ) external onlyOwner(bondhash) {
        _text[bondhash][key] = value;
        emit NewTextRecord(bondhash, key, value);
    }
}
