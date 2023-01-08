//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Names/iName.sol";
import "src/Bonds/iBond.sol";
import "src/Interface/iHelix2.sol";
import "src/Interface/iERC165.sol";
import "src/Interface/iERC173.sol";
import "src/Oracle/iPriceOracle.sol";
import "src/Utils/LibString.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @notice GitHub: https://github.com/helix-coupler/helix2-contracts
 * @notice README: https://github.com/helix-coupler/resources
 * @dev testnet v0.0.1
 * @title Helix2 Bond Base
 */
contract Helix2BondRegistry {
    using LibString for bytes32[];
    using LibString for bytes32;
    using LibString for address[];
    using LibString for address;
    using LibString for string[];
    using LibString for string;
    using LibString for uint8[];
    using LibString for uint8;

    /// Interfaces
    iHELIX2 public HELIX2;
    iNAME public NAMES;
    iPriceOracle public PRICES;

    /// @dev : Helix2 Bond events
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event Hooked(bytes32 indexed bondhash, address config, uint8 rule);
    event Rehooked(bytes32 indexed bondhash, address config, uint8 rule);
    event Unhooked(bytes32 indexed bondhash, uint8 rule);
    event UnhookedAll(bytes32 indexed bondhash);
    event NewCation(bytes32 indexed bondhash, bytes32 cation);
    event NewAnion(bytes32 indexed bondhash, bytes32 anion);
    event NewController(bytes32 indexed bondhash, address controller);
    event NewExpiry(bytes32 indexed bondhash, uint expiry);
    event NewRecord(bytes32 indexed bondhash, address resolver);
    event NewCovalence(bytes32 indexed bondhash, bool covalence);
    event NewResolver(bytes32 indexed bondhash, address resolver);
    event ApprovalForAll(
        address indexed cation,
        address indexed operator,
        bool approved
    );
    error BAD_HOOK();

    /// Dev
    address public Dev;

    /// @dev : Pause/Resume contract
    bool public active = true;
    /// @dev : EIP-165
    mapping(bytes4 => bool) public supportsInterface;

    /// @dev : Bond roothash
    bytes32 public roothash;
    uint256 public basePrice;
    address public Registrar;
    uint256 public theEnd = 250_000_000_000_000_000; // roughly 80,000,000,000 years in the future

    /// @dev : Helix2 Bond struct
    struct Bond {
        uint8[] _rules; /// Rules
        mapping(uint8 => address) _hooks; /// Rules → Hooks
        bytes32 _cation; /// Source of Bond (= Owner)
        bytes32 _anion; /// Target of Bond
        bytes32 _alias; /// Hash of Bond
        address _resolver; /// Resolver of Bond
        address _controller; /// Controller of Bond
        bool _covalence; /// Mutuality Flag
        uint _expiry; /// Expiry of Bond
    }
    mapping(bytes32 => Bond) public Bonds;
    mapping(address => mapping(address => bool)) Operators;

    /**
     * @dev sets permissions for 0x0
     * @notice consider changing msg.sender → address(this)
     */
    function catalyse() internal {
        // 0x0
        Bonds[0x0]._hooks[uint8(0)] = address(0x0);
        Bonds[0x0]._rules = [uint8(0)];
        Bonds[0x0]._cation = bytes32(0x0);
        Bonds[0x0]._anion = bytes32(0x0);
        Bonds[0x0]._alias = bytes32(0x0);
        Bonds[0x0]._covalence = true;
        Bonds[0x0]._expiry = theEnd;
        Bonds[0x0]._controller = msg.sender;
        Bonds[0x0]._resolver = msg.sender;
    }

    /**
     * @dev Initialise a new HELIX2 Bonds Registry
     * @notice
     * @param _helix2 : address of HELIX2 Manager
     * @param _registry : address of HELIX2 Name Registry
     */
    constructor(address _registry, address _helix2, address _priceOracle) {
        Dev = msg.sender;
        HELIX2 = iHELIX2(_helix2);
        NAMES = iNAME(_registry);
        roothash = HELIX2.getRoothash()[1];
        PRICES = iPriceOracle(_priceOracle);
        basePrice = PRICES.getPrices()[1];
        /// give ownership of '0x0' to Dev
        catalyse();
        // Interface
        supportsInterface[type(iERC165).interfaceId] = true;
        supportsInterface[type(iERC173).interfaceId] = true;
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
     */
    function setConfig(address _helix2, address _priceOracle) external onlyDev {
        if (_helix2 != address(0)) {
            HELIX2 = iHELIX2(_helix2);
            roothash = HELIX2.getRoothash()[1];
            Registrar = HELIX2.getRegistrar()[1];
        }
        PRICES = iPriceOracle(_priceOracle);
        basePrice = PRICES.getPrices()[1];
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

    /**
     * @dev sets supportInterface flag
     * @param sig : bytes4 identifier
     * @param value : boolean
     */
    function setInterface(bytes4 sig, bool value) external payable onlyDev {
        require(sig != 0xffffffff, "INVALID_INTERFACE_SELECTOR");
        supportsInterface[sig] = value;
    }

    /// @dev : Modifier to allow only Controller
    modifier onlyController(bytes32 bondhash) {
        require(block.timestamp < Bonds[bondhash]._expiry, "BOND_EXPIRED");
        require(msg.sender == Bonds[bondhash]._controller, "NOT_CONTROLLER");
        _;
    }

    /// @dev : Modifier to allow Cation or Controller
    modifier isCationOrController(bytes32 bondhash) {
        require(block.timestamp < Bonds[bondhash]._expiry, "BOND_EXPIRED");
        bytes32 __cation = Bonds[bondhash]._cation;
        address _cation = NAMES.owner(__cation);
        require(
            _cation == msg.sender ||
                Operators[_cation][msg.sender] ||
                msg.sender == Bonds[bondhash]._controller,
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
    modifier isAuthorised(bytes32 bondhash) {
        bytes32 __cation = Bonds[bondhash]._cation;
        address _cation = NAMES.owner(__cation);
        require(
            msg.sender == Registrar ||
                _cation == msg.sender ||
                Operators[_cation][msg.sender] ||
                msg.sender == Bonds[bondhash]._controller,
            "NOT_AUTHORISED"
        );
        _;
    }

    /**
     * @dev check if bond is available
     * @param bondhash : hash of bond
     */
    modifier isAvailable(bytes32 bondhash) {
        require(block.timestamp >= Bonds[bondhash]._expiry, "BOND_EXISTS");
        _;
    }

    /**
     * @dev verify bond is not expired
     * @param bondhash : label of bond
     */
    modifier isOwned(bytes32 bondhash) {
        require(block.timestamp < Bonds[bondhash]._expiry, "BOND_EXPIRED");
        _;
    }

    /**
     * @dev check if the bond is not duplicate
     * @param bondhash : hash of bond
     * @param newAnion : hash of new anion
     */
    function isNotDuplicateAnion(
        bytes32 bondhash,
        bytes32 newAnion
    ) public view returns (bool) {
        bytes32 _anion = Bonds[bondhash]._anion;
        return _anion != newAnion;
    }

    /**
     * @dev check if new config is a duplicate
     * @param bondhash : hash of bond
     * @param rule : config to check
     */
    function isNotDuplicateHook(
        bytes32 bondhash,
        uint8 rule
    ) public view returns (bool) {
        return !rule.existsIn(Bonds[bondhash]._rules);
    }

    /**
     * @dev verify ownership of bond
     * @param bondhash : hash of bond
     */
    modifier onlyCation(bytes32 bondhash) {
        require(block.timestamp < Bonds[bondhash]._expiry, "BOND_EXPIRED");
        bytes32 __cation = Bonds[bondhash]._cation;
        address _cation = NAMES.owner(__cation);
        require(
            _cation == msg.sender || Operators[_cation][msg.sender],
            "NOT_OWNER"
        );
        _;
    }

    /**
     * @dev register owner of new bond
     * @param bondhash : hash of bond
     * @param _cation : new cation
     */
    function register(bytes32 bondhash, bytes32 _cation) external isRegistrar {
        require(NAMES.owner(_cation) != address(0), "CANNOT_BURN");
        Bonds[bondhash]._cation = _cation;
        emit NewCation(bondhash, _cation);
    }

    /**
     * @dev set cation of a bond
     * @param bondhash : hash of bond
     * @param _cation : new cation
     */
    function setCation(
        bytes32 bondhash,
        bytes32 _cation
    ) external onlyCation(bondhash) {
        require(NAMES.owner(_cation) != address(0), "CANNOT_BURN");
        Bonds[bondhash]._cation = _cation;
        emit NewCation(bondhash, _cation);
    }

    /**
     * @dev set controller of a bond
     * @param bondhash : hash of bond
     * @param _controller : new controller
     */
    function setController(
        bytes32 bondhash,
        address _controller
    ) external isAuthorised(bondhash) {
        Bonds[bondhash]._controller = _controller;
        emit NewController(bondhash, _controller);
    }

    /**
     * @dev set new anion of a bond
     * @param bondhash : hash of anion
     * @param _anion : address of anion
     */
    function setAnion(
        bytes32 bondhash,
        bytes32 _anion
    ) external isAuthorised(bondhash) {
        Bonds[bondhash]._anion = _anion;
        emit NewAnion(bondhash, _anion);
    }

    /**
     * @dev set new alias for bond
     * @param bondhash : hash of bond
     * @param _alias : bash of alias
     */
    function setAlias(bytes32 bondhash, bytes32 _alias) external isRegistrar {
        Bonds[bondhash]._alias = _alias;
    }

    /**
     * @dev set new mutuality flag for bond
     * @param bondhash : hash of bond
     * @param _covalence : bool
     */
    function setCovalence(
        bytes32 bondhash,
        bool _covalence
    ) external isAuthorised(bondhash) {
        Bonds[bondhash]._covalence = _covalence;
        emit NewCovalence(bondhash, _covalence);
    }

    /**
     * @dev set resolver for a bond
     * @param bondhash : hash of bond
     * @param _resolver : new resolver
     */
    function setResolver(
        bytes32 bondhash,
        address _resolver
    ) external isAuthorised(bondhash) {
        Bonds[bondhash]._resolver = _resolver;
        emit NewResolver(bondhash, _resolver);
    }

    /**
     * @dev set expiry for a bond
     * @param bondhash : hash of bond
     * @param _expiry : new expiry
     */
    function setExpiry(bytes32 bondhash, uint _expiry) external isRegistrar {
        require(_expiry > Bonds[bondhash]._expiry, "BAD_EXPIRY");
        Bonds[bondhash]._expiry = _expiry;
        emit NewExpiry(bondhash, _expiry);
    }

    /**
     * @dev set expiry for a bond
     * @param bondhash : hash of bond
     * @param _expiry : new expiry
     */
    function renew(
        bytes32 bondhash,
        uint _expiry
    ) external payable isCationOrController(bondhash) {
        require(_expiry > Bonds[bondhash]._expiry, "BAD_EXPIRY");
        uint newDuration = _expiry - Bonds[bondhash]._expiry;
        require(msg.value >= newDuration * basePrice, "INSUFFICIENT_ETHER");
        Bonds[bondhash]._expiry = _expiry;
        emit NewExpiry(bondhash, _expiry);
    }

    /**
     * @dev set record for a bond
     * @param bondhash : hash of bond
     * @param _resolver : new record
     */
    function setRecord(
        bytes32 bondhash,
        address _resolver
    ) external isAuthorised(bondhash) {
        Bonds[bondhash]._resolver = _resolver;
        emit NewRecord(bondhash, _resolver);
    }

    /**
     * @dev adds a hook with rule
     * @param bondhash : hash of the bond
     * @param rule : rule for the hook
     * @param config : address of config contract
     */
    function hook(
        bytes32 bondhash,
        address config,
        uint8 rule
    ) external isCationOrController(bondhash) {
        require(isNotDuplicateHook(bondhash, rule), "HOOK_EXISTS");
        Bonds[bondhash]._rules.push(rule);
        Bonds[bondhash]._hooks[rule] = config;
        emit Hooked(bondhash, config, rule);
    }

    /**
     * @dev rehooks a hook to a new rule
     * @param bondhash : hash of the bond
     * @param rule : rule for the hook
     * @param config : address of config contract
     */
    function rehook(
        bytes32 bondhash,
        address config,
        uint8 rule
    ) external isCationOrController(bondhash) {
        require(Bonds[bondhash]._hooks[rule] != config, "RULE_EXISTS");
        Bonds[bondhash]._hooks[rule] = config;
        emit Rehooked(bondhash, config, rule);
    }

    /**
     * @dev removes a hook in a bond
     * @param bondhash : hash of the bond
     * @param rule : rule to unhook
     */
    function unhook(
        bytes32 bondhash,
        uint8 rule
    ) external isCationOrController(bondhash) {
        uint8[] memory _rules = Bonds[bondhash]._rules;
        if (rule.existsIn(_rules)) {
            uint index = rule.findIn(_rules);
            Bonds[bondhash]._hooks[rule] = address(0);
            emit Unhooked(bondhash, rule);
            delete Bonds[bondhash]._rules[index];
        } else {
            revert BAD_HOOK();
        }
    }

    /**
     * @dev removes all hooks in a bond
     * @param bondhash : hash of the bond
     */
    function unhookAll(bytes32 bondhash) external isAuthorised(bondhash) {
        uint8[] memory _rules = Bonds[bondhash]._rules;
        for (uint i = 0; i < _rules.length; i++) {
            Bonds[bondhash]._hooks[_rules[i]] = address(0);
            emit Unhooked(bondhash, _rules[i]);
        }
        delete Bonds[bondhash]._rules;
        emit UnhookedAll(bondhash);
    }

    /**
     * @dev sets Controller for all your tokens
     * @param operator : operator address to be set as Controller
     * @param approved : bool to set
     */
    function setApprovalForAll(address operator, bool approved) external {
        Operators[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev return cation of a bond
     * @param bondhash : hash of bond to query
     * @return hash of cation
     */
    function cation(
        bytes32 bondhash
    ) public view isOwned(bondhash) returns (bytes32) {
        bytes32 __cation = Bonds[bondhash]._cation;
        address _cation = NAMES.owner(__cation);
        if (_cation == address(this)) {
            return roothash;
        }
        return __cation;
    }

    /**
     * @dev return controller of a bond
     * @param bondhash : hash of bond to query
     * @return address of controller
     */
    function controller(
        bytes32 bondhash
    ) public view isOwned(bondhash) returns (address) {
        address _controller = Bonds[bondhash]._controller;
        return _controller;
    }

    /**
     * @dev return anion of a bond
     * @param bondhash : hash of bond to query
     * @return hash of anion
     */
    function anion(
        bytes32 bondhash
    ) public view isOwned(bondhash) returns (bytes32) {
        bytes32 _anion = Bonds[bondhash]._anion;
        return _anion;
    }

    /**
     * @dev shows mutuality state of a bond
     * @param bondhash : hash of bond to query
     * @return mutuality state of the bond
     */
    function covalence(
        bytes32 bondhash
    ) public view isOwned(bondhash) returns (bool) {
        bool _covalence = Bonds[bondhash]._covalence;
        return _covalence;
    }

    /**
     * @dev shows alias of a bond
     * @param bondhash : hash of bond to query
     * @return alias of the bond
     */
    function alias_(
        bytes32 bondhash
    ) public view isOwned(bondhash) returns (bytes32) {
        bytes32 _alias = Bonds[bondhash]._alias;
        return _alias;
    }

    /**
     * @dev return hooks of a bond
     * @param bondhash : hash of bond to query
     * @return _rules
     * @return _hooks
     */
    function hooksWithRules(
        bytes32 bondhash
    )
        public
        view
        isOwned(bondhash)
        returns (uint8[] memory _rules, address[] memory _hooks)
    {
        _rules = Bonds[bondhash]._rules;
        _hooks = new address[](_rules.length);
        for (uint i = 0; i < _rules.length; i++) {
            _hooks[i] = Bonds[bondhash]._hooks[_rules[i]];
        }
    }

    /**
     * @dev return expiry of a bond
     * @param bondhash : hash of bond to query
     * @return expiry
     */
    function expiry(bytes32 bondhash) public view returns (uint) {
        uint _expiry = Bonds[bondhash]._expiry;
        return _expiry;
    }

    /**
     * @dev return resolver of a bond
     * @param bondhash : hash of bond to query
     * @return address of resolver
     */
    function resolver(
        bytes32 bondhash
    ) public view isOwned(bondhash) returns (address) {
        address _resolver = Bonds[bondhash]._resolver;
        return _resolver;
    }

    /**
     * @dev check if a bond is registered
     * @param bondhash : hash of bond to query
     * @return true or false
     */
    function recordExists(bytes32 bondhash) public view returns (bool) {
        return block.timestamp < Bonds[bondhash]._expiry;
    }

    /**
     * @dev check if an address is set as operator
     * @param _cation cation of bond to query
     * @param operator operator to check
     * @return true or false
     */
    function isApprovedForAll(
        bytes32 _cation,
        address operator
    ) external view returns (bool) {
        address __cation = NAMES.owner(_cation);
        return Operators[__cation][operator];
    }

    /**
     * @dev withdraw ether to Dev, anyone can trigger
     */
    function withdrawEther() external {
        (bool ok, ) = Dev.call{value: address(this).balance}("");
        require(ok, "ETH_TRANSFER_FAILED");
    }
}