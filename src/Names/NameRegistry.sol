//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Names/iName.sol";
import "src/Names/iERC721.sol";
import "src/Interface/iHelix2.sol";
import "src/Utils/LibString.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Name Base
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
    iERC721 public ERC721;

    /// @dev : Helix2 Name events
    event NewDev(address Dev, address newDev);
    event NewName(bytes32 indexed namehash, address owner);
    event NewOwner(bytes32 indexed namehash, address owner);
    event NewRegistration(bytes32 indexed namehash, address owner);
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
        address _owner; /// Owner of Name
        address _resolver; /// Resolver of Name
        address _controller; /// Controller of Name
        uint _expiry; /// Expiry of Name
    }
    mapping(bytes32 => Name) public Names;
    mapping(address => mapping(address => bool)) Operators;

    /**
     * @dev : sets permissions for 0x0 and roothash
     * @notice : consider changing msg.sender → address(this)
     */
    function catalyse() internal onlyDev {
        // 0x0
        Names[0x0]._owner = msg.sender;
        Names[0x0]._expiry = theEnd;
        Names[0x0]._controller = msg.sender;
        Names[0x0]._resolver = msg.sender;
        // root
        bytes32[4] memory hashes = HELIX2.getRoothash();
        for (uint i = 0; i < hashes.length; i++) {
            Names[hashes[i]]._owner = msg.sender;
            Names[hashes[i]]._expiry = theEnd;
            Names[hashes[i]]._controller = msg.sender;
            Names[hashes[i]]._resolver = msg.sender;
        }
    }

    /**
     * @dev : Initialise a new HELIX2 Names Registry
     * @notice : constructor notes
     * @param _helix2 : address of HELIX2 Manager
     */
    constructor(address _helix2) {
        Dev = msg.sender;
        HELIX2 = iHELIX2(_helix2);
        roothash = HELIX2.getRoothash()[0];
        basePrice = HELIX2.getPrices()[0];
        /// give ownership of '0x0' and <roothash> to Dev
        catalyse();
    }

    /// @dev : Modifier to allow only dev
    modifier onlyDev() {
        require(msg.sender == Dev, "NOT_DEV");
        _;
    }

    /**
     * @dev : transfer contract ownership to new Dev
     * @param newDev : new Dev
     */
    function changeDev(address newDev) external onlyDev {
        emit NewDev(Dev, newDev);
        Dev = newDev;
    }

    /// @dev : Modifier to allow only Controller
    modifier onlyController(bytes32 namehash) {
        require(block.timestamp < Names[namehash]._expiry, "NAME_EXPIRED");
        require(msg.sender == Names[namehash]._controller, "NOT_CONTROLLER");
        _;
    }

    /// @dev : Modifier to allow Owner or Controller
    modifier isOwnerOrController(bytes32 namehash) {
        require(block.timestamp < Names[namehash]._expiry, "NAME_EXPIRED");
        address _owner = Names[namehash]._owner;
        require(
            _owner == msg.sender ||
                Operators[_owner][msg.sender] ||
                msg.sender == Names[namehash]._controller,
            "NOT_OWNER_OR_CONTROLLER"
        );
        _;
    }

    /// @dev : Modifier to allow Registrar
    modifier isRegistrar() {
        Registrar = HELIX2.getRegistrar()[0];
        require(msg.sender == Registrar, "NOT_REGISTRAR");
        _;
    }

    /// @dev : Modifier to allow Owner, Controller or Registrar
    modifier isAuthorised(bytes32 namehash) {
        Registrar = HELIX2.getRegistrar()[0];
        address _owner = Names[namehash]._owner;
        require(
            msg.sender == Registrar ||
                _owner == msg.sender ||
                Operators[_owner][msg.sender] ||
                msg.sender == Names[namehash]._controller,
            "NOT_AUTHORISED"
        );
        _;
    }

    /**
     * @dev : check if name is available
     * @param namehash : hash of name
     */
    modifier isAvailable(bytes32 namehash) {
        require(block.timestamp >= Names[namehash]._expiry, "NAME_EXISTS");
        _;
    }

    /**
     * @dev : check if name is already registered
     * @param namehash : hash of name
     */
    modifier isOwned(bytes32 namehash) {
        require(block.timestamp < Names[namehash]._expiry, "NAME_EXPIRED");
        _;
    }

    /**
     * @dev : verify ownership of name
     * @param namehash : hash of name
     */
    modifier onlyOwner(bytes32 namehash) {
        require(block.timestamp < Names[namehash]._expiry, "NAME_EXPIRED");
        address _owner = Names[namehash]._owner;
        require(
            _owner == msg.sender || Operators[_owner][msg.sender],
            "NOT_OWNER"
        );
        _;
    }

    /**
     * @dev : register owner of new name
     * @param namehash : hash of name
     * @param _owner : new owner
     */
    function register(bytes32 namehash, address _owner) external isRegistrar {
        require(_owner != address(0), "CANNOT_BURN");
        emit Transfer(address(0), _owner, uint256(namehash));
        Names[namehash]._owner = _owner;
        emit NewOwner(namehash, _owner);
        emit NewRegistration(namehash, _owner);
    }

    /**
     * @dev : set owner of a name
     * @param namehash : hash of name
     * @param _owner : new owner
     */
    function setOwner(
        bytes32 namehash,
        address _owner
    ) external onlyOwner(namehash) {
        require(_owner != address(0), "CANNOT_BURN");
        address owner_ = Names[namehash]._owner;
        Registrar = HELIX2.getRegistrar()[0];
        _NAME_ = iNAME(Registrar);
        ERC721 = iERC721(Registrar);
        _NAME_.setBalance(owner_, ERC721.balanceOf(owner_) - 1);
        _NAME_.setBalance(_owner, ERC721.balanceOf(_owner) + 1);
        emit Transfer(owner_, _owner, uint256(namehash));
        Names[namehash]._owner = _owner;
        emit NewOwner(namehash, _owner);
    }

    /**
     * @dev : set owner of a name due to ERC721 transfer() call
     * @param namehash : hash of name
     * @param _owner : new owner
     */
    function setOwnerERC721(
        bytes32 namehash,
        address _owner
    ) external isRegistrar {
        require(_owner != address(0), "CANNOT_BURN");
        Names[namehash]._owner = _owner;
        emit NewOwner(namehash, _owner);
    }

    /**
     * @dev : set controller of a name
     * @param namehash : hash of name
     * @param _controller : new controller
     */
    function setController(
        bytes32 namehash,
        address _controller
    ) external isAuthorised(namehash) {
        emit Approval(Names[namehash]._owner, _controller, uint256(namehash));
        Names[namehash]._controller = _controller;
        emit NewController(namehash, _controller);
    }

    /**
     * @dev : set controller of a name due to ERC721 approve() call
     * @param namehash : hash of name
     * @param _controller : new controller
     */
    function setControllerERC721(
        bytes32 namehash,
        address _controller
    ) external isRegistrar {
        Names[namehash]._controller = _controller;
        emit NewController(namehash, _controller);
    }

    /**
     * @dev : set resolver for a name
     * @param namehash : hash of name
     * @param _resolver : new resolver
     */
    function setResolver(
        bytes32 namehash,
        address _resolver
    ) external isAuthorised(namehash) {
        Names[namehash]._resolver = _resolver;
        emit NewResolver(namehash, _resolver);
    }

    /**
     * @dev : set expiry for a name
     * @param namehash : hash of name
     * @param _expiry : new expiry
     */
    function setExpiry(bytes32 namehash, uint _expiry) external isRegistrar {
        require(_expiry > Names[namehash]._expiry, "BAD_EXPIRY");
        Names[namehash]._expiry = _expiry;
        emit NewExpiry(namehash, _expiry);
    }

    /**
     * @dev : renew a name
     * @param namehash : hash of name
     * @param _expiry : new expiry
     */
    function renew(
        bytes32 namehash,
        uint _expiry
    ) external payable isOwnerOrController(namehash) {
        require(_expiry > Names[namehash]._expiry, "BAD_EXPIRY");
        Registrar = HELIX2.getRegistrar()[0];
        uint newDuration = _expiry - Names[namehash]._expiry;
        require(msg.value >= newDuration * basePrice, "INSUFFICIENT_ETHER");
        Names[namehash]._expiry = _expiry;
        emit NewExpiry(namehash, _expiry);
    }

    /**
     * @dev : set record for a name
     * @param namehash : hash of name
     * @param _resolver : new record
     */
    function setRecord(
        bytes32 namehash,
        address _resolver
    ) external isAuthorised(namehash) {
        Names[namehash]._resolver = _resolver;
        emit NewRecord(namehash, _resolver);
    }

    /**
     * @dev : set operator for a name
     * @param operator : new operator
     * @param approved : state to set
     */
    function setApprovalForAll(address operator, bool approved) external {
        Operators[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev return owner of a name
     * @param namehash hash of name to query
     * @return address of owner
     */
    function owner(bytes32 namehash) public view returns (address) {
        address addr = Names[namehash]._owner;
        if (addr == address(this)) {
            return address(0x0);
        }
        return addr;
    }

    /**
     * @dev return controller of a name
     * @param namehash hash of name to query
     * @return address of controller
     */
    function controller(
        bytes32 namehash
    ) public view isOwned(namehash) returns (address) {
        address _controller = Names[namehash]._controller;
        return _controller;
    }

    /**
     * @dev return expiry of a name
     * @param namehash hash of name to query
     * @return expiry
     */
    function expiry(bytes32 namehash) public view returns (uint) {
        uint _expiry = Names[namehash]._expiry;
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
        address _resolver = Names[namehash]._resolver;
        return _resolver;
    }

    /**
     * @dev check if a name is registered
     * @param namehash hash of name to query
     * @return true or false
     */
    function recordExists(bytes32 namehash) public view returns (bool) {
        return block.timestamp < Names[namehash]._expiry;
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
        return Operators[_owner][operator];
    }

    /**
     * @dev : withdraw ether to Dev, anyone can trigger
     */
    function withdrawEther() external {
        (bool ok, ) = Dev.call{value: address(this).balance}("");
        require(ok, "ETH_TRANSFER_FAILED");
    }
}
