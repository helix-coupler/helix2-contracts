//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Names/iName.sol";
import "src/Names/iERC721.sol";
import "src/Interface/iERC173.sol";
import "src/Interface/iERC165.sol";
import "src/Interface/iHelix2.sol";
import "src/Oracle/iPriceOracle.sol";
import "src/Utils/LibString.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @notice GitHub: https://github.com/helix-coupler/helix2-contracts
 * @notice README: https://github.com/helix-coupler/resources
 * @dev testnet v0.0.1
 * @title Helix2 Name Registry
 */
contract Helix2NameRegistry {
    using LibString for bytes32[];
    using LibString for bytes32;
    using LibString for address[];
    using LibString for address;
    using LibString for string[];
    using LibString for string;

    /// Interfaces
    iHELIX2 public HELIX2;
    iNAME public PARENT;
    iNAME public STORE;
    iERC721 public ERC721;
    iPriceOracle public PRICES;

    /// @dev : Helix2 Name events
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event NewOwner(bytes32 indexed namehash, address owner);
    event NewController(bytes32 indexed namehash, address controller);
    event NewExpiry(bytes32 indexed namehash, uint expiry);
    event NewResolver(bytes32 indexed namehash, address resolver);
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenID
    );

    /// Dev
    address public Dev;

    /// @dev : Pause/Resume contract
    bool public active = true;
    /// @dev : EIP-165
    mapping(bytes4 => bool) public supportedInterfaces;

    /// Constants
    bytes32 public roothash;
    uint256 public basePrice;
    address public Registrar;
    uint256 public theEnd = 250_000_000_000_000_000; // roughly 80,000,000,000 years in the future

    /**
     * @dev Initialise a new HELIX2 Names Registry
     * @notice
     * @param _helix2 : address of HELIX2 Manager
     * @param _priceOracle : address of HELIX2 Price Oracle
     */
    constructor(address _helix2, address _priceOracle) {
        Dev = msg.sender;
        HELIX2 = iHELIX2(_helix2);
        roothash = HELIX2.getRoothash()[0];
        PRICES = iPriceOracle(_priceOracle);
        basePrice = PRICES.getPrices()[0];
        // Interface
        supportedInterfaces[type(iERC165).interfaceId] = true;
        supportedInterfaces[type(iERC173).interfaceId] = true;
    }

    /// @dev : Modifier to allow only dev
    modifier onlyDev() {
        require(msg.sender == Dev, "NOT_DEV");
        _;
    }

    /**
     * @dev pauses or resumes contract
     */
    function toggleActive() external onlyDev {
        active = !active;
    }

    /**
     * @dev sets new manager and config from therein
     * @notice setConfig() must be called whenever a new manager
     * or Price Oracle is deployed or whenever a config changes in the manager
     * @param _helix2 : address of HELIX2 Manager
     * @param _priceOracle : address of price oracle contract
     * @param _store : address of HELIX2 Name Storage
     */
    function setConfig(
        address _helix2,
        address _priceOracle,
        address _store
    ) external onlyDev {
        if (_helix2 != address(0)) {
            HELIX2 = iHELIX2(_helix2);
            roothash = HELIX2.getRoothash()[0];
            Registrar = HELIX2.getRegistrar()[0];
            PARENT = iNAME(Registrar);
            ERC721 = iERC721(Registrar);
        }
        if (_store != address(0)) {
            STORE = iNAME(_store);
        }
        if (_priceOracle != address(0)) {
            PRICES = iPriceOracle(_priceOracle);
            basePrice = PRICES.getPrices()[0];
        }
    }

    /**
     * @dev returns owner of contract
     * @notice EIP-173
     */
    function owner() external view returns (address) {
        return Dev;
    }

    /**
     * @dev transfer contract ownership to new Dev
     * @notice EIP-173
     * @param newDev : new Dev
     */
    function transferOwnership(address newDev) external onlyDev {
        emit OwnershipTransferred(Dev, newDev);
        Dev = newDev;
    }

    /**
     * @dev check if an interface is supported
     * @notice EIP-165
     * @param sig : bytes4 identifier
     */
    function supportsInterface(bytes4 sig) external view returns (bool) {
        return supportedInterfaces[sig];
    }

    /**
     * @dev sets supportInterface flag
     * @notice EIP-165
     * @param sig : bytes4 identifier
     * @param value : boolean
     */
    function setInterface(bytes4 sig, bool value) external payable onlyDev {
        require(sig != 0xffffffff, "INVALID_INTERFACE_SELECTOR");
        supportedInterfaces[sig] = value;
    }

    /// @dev : Modifier to allow Owner or Controller
    modifier isOwnerOrController(bytes32 namehash) {
        require(block.timestamp < STORE.expiry(namehash), "NAME_EXPIRED");
        address _owner = STORE.owner(namehash);
        require(
            _owner == msg.sender || msg.sender == STORE.controller(namehash),
            "NOT_OWNER_OR_CONTROLLER"
        );
        _;
    }

    /// @dev : Modifier to allow Registrar
    modifier isRegistrar() {
        require(msg.sender == Registrar, "NOT_REGISTRAR");
        _;
    }

    /// @dev : Modifier to allow Owner, Controller or Registrar
    modifier isAuthorised(bytes32 namehash) {
        address _owner = STORE.owner(namehash);
        require(
            msg.sender == Registrar ||
                _owner == msg.sender ||
                msg.sender == STORE.controller(namehash),
            "NOT_AUTHORISED"
        );
        _;
    }

    /**
     * @dev check if name is not expired
     * @param namehash : hash of name
     */
    modifier canEmit(bytes32 namehash) {
        require(block.timestamp < STORE.expiry(namehash), "NAME_EXPIRED");
        _;
    }

    /**
     * @dev verify ownership of name
     * @param namehash : hash of name
     */
    modifier isOwner(bytes32 namehash) {
        require(block.timestamp < STORE.expiry(namehash), "NAME_EXPIRED");
        address _owner = STORE.owner(namehash);
        require(_owner == msg.sender, "NOT_OWNER");
        _;
    }

    /**
     * @dev registers new name
     * @param _label : label of name
     * @param namehash : hash of name
     * @param _owner : new owner
     */
    function register(
        string calldata _label,
        bytes32 namehash,
        address _owner
    ) external isRegistrar {
        require(_owner != address(0), "CANNOT_BURN");
        emit Transfer(address(0), _owner, uint256(namehash));
        STORE.setOwner(namehash, _owner);
        STORE.setLabel(namehash, _label);
        emit NewOwner(namehash, _owner);
    }

    /**
     * @dev set owner of a name
     * @param namehash : hash of name
     * @param _owner : new owner
     */
    function setOwner(
        bytes32 namehash,
        address _owner
    ) external isOwner(namehash) {
        require(_owner != address(0), "CANNOT_BURN");
        address currentOwner = STORE.owner(namehash);
        PARENT.setBalance(currentOwner, ERC721.balanceOf(currentOwner) - 1);
        PARENT.setBalance(_owner, ERC721.balanceOf(_owner) + 1);
        emit Transfer(currentOwner, _owner, uint256(namehash));
        STORE.setOwner(namehash, _owner);
        emit NewOwner(namehash, _owner);
    }

    /**
     * @dev set owner of a name due to ERC721 transfer() call
     * @param namehash : hash of name
     * @param _owner : new owner
     */
    function setOwnerERC721(
        bytes32 namehash,
        address _owner
    ) external isRegistrar {
        require(_owner != address(0), "CANNOT_BURN");
        STORE.setOwner(namehash, _owner);
        emit NewOwner(namehash, _owner);
    }

    /**
     * @dev set controller of a name
     * @param namehash : hash of name
     * @param _controller : new controller
     */
    function setController(
        bytes32 namehash,
        address _controller
    ) external isAuthorised(namehash) {
        STORE.setController(namehash, _controller);
        emit NewController(namehash, _controller);
    }

    /**
     * @dev set controller of a name due to ERC721 approve() call
     * @param namehash : hash of name
     * @param _controller : new controller
     */
    function setControllerERC721(
        bytes32 namehash,
        address _controller
    ) external isRegistrar {
        STORE.setController(namehash, _controller);
        emit NewController(namehash, _controller);
    }

    /**
     * @dev set resolver for a name
     * @param namehash : hash of name
     * @param _resolver : new resolver
     */
    function setResolver(
        bytes32 namehash,
        address _resolver
    ) external isAuthorised(namehash) {
        STORE.setResolver(namehash, _resolver);
        emit NewResolver(namehash, _resolver);
    }

    /**
     * @dev set expiry for a name
     * @param namehash : hash of name
     * @param _expiry : new expiry
     */
    function setExpiry(bytes32 namehash, uint _expiry) external isRegistrar {
        require(_expiry > STORE.expiry(namehash), "BAD_EXPIRY");
        STORE.setExpiry(namehash, _expiry);
        emit NewExpiry(namehash, _expiry);
    }

    /**
     * @dev renew a name
     * @param namehash : hash of name
     * @param _expiry : new expiry
     */
    function renew(
        bytes32 namehash,
        uint _expiry
    ) external payable isOwnerOrController(namehash) {
        uint currentExpiry = STORE.expiry(namehash);
        require(_expiry > currentExpiry, "BAD_EXPIRY");
        require(
            msg.value >= (_expiry - currentExpiry) * basePrice,
            "INSUFFICIENT_ETHER"
        );
        STORE.setExpiry(namehash, _expiry);
        emit NewExpiry(namehash, _expiry);
    }

    /**
     * @dev return owner of a name
     * @param namehash hash of name to query
     * @return address of owner
     */
    function owner(bytes32 namehash) public view returns (address) {
        address addr = STORE.owner(namehash);
        if (addr == address(this)) {
            return address(0);
        }
        return addr;
    }

    /**
     * @dev return label of a name
     * @param namehash hash of name to query
     * @return label of name
     */
    function label(
        bytes32 namehash
    ) public view canEmit(namehash) returns (string memory) {
        return STORE.label(namehash);
    }

    /**
     * @dev return controller of a name
     * @param namehash hash of name to query
     * @return address of controller
     */
    function controller(
        bytes32 namehash
    ) public view canEmit(namehash) returns (address) {
        return STORE.controller(namehash);
    }

    /**
     * @dev return expiry of a name
     * @param namehash hash of name to query
     * @return expiry
     */
    function expiry(bytes32 namehash) public view returns (uint) {
        return STORE.expiry(namehash);
    }

    /**
     * @dev return resolver of a name
     * @param namehash hash of name to query
     * @return address of resolver
     */
    function resolver(
        bytes32 namehash
    ) public view canEmit(namehash) returns (address) {
        return STORE.resolver(namehash);
    }

    /**
     * @dev check if a name is registered
     * @param namehash hash of name to query
     * @return true or false
     */
    function recordExists(bytes32 namehash) public view returns (bool) {
        return block.timestamp < STORE.expiry(namehash);
    }

    /// @notice re-entrancy guard
    /// @dev : revert on fallback
    fallback() external payable {
        revert();
    }

    /// @dev : revert on receive
    receive() external payable {
        revert();
    }
}
