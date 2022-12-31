//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Names/iName.sol";
import "src/Polycules/iPolycule.sol";
import "src/Interface/iHelix2.sol";
import "src/Utils/LibString.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Polycule Base
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

    /// @dev : Helix2 Polycule events
    event NewDev(address Dev, address newDev);
    event NewPolycule(bytes32 indexed polyhash, bytes32 cation);
    event Hooked(bytes32 indexed polyhash, address config, uint8 rule);
    event RehookedConfig(bytes32 indexed polyhash, address config, uint8 rule);
    event UnhookedConfig(bytes32 indexed polyhash, uint8 rule);
    event RehookedAnion(bytes32 indexed polyhash, bytes32 anion, uint8 rule);
    event UnhookedAnion(bytes32 indexed polyhash, bytes32 anion);
    event UnhookedAll(bytes32 indexed polyhash);
    event NewCation(bytes32 indexed polyhash, bytes32 cation);
    event NewRegistration(bytes32 indexed polyhash, bytes32 cation);
    event NewAnion(bytes32 indexed polyhash, bytes32 anion);
    event NewAnions(bytes32 indexed polyhash, bytes32[] anion);
    event PopAnion(bytes32 indexed polyhash, bytes32 anion);
    event NewAlias(bytes32 indexed polyhash, bytes32 _alias);
    event NewController(bytes32 indexed polyhash, address controller);
    event NewExpiry(bytes32 indexed polyhash, uint expiry);
    event NewRecord(bytes32 indexed polyhash, address resolver);
    event NewCovalence(bytes32 indexed polyhash, bool covalence);
    event NewResolver(bytes32 indexed polyhash, address resolver);
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

    /// @dev : Polycule roothash
    bytes32 public roothash;
    uint256 public basePrice;
    address public Registrar;
    uint256 public theEnd = 250_000_000_000_000_000; // roughly 80,000,000,000 years in the future

    /// @dev : Helix2 POLYCULE struct
    struct Polycule {
        uint8[] _rules; /// Rules
        mapping(uint8 => address) _hooks; /// Rules → Hooks
        bytes32 _cation; /// Source of Polycule (= Owner)
        bytes32[] _anion; /// Targets of Polycule
        bytes32 _alias; /// Hash of Polycule
        address _resolver; /// Resolver of Polycule
        address _controller; /// Controller of Polycule
        bool _covalence; /// Mutuality Flags
        uint _expiry; /// Expiry of Polycule
    }
    mapping(bytes32 => Polycule) public Polycules;
    mapping(address => mapping(address => bool)) Operators;

    /**
     * @dev : sets permissions for 0x0 and roothash
     * @notice : consider changing msg.sender → address(this)
     */
    function catalyse() internal {
        // 0x0
        Polycules[0x0]._hooks[uint8(0)] = address(0x0);
        Polycules[0x0]._rules = [uint8(0)];
        Polycules[0x0]._cation = bytes32(0x0);
        Polycules[0x0]._anion = [bytes32(0x0)];
        Polycules[0x0]._alias = bytes32(0x0);
        Polycules[0x0]._covalence = true;
        Polycules[0x0]._expiry = theEnd;
        Polycules[0x0]._controller = msg.sender;
        Polycules[0x0]._resolver = msg.sender;
        // root
        bytes32[4] memory hashes = HELIX2.getRoothash();
        for (uint i = 0; i < hashes.length; i++) {
            Polycules[hashes[i]]._hooks[uint8(0)] = address(0x0);
            Polycules[hashes[i]]._rules = [uint8(0)];
            Polycules[hashes[i]]._cation = hashes[i];
            Polycules[hashes[i]]._anion = [hashes[i]];
            Polycules[hashes[i]]._alias = hashes[i];
            Polycules[hashes[i]]._covalence = true;
            Polycules[hashes[i]]._expiry = theEnd;
            Polycules[hashes[i]]._controller = msg.sender;
            Polycules[hashes[i]]._resolver = msg.sender;
        }
    }

    /**
     * @dev Initialise a new HELIX2 Polycules Registry
     * @notice : constructor notes
     * @param _helix2 : address of HELIX2 Manager
     * @param _registry : address of HELIX2 Name Registry
     */
    constructor(address _registry, address _helix2) {
        Dev = msg.sender;
        HELIX2 = iHELIX2(_helix2);
        NAMES = iNAME(_registry);
        roothash = HELIX2.getRoothash()[3];
        basePrice = HELIX2.getPrices()[3];
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
    modifier onlyController(bytes32 polyhash) {
        require(
            block.timestamp < Polycules[polyhash]._expiry,
            "POLYCULE_EXPIRED"
        );
        require(
            msg.sender == Polycules[polyhash]._controller,
            "NOT_CONTROLLER"
        );
        _;
    }

    /// @dev : Modifier to allow Cation or Controller
    modifier isCationOrController(bytes32 polyhash) {
        require(
            block.timestamp < Polycules[polyhash]._expiry,
            "POLYCULE_EXPIRED"
        );
        bytes32 __cation = Polycules[polyhash]._cation;
        address _cation = NAMES.owner(__cation);
        require(
            _cation == msg.sender ||
                Operators[_cation][msg.sender] ||
                msg.sender == Polycules[polyhash]._controller,
            "NOT_OWNER_OR_CONTROLLER"
        );
        _;
    }

    /// @dev : Modifier to allow Owner, Controller or Registrar
    modifier isAuthorised(bytes32 polyhash) {
        Registrar = HELIX2.getRegistrar()[3];
        bytes32 __cation = Polycules[polyhash]._cation;
        address _cation = NAMES.owner(__cation);
        require(
            msg.sender == Registrar ||
                _cation == msg.sender ||
                Operators[_cation][msg.sender] ||
                msg.sender == Polycules[polyhash]._controller,
            "NOT_AUTHORISED"
        );
        _;
    }

    /// @dev : Modifier to allow Registrar
    modifier isRegistrar() {
        Registrar = HELIX2.getRegistrar()[3];
        require(msg.sender == Registrar, "NOT_REGISTRAR");
        _;
    }

    /**
     * @dev : check if polycule is available
     * @param polyhash : hash of polycule
     */
    modifier isAvailable(bytes32 polyhash) {
        require(
            block.timestamp >= Polycules[polyhash]._expiry,
            "POLYCULE_EXISTS"
        );
        _;
    }

    /**
     * @dev : verify polycule is not expired
     * @param polyhash : hash of polycule
     */
    modifier isOwned(bytes32 polyhash) {
        require(
            block.timestamp < Polycules[polyhash]._expiry,
            "POLYCULE_EXPIRED"
        );
        _;
    }

    /**
     * @dev : check if new config is a duplicate
     * @param polyhash : hash of polycule
     * @param rule : rule to check
     */
    function isNotDuplicateHook(
        bytes32 polyhash,
        uint8 rule
    ) public view returns (bool) {
        return !rule.existsIn(Polycules[polyhash]._rules);
    }

    /**
     * @dev : check if new anion is a duplicate
     * @param polyhash : hash of polycule
     * @param _anion : anion to check
     */
    function isNotDuplicateAnion(
        bytes32 polyhash,
        bytes32 _anion
    ) public view returns (bool) {
        return !_anion.existsIn(Polycules[polyhash]._anion);
    }

    /**
     * @dev : verify if each anion has a hook
     * @param _anion : array of anions
     * @param _rule : array of config addresses
     */
    function isLegalMap(
        bytes32[] memory _anion,
        uint8[] memory _rule
    ) public pure returns (bool) {
        if (_anion.length == _rule.length) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev : verify ownership of polycule
     * @param polyhash : hash of polycule
     */
    modifier onlyCation(bytes32 polyhash) {
        require(
            block.timestamp < Polycules[polyhash]._expiry,
            "POLYCULE_EXPIRED"
        );
        bytes32 __cation = Polycules[polyhash]._cation;
        address _cation = NAMES.owner(__cation);
        require(
            _cation == msg.sender || Operators[_cation][msg.sender],
            "NOT_OWNER"
        );
        _;
    }

    /**
     * @dev : register owner of new polycule
     * @param polyhash : hash of polycule
     * @param _cation : new cation
     */
    function register(bytes32 polyhash, bytes32 _cation) external isRegistrar {
        require(NAMES.owner(_cation) != address(0), "CANNOT_BURN");
        Polycules[polyhash]._cation = _cation;
        emit NewCation(polyhash, _cation);
        emit NewRegistration(polyhash, _cation);
    }

    /**
     * @dev : set cation of a polycule
     * @param polyhash : hash of polycule
     * @param _cation : new cation
     */
    function setCation(
        bytes32 polyhash,
        bytes32 _cation
    ) external onlyCation(polyhash) {
        require(NAMES.owner(_cation) != address(0), "CANNOT_BURN");
        Polycules[polyhash]._cation = _cation;
        emit NewCation(polyhash, _cation);
    }

    /**
     * @dev : set controller of a polycule
     * @param polyhash : hash of polycule
     * @param _controller : new controller
     */
    function setController(
        bytes32 polyhash,
        address _controller
    ) external isAuthorised(polyhash) {
        Polycules[polyhash]._controller = _controller;
        emit NewController(polyhash, _controller);
    }

    /**
     * @dev : adds one anion to the polycule
     * @param polyhash : hash of target polycule
     * @param _anion : hash of new anion
     * @param config : config address for the rule
     * @param rule : rule for the new anion
     */
    function addAnion(
        bytes32 polyhash,
        bytes32 _anion,
        address config,
        uint8 rule
    ) external isCationOrController(polyhash) {
        require(isNotDuplicateAnion(polyhash, _anion), "ANION_EXISTS");
        require(isNotDuplicateHook(polyhash, rule), "HOOK_EXISTS");
        require(Polycules[polyhash]._hooks[rule] != config, "RULE_EXISTS");
        Polycules[polyhash]._anion.push(_anion);
        Polycules[polyhash]._rules.push(rule);
        Polycules[polyhash]._hooks[rule] == config;
        emit NewAnion(polyhash, _anion);
        emit Hooked(polyhash, config, rule);
    }

    /**
     * @dev : adds new array of anions to the polycule
     * @notice : will skip pre-existing anions & hook configs
     * @param polyhash : hash of target polycule
     * @param _anion : array of new anions
     * @param _hooks : array of rules for hooks
     * @param _rule : array of new matching config
     */
    function setAnions(
        bytes32 polyhash,
        bytes32[] memory _anion,
        address[] memory _hooks,
        uint8[] memory _rule
    ) external isAuthorised(polyhash) {
        require(isLegalMap(_anion, _rule), "BAD_MAP");
        for (uint i = 0; i < _anion.length; i++) {
            if (!_anion[i].existsIn(Polycules[polyhash]._anion)) {
                Polycules[polyhash]._anion.push(_anion[i]);
                Polycules[polyhash]._rules.push(_rule[i]);
                Polycules[polyhash]._hooks[_rule[i]] = _hooks[i];
                Polycules[polyhash]._covalence = false;
            }
        }
        emit NewAnions(polyhash, _anion);
    }

    /**
     * @dev : pops an anion from the polycule
     * @param polyhash : hash of target polycule
     * @param __anion : hash of anion to remove
     */
    function popAnion(
        bytes32 polyhash,
        bytes32 __anion
    ) external isCationOrController(polyhash) {
        bytes32[] memory _anion = Polycules[polyhash]._anion;
        uint8[] memory _rules = Polycules[polyhash]._rules;
        if (__anion.existsIn(_anion)) {
            uint index = __anion.findIn(_anion);
            Polycules[polyhash]._hooks[_rules[index]] = address(0);
            delete Polycules[polyhash]._anion[index];
            delete Polycules[polyhash]._rules[index];
            emit PopAnion(polyhash, __anion);
        } else {
            revert BAD_ANION();
        }
    }

    /**
     * @dev : set new alias for polycule
     * @param polyhash : hash of polycule
     * @param _alias : bash of alias
     */
    function setAlias(bytes32 polyhash, bytes32 _alias) external isRegistrar {
        Polycules[polyhash]._alias = _alias;
        emit NewAlias(polyhash, _alias);
    }

    /**
     * @dev : switches mutuality flag for an anion
     * @notice : >>> Incompatible <<<
     * @param polyhash : hash of polycule
     * @param _covalence : anion to switch flag for
     */
    function setCovalence(
        bytes32 polyhash,
        bool _covalence
    ) external isAuthorised(polyhash) {
        Polycules[polyhash]._covalence = _covalence;
        emit NewCovalence(polyhash, _covalence);
    }

    /**
     * @dev : set resolver for a polycule
     * @param polyhash : hash of polycule
     * @param _resolver : new resolver
     */
    function setResolver(
        bytes32 polyhash,
        address _resolver
    ) external isAuthorised(polyhash) {
        Polycules[polyhash]._resolver = _resolver;
        emit NewResolver(polyhash, _resolver);
    }

    /**
     * @dev : set expiry for a polycule
     * @param molyhash : hash of polycule
     * @param _expiry : new expiry
     */
    function setExpiry(bytes32 molyhash, uint _expiry) external isRegistrar {
        require(_expiry > Polycules[molyhash]._expiry, "BAD_EXPIRY");
        Polycules[molyhash]._expiry = _expiry;
        emit NewExpiry(molyhash, _expiry);
    }

    /**
     * @dev : set expiry for a polycule
     * @param molyhash : hash of polycule
     * @param _expiry : new expiry
     */
    function renew(
        bytes32 molyhash,
        uint _expiry
    ) external payable isCationOrController(molyhash) {
        require(_expiry > Polycules[molyhash]._expiry, "BAD_EXPIRY");
        Registrar = HELIX2.getRegistrar()[1];
        uint newDuration = _expiry - Polycules[molyhash]._expiry;
        require(msg.value >= newDuration * basePrice, "INSUFFICIENT_ETHER");
        Polycules[molyhash]._expiry = _expiry;
        emit NewExpiry(molyhash, _expiry);
    }

    /**
     * @dev : set record for a polycule
     * @param polyhash : hash of polycule
     * @param _resolver : new record
     */
    function setRecord(
        bytes32 polyhash,
        address _resolver
    ) external isAuthorised(polyhash) {
        Polycules[polyhash]._resolver = _resolver;
        emit NewRecord(polyhash, _resolver);
    }

    /**
     * @dev adds a new hook & rule and anion
     * @param __anion : anion to add hook for
     * @param polyhash : hash of the polycule
     * @param config : address of config contract
     * @param rule : rule for the hook (and anion)
     */
    function hook(
        bytes32 __anion,
        bytes32 polyhash,
        address config,
        uint8 rule
    ) external isCationOrController(polyhash) {
        require(isNotDuplicateAnion(polyhash, __anion), "ANION_EXISTS");
        require(isNotDuplicateHook(polyhash, rule), "HOOK_EXISTS");
        Polycules[polyhash]._rules.push(rule);
        Polycules[polyhash]._hooks[rule] = config;
        Polycules[polyhash]._anion.push(__anion);
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
        require(Polycules[polyhash]._hooks[rule] != config, "RULE_EXISTS");
        Polycules[polyhash]._hooks[rule] = config;
        emit RehookedConfig(polyhash, config, rule);
    }

    /**
     * @dev rehooks a hook (and anion) to a new rule
     * @param polyhash : hash of the polycule
     * @param rule : rule for the new hook (and anion)
     * @param __anion : hash of anion
     */
    function rehook(
        bytes32 polyhash,
        uint8 rule,
        bytes32 __anion
    ) external isCationOrController(polyhash) {
        bytes32[] memory _anion = Polycules[polyhash]._anion;
        if (__anion.existsIn(_anion)) {
            uint index = __anion.findIn(_anion);
            require(
                Polycules[polyhash]._rules[index] != rule,
                "RULE_EXISTS"
            );
            Polycules[polyhash]._rules[index] = rule;
            emit RehookedAnion(polyhash, __anion, rule);
        } else {
            revert BAD_ANION();
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
        uint8[] memory _rules = Polycules[polyhash]._rules;
        if (rule.existsIn(_rules)) {
            uint index = rule.findIn(_rules);
            Polycules[polyhash]._hooks[rule] = address(0);
            emit UnhookedConfig(polyhash, rule);
            delete Polycules[polyhash]._rules[index];
            delete Polycules[polyhash]._anion[index];
        } else {
            revert BAD_HOOK();
        }
    }

    /**
     * @dev removes a hook in a polycule
     * @param polyhash : hash of the polycule
     * @param __anion : __anion to unhook
     */
    function unhook(
        bytes32 polyhash,
        bytes32 __anion
    ) external isCationOrController(polyhash) {
        uint8[] memory _rules = Polycules[polyhash]._rules;
        bytes32[] memory _anion = Polycules[polyhash]._anion;
        if (__anion.existsIn(_anion)) {
            uint index = __anion.findIn(_anion);
            Polycules[polyhash]._hooks[_rules[index]] = address(0);
            emit UnhookedAnion(polyhash, __anion);
            delete Polycules[polyhash]._rules[index];
            delete Polycules[polyhash]._anion[index];
        } else {
            emit UnhookedAnion(polyhash, bytes32(0));
        }
    }

    /**
     * @dev removes all hooks (and anions) in a polycule
     * @param polyhash : hash of the polycule
     */
    function unhookAll(
        bytes32 polyhash
    ) external isCationOrController(polyhash) {
        uint8[] memory _rules = Polycules[polyhash]._rules;
        for (uint i = 0; i < _rules.length; i++) {
            Polycules[polyhash]._hooks[_rules[i]] = address(0);
            emit UnhookedConfig(polyhash, _rules[i]);
        }
        delete Polycules[polyhash]._rules;
        delete Polycules[polyhash]._anion;
        emit UnhookedAll(polyhash);
    }

    /**
     * @dev : set operator for a polycule
     * @param operator : new operator
     * @param approved : state to set
     */
    function setApprovalForAll(address operator, bool approved) external {
        Operators[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev return cation of a polycule
     * @param polyhash : hash of polycule to query
     * @return hash of cation
     */
    function cation(
        bytes32 polyhash
    ) public view isOwned(polyhash) returns (bytes32) {
        bytes32 __cation = Polycules[polyhash]._cation;
        address _cation = NAMES.owner(__cation);
        if (_cation == address(this)) {
            return roothash;
        }
        return __cation;
    }

    /**
     * @dev return controller of a polycule
     * @param polyhash : hash of polycule to query
     * @return address of controller
     */
    function controller(
        bytes32 polyhash
    ) public view isOwned(polyhash) returns (address) {
        address _controller = Polycules[polyhash]._controller;
        return _controller;
    }

    /**
     * @dev shows mutuality state of a polycule
     * @param polyhash : hash of polycule to query
     * @return mutuality state of the polycule
     */
    function covalence(
        bytes32 polyhash
    ) public view isOwned(polyhash) returns (bool) {
        bool _covalence = Polycules[polyhash]._covalence;
        return _covalence;
    }

    /**
     * @dev shows alias of a polycule
     * @param polyhash : hash of polycule to query
     * @return alias of the polycule
     */
    function alias_(
        bytes32 polyhash
    ) public view isOwned(polyhash) returns (bytes32) {
        bytes32 _alias = Polycules[polyhash]._alias;
        return _alias;
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
        isOwned(polyhash)
        returns (uint8[] memory _rules, address[] memory _hooks)
    {
        _rules = Polycules[polyhash]._rules;
        _hooks = new address[](_rules.length);
        for (uint i = 0; i < _rules.length; i++) {
            _hooks[i] = Polycules[polyhash]._hooks[_rules[i]];
        }
    }

    /**
     * @dev return anions of a polycule
     * @param polyhash : hash of polycule to query
     * @return array of anions
     */
    function anion(
        bytes32 polyhash
    ) public view isOwned(polyhash) returns (bytes32[] memory) {
        bytes32[] memory _anion = Polycules[polyhash]._anion;
        return _anion;
    }

    /**
     * @dev return expiry of a polycule
     * @param polyhash : hash of polycule to query
     * @return expiry
     */
    function expiry(bytes32 polyhash) public view returns (uint) {
        uint _expiry = Polycules[polyhash]._expiry;
        return _expiry;
    }

    /**
     * @dev return resolver of a polycule
     * @param polyhash : hash of polycule to query
     * @return address of resolver
     */
    function resolver(
        bytes32 polyhash
    ) public view isOwned(polyhash) returns (address) {
        address _resolver = Polycules[polyhash]._resolver;
        return _resolver;
    }

    /**
     * @dev check if a polycule is registered
     * @param polyhash : hash of polycule to query
     * @return true or false
     */
    function recordExists(bytes32 polyhash) public view returns (bool) {
        return block.timestamp < Polycules[polyhash]._expiry;
    }

    /**
     * @dev check if an address is set as operator
     * @param _cation cation of polycule to query
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
     * @dev : withdraw ether to Dev, anyone can trigger
     */
    function withdrawEther() external {
        (bool ok, ) = Dev.call{value: address(this).balance}("");
        require(ok, "ETH_TRANSFER_FAILED");
    }
}
