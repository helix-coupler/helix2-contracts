//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Names/iName.sol";
import "src/Names/iERC721.sol";
import "src/Interface/iERC173.sol";
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
    iNAME public _NAME_;
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
    event NewRecord(bytes32 indexed namehash, address resolver);
    event NewResolver(bytes32 indexed namehash, address resolver);
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenID
    );
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed tokenID
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /// Dev
    address public Dev;

    /// @dev : Pause/Resume contract
    bool public active = true;

    /// Constants
    bytes32 public roothash;
    uint256 public basePrice;
    address public Registrar;
    uint256 public theEnd = 250_000_000_000_000_000; // roughly 80,000,000,000 years in the future

    /// @dev : Helix2 Name struct
    struct Name {
        string _label; /// Label of Name
        address _owner; /// Owner of Name
        address _resolver; /// Resolver of Name
        address _controller; /// Controller of Name
        uint _expiry; /// Expiry of Name
    }
    mapping(bytes32 => Name) public Names;
    mapping(address => mapping(address => bool)) Operators;

    /**
     * @dev sets permissions for 0x0 upon setConfig()
     * @notice consider changing msg.sender → address(this)
     */
    function catalyse() internal onlyDev {
        // 0x0
        STORE.setLabel(bytes32(0x0), ".");
        STORE.setOwner(bytes32(0x0), msg.sender);
        STORE.setExpiry(bytes32(0x0), theEnd);
        STORE.setController(bytes32(0x0), msg.sender);
        STORE.setResolver(bytes32(0x0), msg.sender);
    }

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
            _NAME_ = iNAME(Registrar);
            ERC721 = iERC721(Registrar);
        }
        if (_store != address(0)) {
            STORE = iNAME(_store);
            catalyse();
        }
        if (_priceOracle != address(0)) {
            PRICES = iPriceOracle(_priceOracle);
            basePrice = PRICES.getPrices()[0];
        }
    }

    /**
     * @dev get owner of contract
     * @return address of controlling dev or multi-sig wallet
     */
    function owner() external view returns (address) {
        return Dev;
    }

    /**
     * @dev transfer contract ownership to new Dev
     * @param newDev : new Dev
     */
    function transferOwnership(address newDev) external onlyDev {
        emit OwnershipTransferred(Dev, newDev);
        Dev = newDev;
    }

    /// @dev : Modifier to allow only Controller
    modifier onlyController(bytes32 namehash) {
        require(block.timestamp < STORE.expiry(namehash), "NAME_EXPIRED");
        require(msg.sender == STORE.controller(namehash), "NOT_CONTROLLER");
        _;
    }

    /// @dev : Modifier to allow Owner or Controller
    modifier isOwnerOrController(bytes32 namehash) {
        require(block.timestamp < STORE.expiry(namehash), "NAME_EXPIRED");
        address _owner = STORE.owner(namehash);
        require(
            _owner == msg.sender ||
                STORE.isApprovedForAll(_owner, msg.sender) ||
                msg.sender == STORE.controller(namehash),
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
                STORE.isApprovedForAll(_owner, msg.sender) ||
                msg.sender == STORE.controller(namehash),
            "NOT_AUTHORISED"
        );
        _;
    }

    /**
     * @dev check if name is available
     * @param namehash : hash of name
     */
    modifier isAvailable(bytes32 namehash) {
        require(block.timestamp >= STORE.expiry(namehash), "NAME_EXISTS");
        _;
    }

    /**
     * @dev check if name is already registered
     * @param namehash : hash of name
     */
    modifier isOwned(bytes32 namehash) {
        require(block.timestamp < STORE.expiry(namehash), "NAME_EXPIRED");
        _;
    }

    /**
     * @dev verify ownership of name
     * @param namehash : hash of name
     */
    modifier onlyOwner(bytes32 namehash) {
        require(block.timestamp < STORE.expiry(namehash), "NAME_EXPIRED");
        address _owner = STORE.owner(namehash);
        require(
            _owner == msg.sender || STORE.isApprovedForAll(_owner, msg.sender),
            "NOT_OWNER"
        );
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
    ) external onlyOwner(namehash) {
        require(_owner != address(0), "CANNOT_BURN");
        address owner_ = STORE.owner(namehash);
        _NAME_.setBalance(owner_, ERC721.balanceOf(owner_) - 1);
        _NAME_.setBalance(_owner, ERC721.balanceOf(_owner) + 1);
        emit Transfer(owner_, _owner, uint256(namehash));
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
        emit Approval(STORE.owner(namehash), _controller, uint256(namehash));
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
        uint expiry_ = STORE.expiry(namehash);
        require(_expiry > expiry_, "BAD_EXPIRY");
        uint newDuration = _expiry - expiry_;
        require(msg.value >= newDuration * basePrice, "INSUFFICIENT_ETHER");
        STORE.setExpiry(namehash, _expiry);
        emit NewExpiry(namehash, _expiry);
    }

    /**
     * @dev set record for a name
     * @param namehash : hash of name
     * @param _resolver : new record
     */
    function setRecord(
        bytes32 namehash,
        address _resolver
    ) external isAuthorised(namehash) {
        STORE.setResolver(namehash, _resolver);
        emit NewRecord(namehash, _resolver);
    }

    /**
     * @dev set operator for a name
     * @param operator : new operator
     * @param approved : state to set
     */
    function setApprovalForAll(address operator, bool approved) external {
        STORE.setApprovalForAll(msg.sender, operator, approved);
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev return owner of a name
     * @param namehash hash of name to query
     * @return address of owner
     */
    function owner(bytes32 namehash) public view returns (address) {
        address addr = STORE.owner(namehash);
        if (addr == address(this)) {
            return address(0x0);
        }
        return addr;
    }

    /**
     * @dev return label of a name
     * @param namehash hash of name to query
     * @return label of name
     */
    function label(bytes32 namehash) public view returns (string memory) {
        string memory _label = STORE.label(namehash);
        return _label;
    }

    /**
     * @dev return controller of a name
     * @param namehash hash of name to query
     * @return address of controller
     */
    function controller(
        bytes32 namehash
    ) public view isOwned(namehash) returns (address) {
        address _controller = STORE.controller(namehash);
        return _controller;
    }

    /**
     * @dev return expiry of a name
     * @param namehash hash of name to query
     * @return expiry
     */
    function expiry(bytes32 namehash) public view returns (uint) {
        uint _expiry = STORE.expiry(namehash);
        return _expiry;
    }

    /**
     * @dev return resolver of a name
     * @param namehash hash of name to query
     * @return address of resolver
     */
    function resolver(
        bytes32 namehash
    ) public view isOwned(namehash) returns (address) {
        address _resolver = STORE.resolver(namehash);
        return _resolver;
    }

    /**
     * @dev check if a name is registered
     * @param namehash hash of name to query
     * @return true or false
     */
    function recordExists(bytes32 namehash) public view returns (bool) {
        return block.timestamp < STORE.expiry(namehash);
    }

    /**
     * @dev check if an address is set as operator
     * @param _owner owner of name to query
     * @param operator operator to check
     * @return true or false
     */
    function isApprovedForAll(
        address _owner,
        address operator
    ) external view returns (bool) {
        return STORE.isApprovedForAll(_owner, operator);
    }

    /**
     * @dev withdraw ether to Dev, anyone can trigger
     */
    function withdrawEther() external {
        (bool ok, ) = Dev.call{value: address(this).balance}("");
        require(ok, "ETH_TRANSFER_FAILED");
    }
}
