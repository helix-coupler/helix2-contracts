//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Names/iName.sol";
import "src/Polycules/iPolycule.sol";
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
 * @title Helix2 Polycule Registry
 */
contract Helix2PolyculeRegistry {
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
    iPOLYCULE public STORE;
    iPriceOracle public PRICES;

    /// @dev : Helix2 Polycule events
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event Hooked(bytes32 indexed polyhash, address config, uint8 rule);
    event RehookedConfig(bytes32 indexed polyhash, address config, uint8 rule);
    event UnhookedConfig(bytes32 indexed polyhash, uint8 rule);
    event RehookedAnion(bytes32 indexed polyhash, bytes32 anion, uint8 rule);
    event UnhookedAnion(bytes32 indexed polyhash, bytes32 anion);
    event UnhookedAll(bytes32 indexed polyhash);
    event NewCation(bytes32 indexed polyhash, bytes32 cation);
    event NewAnion(bytes32 indexed polyhash, bytes32 anion);
    event NewAnions(bytes32 indexed polyhash, bytes32[] anion);
    event PopAnion(bytes32 indexed polyhash, bytes32 anion);
    event NewController(bytes32 indexed polyhash, address controller);
    event NewExpiry(bytes32 indexed polyhash, uint expiry);
    event NewCovalence(bytes32 indexed polyhash, bool covalence);
    event NewResolver(bytes32 indexed polyhash, address resolver);

    error BAD_ANION();
    error BAD_RULE();
    error BAD_HOOK();

    /// Dev
    address public Dev;

    /// @dev : Pause/Resume contract
    bool public active = true;
    /// @dev : EIP-165
    mapping(bytes4 => bool) public supportsInterface;

    /// @dev : Polycule roothash
    bytes32 public roothash;
    uint256 public basePrice;
    address public Registrar;
    uint256 public theEnd = 250_000_000_000_000_000; // roughly 80,000,000,000 years in the future

    /**
     * @dev Initialise a new HELIX2 Polycules Registry
     * @notice
     * @param _helix2 : address of HELIX2 Manager
     * @param _registry : address of HELIX2 Name Registry
     */
    constructor(address _registry, address _helix2, address _priceOracle) {
        Dev = msg.sender;
        HELIX2 = iHELIX2(_helix2);
        NAMES = iNAME(_registry);
        roothash = HELIX2.getRoothash()[3];
        PRICES = iPriceOracle(_priceOracle);
        basePrice = PRICES.getPrices()[3];
        // Interface
        supportsInterface[type(iERC165).interfaceId] = true;
        supportsInterface[type(iERC173).interfaceId] = true;
    }

    /// @dev : Modifier to allow Dev
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
            roothash = HELIX2.getRoothash()[3];
            Registrar = HELIX2.getRegistrar()[3];
        }
        if (_store != address(0)) {
            STORE = iPOLYCULE(_store);
        }
        if (_priceOracle != address(0)) {
            PRICES = iPriceOracle(_priceOracle);
            basePrice = PRICES.getPrices()[3];
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
    modifier isCationOrController(bytes32 polyhash) {
        require(block.timestamp < STORE.expiry(polyhash), "POLYCULE_EXPIRED");
        bytes32 _cation = STORE.cation(polyhash);
        address _owner = NAMES.owner(_cation);
        require(
            _owner == msg.sender || msg.sender == STORE.controller(polyhash),
            "NOT_OWNER_OR_CONTROLLER"
        );
        _;
    }

    /// @dev : Modifier to allow Registrar
    modifier isRegistrar() {
        require(msg.sender == Registrar, "NOT_REGISTRAR");
        _;
    }

    /// @dev : Modifier to allow Cation, Controller or Registrar
    modifier isAuthorised(bytes32 polyhash) {
        bytes32 _cation = STORE.cation(polyhash);
        address _owner = NAMES.owner(_cation);
        require(
            msg.sender == Registrar ||
                _owner == msg.sender ||
                msg.sender == STORE.controller(polyhash),
            "NOT_AUTHORISED"
        );
        _;
    }

    /**
     * @dev check if polycule is not expired
     * and can emit records
     * @param polyhash : hash of polycule
     */
    modifier canEmit(bytes32 polyhash) {
        require(block.timestamp < STORE.expiry(polyhash), "NAME_EXPIRED");
        _;
    }

    /**
     * @dev verify ownership of polycule
     * @param polyhash : hash of polycule
     */
    modifier isCation(bytes32 polyhash) {
        require(block.timestamp < STORE.expiry(polyhash), "POLYCULE_EXPIRED");
        address _owner = NAMES.owner(STORE.cation(polyhash));
        require(_owner == msg.sender, "NOT_OWNER");
        _;
    }

    /**
     * @dev check if new anion is a duplicate
     * @param polyhash : hash of polycule
     * @param _anion : anion to check
     */
    function isNotDuplicateAnionOrHook(
        bytes32 polyhash,
        bytes32 _anion,
        uint8 rule
    ) internal view returns (bool) {
        return
            !_anion.existsIn(STORE.anions(polyhash)) &&
            !rule.existsIn(STORE.rules(polyhash));
    }

    /**
     * @dev verify if each anion has a hook
     * @param _anions : array of anions
     * @param _rules : array of config addresses
     */
    function isLegalMap(
        bytes32[] memory _anions,
        uint8[] memory _rules
    ) internal pure returns (bool) {
        if (_anions.length == _rules.length) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev register owner of new polycule
     * @param polyhash : hash of polycule
     * @param _cation : new cation
     */
    function register(bytes32 polyhash, bytes32 _cation) external isRegistrar {
        require(NAMES.owner(_cation) != address(0), "CANNOT_BURN");
        STORE.setCation(polyhash, _cation);
        emit NewCation(polyhash, _cation);
    }

    /**
     * @dev set cation of a polycule
     * @param polyhash : hash of polycule
     * @param _cation : new cation
     */
    function setCation(
        bytes32 polyhash,
        bytes32 _cation
    ) external isCation(polyhash) {
        require(NAMES.owner(_cation) != address(0), "CANNOT_BURN");
        STORE.setCation(polyhash, _cation);
        emit NewCation(polyhash, _cation);
    }

    /**
     * @dev set controller of a polycule
     * @param polyhash : hash of polycule
     * @param _controller : new controller
     */
    function setController(
        bytes32 polyhash,
        address _controller
    ) external isAuthorised(polyhash) {
        STORE.setController(polyhash, _controller);
        emit NewController(polyhash, _controller);
    }

    /**
     * @dev adds one anion to the polycule
     * @param polyhash : hash of target polycule
     * @param _anion : hash of new anion
     * @param config : config address for the rule
     * @param rule : rule for the new anion
     */
    function addAnionWithConfig(
        bytes32 polyhash,
        bytes32 _anion,
        address config,
        uint8 rule
    ) external isCationOrController(polyhash) {
        require(
            isNotDuplicateAnionOrHook(polyhash, _anion, rule),
            "ANION_OR_HOOK_EXISTS"
        );
        (uint8[] memory _rules, address[] memory _hooks) = STORE.hooksWithRules(
            polyhash
        );
        uint index = rule.findIn(_rules);
        require(_hooks[index] != config, "RULE_EXISTS");
        STORE.addAnionWithConfig(polyhash, _anion, config, rule);
        emit NewAnion(polyhash, _anion);
        emit Hooked(polyhash, config, rule);
    }

    /**
     * @dev adds new array of anions to the polycule
     * @notice will skip pre-existing anions & hook configs
     * @param polyhash : hash of target polycule
     * @param _anions : array of new anions
     * @param _hooks : array of rules for hooks
     * @param _rules : array of new matching config
     */
    function setAnions(
        bytes32 polyhash,
        bytes32[] memory _anions,
        address[] memory _hooks,
        uint8[] memory _rules
    ) external isAuthorised(polyhash) {
        require(isLegalMap(_anions, _rules), "BAD_MAP");
        for (uint i = 0; i < _anions.length; i++) {
            if (!_anions[i].existsIn(STORE.anions(polyhash))) {
                STORE.addAnionWithConfig(
                    polyhash,
                    _anions[i],
                    _hooks[i],
                    _rules[i]
                );
                STORE.setCovalence(polyhash, false);
            }
        }
        emit NewAnions(polyhash, _anions);
    }

    /**
     * @dev pops an anion from the polycule
     * @param polyhash : hash of target polycule
     * @param _anion : hash of anion to remove
     */
    function popAnion(
        bytes32 polyhash,
        bytes32 _anion
    ) external isCationOrController(polyhash) {
        bytes32[] memory _anions = STORE.anions(polyhash);
        if (_anion.existsIn(_anions)) {
            uint index = _anion.findIn(_anions);
            STORE.popAnion(polyhash, index);
            emit PopAnion(polyhash, _anion);
        } else {
            revert BAD_ANION();
        }
    }

    /**
     * @dev set new label for polycule
     * @param polyhash : hash of polycule
     * @param _label : bash of label
     */
    function setLabel(bytes32 polyhash, bytes32 _label) external isRegistrar {
        STORE.setLabel(polyhash, _label);
    }

    /**
     * @dev switches mutuality flag
     * @notice
     * @param polyhash : hash of polycule
     * @param _covalence : new covalence flag
     */
    function setCovalence(
        bytes32 polyhash,
        bool _covalence
    ) external isAuthorised(polyhash) {
        STORE.setCovalence(polyhash, _covalence);
        emit NewCovalence(polyhash, _covalence);
    }

    /**
     * @dev set resolver for a polycule
     * @param polyhash : hash of polycule
     * @param _resolver : new resolver
     */
    function setResolver(
        bytes32 polyhash,
        address _resolver
    ) external isAuthorised(polyhash) {
        STORE.setResolver(polyhash, _resolver);
        emit NewResolver(polyhash, _resolver);
    }

    /**
     * @dev set expiry for a polycule
     * @param polyhash : hash of polycule
     * @param _expiry : new expiry
     */
    function setExpiry(bytes32 polyhash, uint _expiry) external isRegistrar {
        require(_expiry > STORE.expiry(polyhash), "BAD_EXPIRY");
        STORE.setExpiry(polyhash, _expiry);
        emit NewExpiry(polyhash, _expiry);
    }

    /**
     * @dev set expiry for a polycule
     * @param polyhash : hash of polycule
     * @param _expiry : new expiry
     */
    function renew(
        bytes32 polyhash,
        uint _expiry
    ) external payable isCationOrController(polyhash) {
        uint currentExpiry = STORE.expiry(polyhash);
        require(_expiry > currentExpiry, "BAD_EXPIRY");
        require(
            msg.value >= (_expiry - currentExpiry) * basePrice,
            "INSUFFICIENT_ETHER"
        );
        STORE.setExpiry(polyhash, _expiry);
        emit NewExpiry(polyhash, _expiry);
    }

    /**
     * @dev adds a new hook & rule and anion
     * @param _anion : anion to add hook for
     * @param polyhash : hash of the polycule
     * @param config : address of config contract
     * @param rule : rule for the hook (and anion)
     */
    function hook(
        bytes32 _anion,
        bytes32 polyhash,
        address config,
        uint8 rule
    ) external isCationOrController(polyhash) {
        require(
            isNotDuplicateAnionOrHook(polyhash, _anion, rule),
            "ANION_OR_HOOK_EXISTS"
        );
        STORE.hook(_anion, polyhash, config, rule);
        emit Hooked(polyhash, config, rule);
    }

    /**
     * @dev rehooks a hook to a new rule
     * @param polyhash : hash of the polycule
     * @param config : address of config contract
     * @param rule : rule for the new hook
     */
    function rehook(
        bytes32 polyhash,
        address config,
        uint8 rule
    ) external isCationOrController(polyhash) {
        (uint8[] memory _rules, address[] memory _hooks) = STORE.hooksWithRules(
            polyhash
        );
        if (rule.existsIn(_rules)) {
            uint index = rule.findIn(_rules);
            require(_hooks[index] != config, "HOOK_EXISTS");
            STORE.rehook(polyhash, config, rule);
            emit RehookedConfig(polyhash, config, rule);
        } else {
            revert BAD_RULE();
        }
    }

    /**
     * @dev removes a hook in a polycule
     * @param polyhash : hash of the polycule
     * @param rule : rule to unhook
     */
    function unhook(
        bytes32 polyhash,
        uint8 rule
    ) external isCationOrController(polyhash) {
        uint8[] memory _rules = STORE.rules(polyhash);
        if (rule.existsIn(_rules)) {
            uint index = rule.findIn(_rules);
            STORE.unhook(polyhash, rule, index);
            emit UnhookedConfig(polyhash, rule);
        } else {
            revert BAD_HOOK();
        }
    }

    /**
     * @dev removes all hooks (and anions) in a polycule
     * @param polyhash : hash of the polycule
     */
    function unhookAll(
        bytes32 polyhash
    ) external isCationOrController(polyhash) {
        STORE.unhookAll(polyhash);
        emit UnhookedAll(polyhash);
    }

    /**
     * @dev return cation of a polycule
     * @param polyhash : hash of polycule to query
     * @return hash of cation
     */
    function cation(
        bytes32 polyhash
    ) public view canEmit(polyhash) returns (bytes32) {
        bytes32 _cation = STORE.cation(polyhash);
        address _owner = NAMES.owner(_cation);
        if (_owner == address(this)) {
            return bytes32(0);
        }
        return _cation;
    }

    /**
     * @dev return controller of a polycule
     * @param polyhash : hash of polycule to query
     * @return address of controller
     */
    function controller(
        bytes32 polyhash
    ) public view canEmit(polyhash) returns (address) {
        return STORE.controller(polyhash);
    }

    /**
     * @dev shows mutuality state of a polycule
     * @param polyhash : hash of polycule to query
     * @return mutuality state of the polycule
     */
    function covalence(
        bytes32 polyhash
    ) public view canEmit(polyhash) returns (bool) {
        return STORE.covalence(polyhash);
    }

    /**
     * @dev shows label of a polycule
     * @param polyhash : hash of polycule to query
     * @return label of the polycule
     */
    function label(
        bytes32 polyhash
    ) public view canEmit(polyhash) returns (bytes32) {
        return STORE.label(polyhash);
    }

    /**
     * @dev return hooks of a polycule
     * @param polyhash : hash of polycule to query
     * @return _rules
     * @return _hooks
     */
    function hooksWithRules(
        bytes32 polyhash
    )
        public
        view
        canEmit(polyhash)
        returns (uint8[] memory _rules, address[] memory _hooks)
    {
        (_rules, _hooks) = STORE.hooksWithRules(polyhash);
    }

    /**
     * @dev return anions of a polycule
     * @param polyhash : hash of polycule to query
     * @return array of anions
     */
    function anions(
        bytes32 polyhash
    ) public view canEmit(polyhash) returns (bytes32[] memory) {
        return STORE.anions(polyhash);
    }

    /**
     * @dev return expiry of a polycule
     * @param polyhash : hash of polycule to query
     * @return expiry
     */
    function expiry(bytes32 polyhash) public view returns (uint) {
        return STORE.expiry(polyhash);
    }

    /**
     * @dev return resolver of a polycule
     * @param polyhash : hash of polycule to query
     * @return address of resolver
     */
    function resolver(
        bytes32 polyhash
    ) public view canEmit(polyhash) returns (address) {
        return STORE.resolver(polyhash);
    }

    /**
     * @dev check if a polycule is registered
     * @param polyhash : hash of polycule to query
     * @return true or false
     */
    function recordExists(bytes32 polyhash) public view returns (bool) {
        return block.timestamp < STORE.expiry(polyhash);
    }
}
