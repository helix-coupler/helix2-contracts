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
 * @title Helix2 Molecule Registry
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
    iMOLECULE public STORE;
    iPriceOracle public PRICES;

    /// @dev : Helix2 Molecule events
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event Hooked(bytes32 indexed molyhash, address config, uint8 rule);
    event Rehooked(bytes32 indexed molyhash, address config, uint8 rule);
    event Unhooked(bytes32 indexed molyhash, uint8 rule);
    event UnhookedAll(bytes32 indexed molyhash);
    event NewCation(bytes32 indexed molyhash, bytes32 cation);
    event NewAnion(bytes32 indexed molyhash, bytes32 anion);
    event NewAnions(bytes32 indexed molyhash, bytes32[] anion);
    event PopAnion(bytes32 indexed molyhash, bytes32 anion);
    event NewController(bytes32 indexed molyhash, address controller);
    event NewExpiry(bytes32 indexed molyhash, uint expiry);
    event NewCovalence(bytes32 indexed molyhash, bool covalence);
    event NewResolver(bytes32 indexed molyhash, address resolver);

    error BAD_ANION();
    error BAD_RULE();
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
        bytes32 _label; /// Hash of Molecule
        address _resolver; /// Resolver of Molecule
        address _controller; /// Controller of Molecule
        bool _covalence; /// Mutuality Flag
        uint _expiry; /// Expiry of Molecule
    }
    mapping(bytes32 => Molecule) public Molecules;
    mapping(address => mapping(address => bool)) Operators;

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
     * @param _store : address of HELIX2 Polycule Storage
     */
    function setConfig(
        address _helix2,
        address _priceOracle,
        address _store
    ) external onlyDev {
        if (_helix2 != address(0)) {
            HELIX2 = iHELIX2(_helix2);
            roothash = HELIX2.getRoothash()[2];
            Registrar = HELIX2.getRegistrar()[2];
        }
        if (_store != address(0)) {
            STORE = iMOLECULE(_store);
        }
        if (_priceOracle != address(0)) {
            PRICES = iPriceOracle(_priceOracle);
            basePrice = PRICES.getPrices()[2];
        }
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

    /// @dev : Modifier to allow Cation or Controller
    modifier isCationOrController(bytes32 molyhash) {
        require(block.timestamp < STORE.expiry(molyhash), "MOLECULE_EXPIRED");
        bytes32 _cation = STORE.cation(molyhash);
        address _owner = NAMES.owner(_cation);
        require(
            _owner == msg.sender || msg.sender == STORE.controller(molyhash),
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
        bytes32 _cation = STORE.cation(molyhash);
        address _owner = NAMES.owner(_cation);
        require(
            msg.sender == Registrar ||
                _owner == msg.sender ||
                msg.sender == STORE.controller(molyhash),
            "NOT_AUTHORISED"
        );
        _;
    }

    /**
     * @dev check if polycule is not expired
     * and can emit records
     * @param molyhash : hash of polycule
     */
    modifier canEmit(bytes32 molyhash) {
        require(block.timestamp < STORE.expiry(molyhash), "MOLECULE_EXPIRED");
        _;
    }

    /**
     * @dev verify ownership of molecule
     * @param molyhash : hash of molecule
     */
    modifier isCation(bytes32 molyhash) {
        require(block.timestamp < STORE.expiry(molyhash), "MOLECULE_EXPIRED");
        address _owner = NAMES.owner(STORE.cation(molyhash));
        require(_owner == msg.sender, "NOT_OWNER");
        _;
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
        return !_anion.existsIn(STORE.anions(molyhash));
    }

    /**
     * @dev check if new config is a duplicate
     * @param molyhash : hash of molecule
     * @param rule : rule to check
     */
    function isNotDuplicateRule(
        bytes32 molyhash,
        uint8 rule
    ) public view returns (bool) {
        (uint8[] memory _rules, ) = STORE.hooksWithRules(molyhash);
        return !rule.existsIn(_rules);
    }

    /**
     * @dev register owner of new molecule
     * @param molyhash : hash of molecule
     * @param _cation : new cation
     */
    function register(bytes32 molyhash, bytes32 _cation) external isRegistrar {
        require(NAMES.owner(_cation) != address(0), "CANNOT_BURN");
        STORE.setCation(molyhash, _cation);
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
    ) external isCation(molyhash) {
        require(NAMES.owner(_cation) != address(0), "CANNOT_BURN");
        STORE.setCation(molyhash, _cation);
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
        STORE.setController(molyhash, _controller);
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
        STORE.addAnion(molyhash, _anion);
        emit NewAnion(molyhash, _anion);
    }

    /**
     * @dev adds new array of anions to the molecule
     * @notice will skip pre-existing anions
     * @param molyhash : hash of target molecule
     * @param _anions : array of new anions
     */
    function setAnions(
        bytes32 molyhash,
        bytes32[] memory _anions
    ) external isAuthorised(molyhash) {
        bytes32[] memory _anions_ = STORE.anions(molyhash);
        for (uint i = 0; i < _anions.length; i++) {
            if (!_anions[i].existsIn(_anions_)) {
                STORE.addAnion(molyhash, _anions[i]);
            }
        }
        emit NewAnions(molyhash, _anions);
    }

    /**
     * @dev pops an anion from the molecule
     * @param molyhash : hash of target molecule
     * @param _anion : hash of anion to remove
     */
    function popAnion(
        bytes32 molyhash,
        bytes32 _anion
    ) external isCationOrController(molyhash) {
        bytes32[] memory _anions = STORE.anions(molyhash);
        if (_anion.existsIn(_anions)) {
            uint index = _anion.findIn(_anions);
            STORE.popAnion(molyhash, index);
            emit PopAnion(molyhash, _anion);
        } else {
            revert BAD_ANION();
        }
    }

    /**
     * @dev set new label for molecule
     * @param molyhash : hash of molecule
     * @param _label : bash of label
     */
    function setLabel(bytes32 molyhash, bytes32 _label) external isRegistrar {
        STORE.setLabel(molyhash, _label);
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
        STORE.setCovalence(molyhash, _covalence);
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
        STORE.setResolver(molyhash, _resolver);
        emit NewResolver(molyhash, _resolver);
    }

    /**
     * @dev set expiry for a molecule
     * @param molyhash : hash of molecule
     * @param _expiry : new expiry
     */
    function setExpiry(bytes32 molyhash, uint _expiry) external isRegistrar {
        require(_expiry > STORE.expiry(molyhash), "BAD_EXPIRY");
        STORE.setExpiry(molyhash, _expiry);
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
        uint currentExpiry = STORE.expiry(molyhash);
        require(_expiry > currentExpiry, "BAD_EXPIRY");
        require(
            msg.value >= (_expiry - currentExpiry) * basePrice,
            "INSUFFICIENT_ETHER"
        );
        STORE.setExpiry(molyhash, _expiry);
        emit NewExpiry(molyhash, _expiry);
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
        require(isNotDuplicateRule(molyhash, rule), "RULE_EXISTS");
        STORE.hook(molyhash, config, rule);
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
        (uint8[] memory _rules, address[] memory _hooks) = STORE.hooksWithRules(
            molyhash
        );
        if (rule.existsIn(_rules)) {
            uint index = rule.findIn(_rules);
            require(_hooks[index] != config, "RULE_EXISTS");
            STORE.rehook(molyhash, config, rule);
            emit Rehooked(molyhash, config, rule);
        } else {
            revert BAD_RULE();
        }
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
        (uint8[] memory _rules, ) = STORE.hooksWithRules(molyhash);
        if (rule.existsIn(_rules)) {
            uint index = rule.findIn(_rules);
            STORE.unhook(molyhash, rule, index);
            emit Unhooked(molyhash, rule);
        } else {
            revert BAD_HOOK();
        }
    }

    /**
     * @dev removes all hooks in a molecule
     * @param molyhash : hash of the molecule
     */
    function unhookAll(bytes32 molyhash) external isAuthorised(molyhash) {
        STORE.unhookAll(molyhash);
        emit UnhookedAll(molyhash);
    }

    /**
     * @dev return cation of a molecule
     * @param molyhash : hash of molecule to query
     * @return hash of cation
     */
    function cation(
        bytes32 molyhash
    ) public view canEmit(molyhash) returns (bytes32) {
        bytes32 _cation = STORE.cation(molyhash);
        address _owner = NAMES.owner(_cation);
        if (_owner == address(this)) {
            return bytes32(0);
        }
        return _cation;
    }

    /**
     * @dev return controller of a molecule
     * @param molyhash : hash of molecule to query
     * @return address of controller
     */
    function controller(
        bytes32 molyhash
    ) public view canEmit(molyhash) returns (address) {
        return STORE.controller(molyhash);
    }

    /**
     * @dev shows mutuality state of a molecule
     * @param molyhash : hash of molecule to query
     * @return mutuality state of the molecule
     */
    function covalence(
        bytes32 molyhash
    ) public view canEmit(molyhash) returns (bool) {
        return STORE.covalence(molyhash);
    }

    /**
     * @dev shows label of a molecule
     * @param molyhash : hash of molecule to query
     * @return label of the molecule
     */
    function label(
        bytes32 molyhash
    ) public view canEmit(molyhash) returns (bytes32) {
        return STORE.label(molyhash);
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
        canEmit(molyhash)
        returns (uint8[] memory _rules, address[] memory _hooks)
    {
        (_rules, _hooks) = STORE.hooksWithRules(molyhash);
    }

    /**
     * @dev return anions of a molecule
     * @param molyhash : hash of molecule to query
     * @return array of anions
     */
    function anions(
        bytes32 molyhash
    ) public view canEmit(molyhash) returns (bytes32[] memory) {
        return STORE.anions(molyhash);
    }

    /**
     * @dev return expiry of a molecule
     * @param molyhash : hash of molecule to query
     * @return expiry
     */
    function expiry(bytes32 molyhash) public view returns (uint) {
        return STORE.expiry(molyhash);
    }

    /**
     * @dev return resolver of a molecule
     * @param molyhash : hash of molecule to query
     * @return address of resolver
     */
    function resolver(
        bytes32 molyhash
    ) public view canEmit(molyhash) returns (address) {
        return STORE.resolver(molyhash);
    }

    /**
     * @dev check if a molecule is registered
     * @param molyhash : hash of molecule to query
     * @return true or false
     */
    function recordExists(bytes32 molyhash) public view returns (bool) {
        return block.timestamp < STORE.expiry(molyhash);
    }
}
