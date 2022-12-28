//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Names/iName.sol";
import "src/Molecules/iMolecule.sol";
import "src/Interface/iHelix2.sol";
import "src/Utils/LibString.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Molecule Base
 */
contract Helix2MoleculeRegistry {
    using LibString for bytes32[];
    using LibString for bytes32;
    using LibString for address[];
    using LibString for address;
    using LibString for string[];
    using LibString for string;

    /// Interfaces
    iHELIX2 public HELIX2;
    iNAME public NAMES;

    /// @dev : Helix2 Molecule events
    event NewDev(address Dev, address newDev);
    event NewMolecule(bytes32 indexed molyhash, bytes32 cation);
    event Hooked(bytes32 indexed molyhash, address config, uint8 rule);
    event Rehooked(bytes32 indexed molyhash, address config, uint8 rule);
    event Unhooked(bytes32 indexed molyhash, address config);
    event UnhookedAll(bytes32 indexed molyhash);
    event NewCation(bytes32 indexed molyhash, bytes32 cation);
    event NewRegistration(bytes32 indexed molyhash, bytes32 cation);
    event NewAnion(bytes32 indexed molyhash, bytes32 anion);
    event NewAnions(bytes32 indexed molyhash, bytes32[] anion);
    event PopAnion(bytes32 indexed molyhash, bytes32 anion);
    event NewAlias(bytes32 indexed molyhash, bytes32 _alias);
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

    error AnionNotFound(bytes32 moleculehash, bytes32 anion);

    /// Dev
    address public Dev;

    /// @dev : Pause/Resume contract
    bool public active = true;

    /// @dev : Molecule roothash
    bytes32 public roothash;
    uint256 public basePrice;
    address public Registrar;
    uint256 public theEnd = 250_000_000_000_000_000; // roughly 80,000,000,000 years in the future

    /// @dev : Helix2 MOLECULE struct
    struct Molecule {
        address[] _hooks; /// Hooks
        mapping(address => uint8) _rules; /// Rules for Hooks
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
     * @dev : sets permissions for 0x0 and roothash
     * @notice : consider changing msg.sender → address(this)
     */
    function catalyse() internal {
        // 0x0
        Molecules[0x0]._rules[address(0x0)] = uint8(0);
        Molecules[0x0]._hooks = [address(0x0)];
        Molecules[0x0]._cation = bytes32(0x0);
        Molecules[0x0]._anion = [bytes32(0x0)];
        Molecules[0x0]._alias = bytes32(0x0);
        Molecules[0x0]._covalence = true;
        Molecules[0x0]._expiry = theEnd;
        Molecules[0x0]._controller = msg.sender;
        Molecules[0x0]._resolver = msg.sender;
        // root
        bytes32[4] memory hashes = HELIX2.getRoothash();
        for (uint i = 0; i < hashes.length; i++) {
            Molecules[hashes[i]]._rules[address(0x0)] = uint8(0);
            Molecules[hashes[i]]._hooks = [address(0x0)];
            Molecules[hashes[i]]._cation = hashes[i];
            Molecules[hashes[i]]._anion = [hashes[i]];
            Molecules[hashes[i]]._alias = hashes[i];
            Molecules[hashes[i]]._covalence = true;
            Molecules[hashes[i]]._expiry = theEnd;
            Molecules[hashes[i]]._controller = msg.sender;
            Molecules[hashes[i]]._resolver = msg.sender;
        }
    }

    /**
     * @dev Initialise a new HELIX2 Molecules Registry
     * @notice : constructor notes
     * @param _helix2 : address of HELIX2 Manager
     * @param _registry : address of HELIX2 Name Registry
     */
    constructor(address _registry, address _helix2) {
        Dev = msg.sender;
        HELIX2 = iHELIX2(_helix2);
        NAMES = iNAME(_registry);
        roothash = HELIX2.getRoothash()[2];
        basePrice = HELIX2.getPrices()[2];
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
    modifier onlyController(bytes32 molyhash) {
        require(
            block.timestamp < Molecules[molyhash]._expiry,
            "MOLECULE_EXPIRED"
        ); // expiry check
        require(
            msg.sender == Molecules[molyhash]._controller,
            "NOT_CONTROLLER"
        );
        _;
    }

    /// @dev : Modifier to allow Registrar
    modifier isRegistrar() {
        Registrar = HELIX2.getRegistrar()[2];
        require(msg.sender == Registrar, "NOT_REGISTRAR");
        _;
    }

    /// @dev : Modifier to allow Owner, Controller or Registrar
    modifier isAuthorised(bytes32 molyhash) {
        Registrar = HELIX2.getRegistrar()[2];
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
     * @dev : check if molecule is available
     * @param molyhash : hash of molecule
     */
    modifier isAvailable(bytes32 molyhash) {
        require(
            block.timestamp >= Molecules[molyhash]._expiry,
            "MOLECULE_EXISTS"
        ); // expiry check
        _;
    }

    /**
     * @dev : verify molecule is not expired
     * @param molyhash : hash of molecule
     */
    modifier isOwned(bytes32 molyhash) {
        require(
            block.timestamp < Molecules[molyhash]._expiry,
            "MOLECULE_EXPIRED"
        ); // expiry check
        _;
    }

    /**
     * @dev : check if new config is a duplicate
     * @param molyhash : hash of molecule
     * @param config : config to check
     */
    function isNotDuplicateHook(
        bytes32 molyhash,
        address config
    ) public view returns (bool) {
        return !config.existsIn(Molecules[molyhash]._hooks);
    }

    /**
     * @dev : check if new anion is a duplicate
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
     * @dev : verify ownership of molecule
     * @param molyhash : hash of molecule
     */
    modifier onlyCation(bytes32 molyhash) {
        require(
            block.timestamp < Molecules[molyhash]._expiry,
            "MOLECULE_EXPIRED"
        ); // expiry check
        bytes32 __cation = Molecules[molyhash]._cation;
        address _cation = NAMES.owner(__cation);
        require(
            _cation == msg.sender || Operators[_cation][msg.sender],
            "NOT_OWNER"
        );
        _;
    }

    /**
     * @dev : register owner of new molecule
     * @param molyhash : hash of molecule
     * @param _cation : new cation
     */
    function register(
        bytes32 molyhash,
        bytes32 _cation
    ) external isAvailable(molyhash) {
        Molecules[molyhash]._cation = _cation;
        emit NewRegistration(molyhash, _cation);
    }

    /**
     * @dev : set cation of a molecule
     * @param molyhash : hash of molecule
     * @param _cation : new cation
     */
    function setCation(
        bytes32 molyhash,
        bytes32 _cation
    ) external onlyCation(molyhash) {
        Molecules[molyhash]._cation = _cation;
        emit NewCation(molyhash, _cation);
    }

    /**
     * @dev : set controller of a molecule
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
     * @dev : adds one anion to the molecule
     * @param molyhash : hash of target molecule
     * @param _anion : hash of new anion
     */
    function addAnion(
        bytes32 molyhash,
        bytes32 _anion
    ) external isAuthorised(molyhash) {
        require(isNotDuplicateAnion(molyhash, _anion), "ANION_EXISTS");
        Molecules[molyhash]._anion.push(_anion);
        emit NewAnion(molyhash, _anion);
    }

    /**
     * @dev : adds new array of anions to the molecule
     * @notice : will overwrite pre-existing anions
     * @param molyhash : hash of target molecule
     * @param _anion : array of new anions
     */
    function setAnions(
        bytes32 molyhash,
        bytes32[] memory _anion
    ) external isAuthorised(molyhash) {
        for (uint i = 0; i < _anion.length; i++) {
            if (_anion[i].existsIn(Molecules[molyhash]._anion)) {
                Molecules[molyhash]._anion.push(_anion[i]);
            }
        }
        emit NewAnions(molyhash, _anion);
    }

    /**
     * @dev : pops an anion from the molecule
     * @param molyhash : hash of target molecule
     * @param __anion : hash of anion to remove
     */
    function popAnion(
        bytes32 molyhash,
        bytes32 __anion
    ) external isAuthorised(molyhash) {
        bytes32[] memory _anion = Molecules[molyhash]._anion;
        if (__anion.existsIn(_anion)) {
            uint index = __anion.findIn(_anion);
            delete Molecules[molyhash]._anion[index];
            emit PopAnion(molyhash, __anion);
        } else {
            revert AnionNotFound(molyhash, __anion);
        }
    }

    /**
     * @dev : set new alias for molecule
     * @param molyhash : hash of molecule
     * @param _alias : bash of alias
     */
    function setAlias(
        bytes32 molyhash,
        bytes32 _alias
    ) external isAuthorised(molyhash) {
        Molecules[molyhash]._alias = _alias;
        emit NewAlias(molyhash, _alias);
    }

    /**
     * @dev : set new mutuality flag for molecule
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
     * @dev : set resolver for a molecule
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
     * @dev : set expiry for a molecule
     * @param molyhash : hash of molecule
     * @param _expiry : new expiry
     */
    function setExpiry(
        bytes32 molyhash,
        uint _expiry
    ) external payable isAuthorised(molyhash) {
        require(_expiry > Molecules[molyhash]._expiry, "BAD_EXPIRY");
        Registrar = HELIX2.getRegistrar()[2];
        if (msg.sender != Registrar) {
            uint newDuration = _expiry - Molecules[molyhash]._expiry;
            require(msg.value >= newDuration * basePrice, "INSUFFICIENT_ETHER");
        }
        Molecules[molyhash]._expiry = _expiry;
        emit NewExpiry(molyhash, _expiry);
    }

    /**
     * @dev : set record for a molecule
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
        uint8 rule,
        address config
    ) external onlyCation(molyhash) {
        require(isNotDuplicateHook(molyhash, config), "HOOK_EXISTS");
        Molecules[molyhash]._hooks.push(config);
        Molecules[molyhash]._rules[config] = rule;
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
        uint8 rule,
        address config
    ) external onlyCation(molyhash) {
        require(Molecules[molyhash]._rules[config] != rule, "RULE_EXISTS");
        Molecules[molyhash]._rules[config] = rule;
        emit Rehooked(molyhash, config, rule);
    }

    /**
     * @dev removes a hook in a molecule
     * @param molyhash : hash of the molecule
     * @param config : contract address of config
     */
    function unhook(
        bytes32 molyhash,
        address config
    ) external onlyCation(molyhash) {
        address[] memory _hooks = Molecules[molyhash]._hooks;
        if (config.existsIn(_hooks)) {
            uint index = config.findIn(_hooks);
            if (index == uint(0)) {
                emit Unhooked(molyhash, address(0));
            } else {
                Molecules[molyhash]._rules[config] = uint8(0);
                emit Unhooked(molyhash, config);
                delete Molecules[molyhash]._hooks[index];
            }
        } else {
            emit Unhooked(molyhash, address(0));
        }
    }

    /**
     * @dev removes all hooks in a molecule
     * @param molyhash : hash of the molecule
     */
    function unhookAll(bytes32 molyhash) external onlyCation(molyhash) {
        address[] memory _hooks = Molecules[molyhash]._hooks;
        for (uint i = 0; i < _hooks.length; i++) {
            Molecules[molyhash]._rules[_hooks[i]] = uint8(0);
            emit Unhooked(molyhash, _hooks[i]);
        }
        delete Molecules[molyhash]._hooks;
        emit UnhookedAll(molyhash);
        Molecules[molyhash]._hooks.push(address(0));
    }

    /**
     * @dev : set operator for a molecule
     * @param operator : new operator
     * @param approved : state to set
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
     * @return tuple of (hooks, rules)
     */
    function hooksWithRules(
        bytes32 molyhash
    ) public view isOwned(molyhash) returns (address[] memory, uint8[] memory) {
        address[] memory _hooks = Molecules[molyhash]._hooks;
        uint8[] memory _rules = new uint8[](_hooks.length);
        for (uint i = 0; i < _hooks.length; i++) {
            _rules[i] = Molecules[molyhash]._rules[_hooks[i]];
        }
        return (_hooks, _rules);
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
     * @dev : withdraw ether to Dev, anyone can trigger
     */
    function withdrawEther() external {
        (bool ok, ) = Dev.call{value: address(this).balance}("");
        require(ok, "ETH_TRANSFER_FAILED");
    }
}
