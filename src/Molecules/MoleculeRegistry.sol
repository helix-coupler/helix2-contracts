//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Names/iName.sol";
import "src/Molecules/iMolecule.sol";
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
 * @title Helix2 Molecule Base
 */
contract Helix2MoleculeRegistry {
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

    /// @dev : Helix2 Molecule events
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event Hooked(bytes32 indexed bondhash, address config, uint8 rule);
    event Rehooked(bytes32 indexed bondhash, address config, uint8 rule);
    event Unhooked(bytes32 indexed bondhash, uint8 rule);
    event UnhookedAll(bytes32 indexed molyhash);
    event NewCation(bytes32 indexed molyhash, bytes32 cation);
    event NewAnion(bytes32 indexed molyhash, bytes32 anion);
    event NewAnions(bytes32 indexed molyhash, bytes32[] anion);
    event PopAnion(bytes32 indexed molyhash, bytes32 anion);
    event NewController(bytes32 indexed molyhash, address controller);
    event NewExpiry(bytes32 indexed molyhash, uint expiry);
    event NewRecord(bytes32 indexed molyhash, address resolver);
    event NewCovalence(bytes32 indexed molyhash, bool covalence);
    event NewResolver(bytes32 indexed molyhash, address resolver);
    event ApprovalForAll(
        address indexed cation,
        address indexed operator,
        bool approved
    );

    error BAD_ANION();
    error BAD_HOOK();

    /// Dev
    address public Dev;

    /// @dev : Pause/Resume contract
    bool public active = true;
    /// @dev : EIP-165
    mapping(bytes4 => bool) public supportsInterface;

    /// @dev : Molecule roothash
    bytes32 public roothash;
    uint256 public basePrice;
    address public Registrar;
    uint256 public theEnd = 250_000_000_000_000_000; // roughly 80,000,000,000 years in the future

    /// @dev : Helix2 MOLECULE struct
    struct Molecule {
        uint8[] _rules; /// Rules
        mapping(uint8 => address) _hooks; /// Rules → Hooks
        bytes32 _cation; /// Source of Molecule (= Owner)
        bytes32[] _anion; /// Targets of Molecule
        bytes32 _alias; /// Hash of Molecule
        address _resolver; /// Resolver of Molecule
        address _controller; /// Controller of Molecule
        bool _covalence; /// Mutuality Flag
        uint _expiry; /// Expiry of Molecule
    }
    mapping(bytes32 => Molecule) public Molecules;
    mapping(address => mapping(address => bool)) Operators;

    /**
     * @dev sets permissions for 0x0
     * @notice consider changing msg.sender → address(this)
     */
    function catalyse() internal {
        // 0x0
        Molecules[0x0]._hooks[uint8(0)] = address(0x0);
        Molecules[0x0]._rules = [uint8(0)];
        Molecules[0x0]._cation = bytes32(0x0);
        Molecules[0x0]._anion = [bytes32(0x0)];
        Molecules[0x0]._alias = bytes32(0x0);
        Molecules[0x0]._covalence = true;
        Molecules[0x0]._expiry = theEnd;
        Molecules[0x0]._controller = msg.sender;
        Molecules[0x0]._resolver = msg.sender;
    }

    /**
     * @dev Initialise a new HELIX2 Molecules Registry
     * @notice
     * @param _helix2 : address of HELIX2 Manager
     * @param _registry : address of HELIX2 Name Registry
     */
    constructor(address _registry, address _helix2, address _priceOracle) {
        Dev = msg.sender;
        HELIX2 = iHELIX2(_helix2);
        NAMES = iNAME(_registry);
        roothash = HELIX2.getRoothash()[2];
        PRICES = iPriceOracle(_priceOracle);
        basePrice = PRICES.getPrices()[2];
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
            roothash = HELIX2.getRoothash()[2];
            Registrar = HELIX2.getRegistrar()[2];
        }
        PRICES = iPriceOracle(_priceOracle);
        basePrice = PRICES.getPrices()[2];
    }

    /**
     * @dev : get owner of contract
     * @return : address of controlling dev or multi-sig wallet
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
    modifier onlyController(bytes32 molyhash) {
        require(
            block.timestamp < Molecules[molyhash]._expiry,
            "MOLECULE_EXPIRED"
        );
        require(
            msg.sender == Molecules[molyhash]._controller,
            "NOT_CONTROLLER"
        );
        _;
    }

    /// @dev : Modifier to allow Cation or Controller
    modifier isCationOrController(bytes32 molyhash) {
        require(
            block.timestamp < Molecules[molyhash]._expiry,
            "MOLECULE_EXPIRED"
        );
        bytes32 __cation = Molecules[molyhash]._cation;
        address _cation = NAMES.owner(__cation);
        require(
            _cation == msg.sender ||
                Operators[_cation][msg.sender] ||
                msg.sender == Molecules[molyhash]._controller,
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
    modifier isAuthorised(bytes32 molyhash) {
        bytes32 __cation = Molecules[molyhash]._cation;
        address _cation = NAMES.owner(__cation);
        require(
            msg.sender == Registrar ||
                _cation == msg.sender ||
                Operators[_cation][msg.sender] ||
                msg.sender == Molecules[molyhash]._controller,
            "NOT_AUTHORISED"
        );
        _;
    }

    /**
     * @dev check if molecule is available
     * @param molyhash : hash of molecule
     */
    modifier isAvailable(bytes32 molyhash) {
        require(
            block.timestamp >= Molecules[molyhash]._expiry,
            "MOLECULE_EXISTS"
        );
        _;
    }

    /**
     * @dev verify molecule is not expired
     * @param molyhash : hash of molecule
     */
    modifier isOwned(bytes32 molyhash) {
        require(
            block.timestamp < Molecules[molyhash]._expiry,
            "MOLECULE_EXPIRED"
        );
        _;
    }

    /**
     * @dev check if new config is a duplicate
     * @param molyhash : hash of molecule
     * @param rule : rule to check
     */
    function isNotDuplicateHook(
        bytes32 molyhash,
        uint8 rule
    ) public view returns (bool) {
        return !rule.existsIn(Molecules[molyhash]._rules);
    }

    /**
     * @dev check if new anion is a duplicate
     * @param molyhash : hash of molecule
     * @param _anion : anion to check
     */
    function isNotDuplicateAnion(
        bytes32 molyhash,
        bytes32 _anion
    ) public view returns (bool) {
        return !_anion.existsIn(Molecules[molyhash]._anion);
    }

    /**
     * @dev verify ownership of molecule
     * @param molyhash : hash of molecule
     */
    modifier onlyCation(bytes32 molyhash) {
        require(
            block.timestamp < Molecules[molyhash]._expiry,
            "MOLECULE_EXPIRED"
        );
        bytes32 __cation = Molecules[molyhash]._cation;
        address _cation = NAMES.owner(__cation);
        require(
            _cation == msg.sender || Operators[_cation][msg.sender],
            "NOT_OWNER"
        );
        _;
    }

    /**
     * @dev register owner of new molecule
     * @param molyhash : hash of molecule
     * @param _cation : new cation
     */
    function register(bytes32 molyhash, bytes32 _cation) external isRegistrar {
        require(NAMES.owner(_cation) != address(0), "CANNOT_BURN");
        Molecules[molyhash]._cation = _cation;
        emit NewCation(molyhash, _cation);
    }

    /**
     * @dev set cation of a molecule
     * @param molyhash : hash of molecule
     * @param _cation : new cation
     */
    function setCation(
        bytes32 molyhash,
        bytes32 _cation
    ) external onlyCation(molyhash) {
        require(NAMES.owner(_cation) != address(0), "CANNOT_BURN");
        Molecules[molyhash]._cation = _cation;
        emit NewCation(molyhash, _cation);
    }

    /**
     * @dev set controller of a molecule
     * @param molyhash : hash of molecule
     * @param _controller : new controller
     */
    function setController(
        bytes32 molyhash,
        address _controller
    ) external isAuthorised(molyhash) {
        Molecules[molyhash]._controller = _controller;
        emit NewController(molyhash, _controller);
    }

    /**
     * @dev adds one anion to the molecule
     * @param molyhash : hash of target molecule
     * @param _anion : hash of new anion
     */
    function addAnion(
        bytes32 molyhash,
        bytes32 _anion
    ) external isCationOrController(molyhash) {
        require(isNotDuplicateAnion(molyhash, _anion), "ANION_EXISTS");
        Molecules[molyhash]._anion.push(_anion);
        emit NewAnion(molyhash, _anion);
    }

    /**
     * @dev adds new array of anions to the molecule
     * @notice will skip pre-existing anions
     * @param molyhash : hash of target molecule
     * @param _anion : array of new anions
     */
    function setAnions(
        bytes32 molyhash,
        bytes32[] memory _anion
    ) external isAuthorised(molyhash) {
        for (uint i = 0; i < _anion.length; i++) {
            if (!_anion[i].existsIn(Molecules[molyhash]._anion)) {
                Molecules[molyhash]._anion.push(_anion[i]);
            }
        }
        emit NewAnions(molyhash, _anion);
    }

    /**
     * @dev pops an anion from the molecule
     * @param molyhash : hash of target molecule
     * @param __anion : hash of anion to remove
     */
    function popAnion(
        bytes32 molyhash,
        bytes32 __anion
    ) external isCationOrController(molyhash) {
        bytes32[] memory _anion = Molecules[molyhash]._anion;
        if (__anion.existsIn(_anion)) {
            uint index = __anion.findIn(_anion);
            delete Molecules[molyhash]._anion[index];
            emit PopAnion(molyhash, __anion);
        } else {
            revert BAD_ANION();
        }
    }

    /**
     * @dev set new alias for molecule
     * @param molyhash : hash of molecule
     * @param _alias : bash of alias
     */
    function setAlias(bytes32 molyhash, bytes32 _alias) external isRegistrar {
        Molecules[molyhash]._alias = _alias;
    }

    /**
     * @dev set new mutuality flag for molecule
     * @param molyhash : hash of molecule
     * @param _covalence : bool
     */
    function setCovalence(
        bytes32 molyhash,
        bool _covalence
    ) external isAuthorised(molyhash) {
        Molecules[molyhash]._covalence = _covalence;
        emit NewCovalence(molyhash, _covalence);
    }

    /**
     * @dev set resolver for a molecule
     * @param molyhash : hash of molecule
     * @param _resolver : new resolver
     */
    function setResolver(
        bytes32 molyhash,
        address _resolver
    ) external isAuthorised(molyhash) {
        Molecules[molyhash]._resolver = _resolver;
        emit NewResolver(molyhash, _resolver);
    }

    /**
     * @dev set expiry for a molecule
     * @param molyhash : hash of molecule
     * @param _expiry : new expiry
     */
    function setExpiry(bytes32 molyhash, uint _expiry) external isRegistrar {
        require(_expiry > Molecules[molyhash]._expiry, "BAD_EXPIRY");
        Molecules[molyhash]._expiry = _expiry;
        emit NewExpiry(molyhash, _expiry);
    }

    /**
     * @dev set expiry for a molecule
     * @param molyhash : hash of molecule
     * @param _expiry : new expiry
     */
    function renew(
        bytes32 molyhash,
        uint _expiry
    ) external payable isCationOrController(molyhash) {
        require(_expiry > Molecules[molyhash]._expiry, "BAD_EXPIRY");
        uint newDuration = _expiry - Molecules[molyhash]._expiry;
        require(msg.value >= newDuration * basePrice, "INSUFFICIENT_ETHER");
        Molecules[molyhash]._expiry = _expiry;
        emit NewExpiry(molyhash, _expiry);
    }

    /**
     * @dev set record for a molecule
     * @param molyhash : hash of molecule
     * @param _resolver : new record
     */
    function setRecord(
        bytes32 molyhash,
        address _resolver
    ) external isAuthorised(molyhash) {
        Molecules[molyhash]._resolver = _resolver;
        emit NewRecord(molyhash, _resolver);
    }

    /**
     * @dev adds a new hook with rule
     * @param molyhash : hash of the molecule
     * @param rule : rule for the hook
     * @param config : address of config contract
     */
    function hook(
        bytes32 molyhash,
        address config,
        uint8 rule
    ) external isCationOrController(molyhash) {
        require(isNotDuplicateHook(molyhash, rule), "HOOK_EXISTS");
        Molecules[molyhash]._rules.push(rule);
        Molecules[molyhash]._hooks[rule] = config;
        emit Hooked(molyhash, config, rule);
    }

    /**
     * @dev rehooks a hook to a new rule
     * @param molyhash : hash of the molecule
     * @param rule : rule for the new hook
     * @param config : address of config contract
     */
    function rehook(
        bytes32 molyhash,
        address config,
        uint8 rule
    ) external isCationOrController(molyhash) {
        require(Molecules[molyhash]._hooks[rule] != config, "RULE_EXISTS");
        Molecules[molyhash]._hooks[rule] = config;
        emit Rehooked(molyhash, config, rule);
    }

    /**
     * @dev removes a hook in a molecule
     * @param molyhash : hash of the molecule
     * @param rule : rule to unhook
     */
    function unhook(
        bytes32 molyhash,
        uint8 rule
    ) external isCationOrController(molyhash) {
        uint8[] memory _rules = Molecules[molyhash]._rules;
        if (rule.existsIn(_rules)) {
            uint index = rule.findIn(_rules);
            Molecules[molyhash]._hooks[rule] = address(0);
            emit Unhooked(molyhash, rule);
            delete Molecules[molyhash]._rules[index];
        } else {
            revert BAD_HOOK();
        }
    }

    /**
     * @dev removes all hooks in a molecule
     * @param molyhash : hash of the molecule
     */
    function unhookAll(bytes32 molyhash) external isAuthorised(molyhash) {
        uint8[] memory _rules = Molecules[molyhash]._rules;
        for (uint i = 0; i < _rules.length; i++) {
            Molecules[molyhash]._hooks[_rules[i]] = address(0);
            emit Unhooked(molyhash, _rules[i]);
        }
        delete Molecules[molyhash]._rules;
        emit UnhookedAll(molyhash);
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
     * @dev return cation of a molecule
     * @param molyhash : hash of molecule to query
     * @return hash of cation
     */
    function cation(
        bytes32 molyhash
    ) public view isOwned(molyhash) returns (bytes32) {
        bytes32 __cation = Molecules[molyhash]._cation;
        address _cation = NAMES.owner(__cation);
        if (_cation == address(this)) {
            return roothash;
        }
        return __cation;
    }

    /**
     * @dev return controller of a molecule
     * @param molyhash : hash of molecule to query
     * @return address of controller
     */
    function controller(
        bytes32 molyhash
    ) public view isOwned(molyhash) returns (address) {
        address _controller = Molecules[molyhash]._controller;
        return _controller;
    }

    /**
     * @dev shows mutuality state of a molecule
     * @param molyhash : hash of molecule to query
     * @return mutuality state of the molecule
     */
    function covalence(
        bytes32 molyhash
    ) public view isOwned(molyhash) returns (bool) {
        bool _covalence = Molecules[molyhash]._covalence;
        return _covalence;
    }

    /**
     * @dev shows alias of a molecule
     * @param molyhash : hash of molecule to query
     * @return alias of the molecule
     */
    function alias_(
        bytes32 molyhash
    ) public view isOwned(molyhash) returns (bytes32) {
        bytes32 _alias = Molecules[molyhash]._alias;
        return _alias;
    }

    /**
     * @dev return hooks of a molecule
     * @param molyhash : hash of molecule to query
     * @return _rules
     * @return _hooks
     */
    function hooksWithRules(
        bytes32 molyhash
    )
        public
        view
        isOwned(molyhash)
        returns (uint8[] memory _rules, address[] memory _hooks)
    {
        _rules = Molecules[molyhash]._rules;
        _hooks = new address[](_rules.length);
        for (uint i = 0; i < _rules.length; i++) {
            _hooks[i] = Molecules[molyhash]._hooks[_rules[i]];
        }
    }

    /**
     * @dev return anions of a molecule
     * @param molyhash : hash of molecule to query
     * @return array of anions
     */
    function anion(
        bytes32 molyhash
    ) public view isOwned(molyhash) returns (bytes32[] memory) {
        bytes32[] memory _anion = Molecules[molyhash]._anion;
        return _anion;
    }

    /**
     * @dev return expiry of a molecule
     * @param molyhash : hash of molecule to query
     * @return expiry
     */
    function expiry(bytes32 molyhash) public view returns (uint) {
        uint _expiry = Molecules[molyhash]._expiry;
        return _expiry;
    }

    /**
     * @dev return resolver of a molecule
     * @param molyhash : hash of molecule to query
     * @return address of resolver
     */
    function resolver(
        bytes32 molyhash
    ) public view isOwned(molyhash) returns (address) {
        address _resolver = Molecules[molyhash]._resolver;
        return _resolver;
    }

    /**
     * @dev check if a molecule is registered
     * @param molyhash : hash of molecule to query
     * @return true or false
     */
    function recordExists(bytes32 molyhash) public view returns (bool) {
        return block.timestamp < Molecules[molyhash]._expiry;
    }

    /**
     * @dev check if an address is set as operator
     * @param _cation cation of molecule to query
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
