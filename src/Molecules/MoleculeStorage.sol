//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Interface/iERC173.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @notice GitHub: https://github.com/helix-coupler/helix2-contracts
 * @notice README: https://github.com/helix-coupler/resources
 * @dev testnet v0.0.1
 * @title Helix2 Molecule Storage
 */
contract Helix2MoleculeStorage {
    /// @dev : Helix2 Name events
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// Dev
    address public Dev;
    /// Registry
    address public Registry;

    /// @dev : Pause/Resume contract
    bool public active = true;

    /// @dev : Helix2 MOLECULE struct
    struct Molecule {
        uint8[] _rules; /// Rules
        mapping(uint8 => address) _hooks; /// Rules → Hooks
        bytes32 _cation; /// Source of Molecule (= Owner)
        bytes32[] _anions; /// Targets of Molecule
        bytes32 _label; /// Hash of Molecule
        address _resolver; /// Resolver of Molecule
        address _controller; /// Controller of Molecule
        bool _covalence; /// Mutuality Flag
        uint _expiry; /// Expiry of Molecule
    }
    mapping(bytes32 => Molecule) public Molecules;

    /**
     * @dev Initialise a new HELIX2 Names Storage
     * @notice
     * @param _registry : address of HELIX2 Names Registry
     */
    constructor(address _registry) {
        Registry = _registry;
        Dev = msg.sender;
    }

    /// @dev : Modifier to allow only dev
    modifier onlyDev() {
        require(msg.sender == Dev, "NOT_DEV");
        _;
    }

    /// @dev : Modifier to allow only parent registry
    modifier onlyRegistry() {
        require(msg.sender == Registry, "NOT_ALLOWED");
        _;
    }

    /**
     * @dev pauses or resumes contract
     */
    function toggleActive() external onlyDev {
        active = !active;
    }

    /**
     * @dev sets config
     * @notice
     * @param _registry : address of new HELIX2 Name Registry
     */
    function setConfig(address _registry) external onlyDev {
        Registry = _registry;
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
     * @dev set cation of a molecule
     * @param molyhash : hash of molecule
     * @param _cation : new cation
     */
    function setCation(
        bytes32 molyhash,
        bytes32 _cation
    ) external onlyRegistry {
        Molecules[molyhash]._cation = _cation;
    }

    /**
     * @dev set controller of a molecule
     * @param molyhash : hash of molecule
     * @param _controller : new controller
     */
    function setController(
        bytes32 molyhash,
        address _controller
    ) external onlyRegistry {
        Molecules[molyhash]._controller = _controller;
    }

    /**
     * @dev adds one anion to the molecule
     * @param molyhash : hash of target molecule
     * @param _anion : hash of new anion
     */
    function addAnion(bytes32 molyhash, bytes32 _anion) external onlyRegistry {
        Molecules[molyhash]._anions.push(_anion);
    }

    /**
     * @dev pops an anion from the molecule
     * @param molyhash : hash of target molecule
     * @param index : index to pop
     */
    function popAnion(bytes32 molyhash, uint index) external onlyRegistry {
        delete Molecules[molyhash]._anions[index];
    }

    /**
     * @dev set new label for molecule
     * @param molyhash : hash of molecule
     * @param _label : bash of label
     */
    function setLabel(bytes32 molyhash, bytes32 _label) external onlyRegistry {
        Molecules[molyhash]._label = _label;
    }

    /**
     * @dev set new mutuality flag for molecule
     * @param molyhash : hash of molecule
     * @param _covalence : bool
     */
    function setCovalence(
        bytes32 molyhash,
        bool _covalence
    ) external onlyRegistry {
        Molecules[molyhash]._covalence = _covalence;
    }

    /**
     * @dev set resolver for a molecule
     * @param molyhash : hash of molecule
     * @param _resolver : new resolver
     */
    function setResolver(
        bytes32 molyhash,
        address _resolver
    ) external onlyRegistry {
        Molecules[molyhash]._resolver = _resolver;
    }

    /**
     * @dev set expiry for a molecule
     * @param molyhash : hash of molecule
     * @param _expiry : new expiry
     */
    function setExpiry(bytes32 molyhash, uint _expiry) external onlyRegistry {
        require(_expiry > Molecules[molyhash]._expiry, "BAD_EXPIRY");
        Molecules[molyhash]._expiry = _expiry;
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
    ) external onlyRegistry {
        Molecules[molyhash]._rules.push(rule);
        Molecules[molyhash]._hooks[rule] = config;
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
    ) external onlyRegistry {
        Molecules[molyhash]._hooks[rule] = config;
    }

    /**
     * @dev removes a hook in a molecule
     * @param molyhash : hash of the molecule
     * @param rule : rule to unhook
     * @param index : index to unhook
     */
    function unhook(
        bytes32 molyhash,
        uint8 rule,
        uint index
    ) external onlyRegistry {
        Molecules[molyhash]._hooks[rule] = address(0);
        delete Molecules[molyhash]._rules[index];
    }

    /**
     * @dev removes all hooks in a molecule
     * @param molyhash : hash of the molecule
     */
    function unhookAll(bytes32 molyhash) external onlyRegistry {
        for (uint i = 0; i < Molecules[molyhash]._rules.length; i++) {
            Molecules[molyhash]._hooks[Molecules[molyhash]._rules[i]] = address(
                0
            );
        }
        delete Molecules[molyhash]._rules;
    }

    /**
     * @dev return cation of a molecule
     * @param molyhash : hash of molecule to query
     * @return hash of cation
     */
    function cation(bytes32 molyhash) public view returns (bytes32) {
        return Molecules[molyhash]._cation;
    }

    /**
     * @dev return controller of a molecule
     * @param molyhash : hash of molecule to query
     * @return address of controller
     */
    function controller(bytes32 molyhash) public view returns (address) {
        return Molecules[molyhash]._controller;
    }

    /**
     * @dev shows mutuality state of a molecule
     * @param molyhash : hash of molecule to query
     * @return mutuality state of the molecule
     */
    function covalence(bytes32 molyhash) public view returns (bool) {
        return Molecules[molyhash]._covalence;
    }

    /**
     * @dev shows label of a molecule
     * @param molyhash : hash of molecule to query
     * @return label of the molecule
     */
    function label(bytes32 molyhash) public view returns (bytes32) {
        return Molecules[molyhash]._label;
    }

    /**
     * @dev return hooks of a molecule
     * @param molyhash : hash of molecule to query
     * @return _rules
     * @return _hooks
     */
    function hooksWithRules(
        bytes32 molyhash
    ) public view returns (uint8[] memory _rules, address[] memory _hooks) {
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
    function anions(bytes32 molyhash) public view returns (bytes32[] memory) {
        return Molecules[molyhash]._anions;
    }

    /**
     * @dev return expiry of a molecule
     * @param molyhash : hash of molecule to query
     * @return expiry
     */
    function expiry(bytes32 molyhash) public view returns (uint) {
        return Molecules[molyhash]._expiry;
    }

    /**
     * @dev return resolver of a molecule
     * @param molyhash : hash of molecule to query
     * @return address of resolver
     */
    function resolver(bytes32 molyhash) public view returns (address) {
        return Molecules[molyhash]._resolver;
    }
}
