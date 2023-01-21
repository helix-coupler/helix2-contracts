//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Interface/iERC173.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @notice GitHub: https://github.com/helix-coupler/helix2-contracts
 * @notice README: https://github.com/helix-coupler/resources
 * @dev testnet v0.0.1
 * @title Helix2 Polycule Storage
 */
contract Helix2PolyculeStorage {
    /// @dev : Helix2 Polycule events
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

    /// @dev : Helix2 POLYCULE struct
    struct Polycule {
        uint256[] _rules; /// Rules
        mapping(uint256 => address) _hooks; /// Rules → Hooks
        bytes32 _cation; /// Source of Polycule (= Owner)
        bytes32[] _anions; /// Targets of Polycule
        bytes32 _label; /// Hash of Polycule
        address _resolver; /// Resolver of Polycule
        address _controller; /// Controller of Polycule
        bool _covalence; /// Mutuality Flags
        uint _expiry; /// Expiry of Polycule
    }
    mapping(bytes32 => Polycule) public Polycules;

    /**
     * @dev Initialise a new HELIX2 Polycules Storage
     * @notice
     * @param _registry : address of HELIX2 Polycules Registry
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
     * @param _registry : address of new HELIX2 Polycule Registry
     */
    function setConfig(address _registry) external onlyDev {
        Registry = _registry;
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
     * @dev set cation of a polycule
     * @param polyhash : hash of polycule
     * @param _cation : new cation
     */
    function setCation(
        bytes32 polyhash,
        bytes32 _cation
    ) external onlyRegistry {
        Polycules[polyhash]._cation = _cation;
    }

    /**
     * @dev set controller of a polycule
     * @param polyhash : hash of polycule
     * @param _controller : new controller
     */
    function setController(
        bytes32 polyhash,
        address _controller
    ) external onlyRegistry {
        Polycules[polyhash]._controller = _controller;
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
        uint256 rule
    ) external onlyRegistry {
        Polycules[polyhash]._anions.push(_anion);
        Polycules[polyhash]._rules.push(rule);
        Polycules[polyhash]._hooks[rule] == config;
    }

    /**
     * @dev pops an anion from the polycule
     * @param polyhash : hash of polycule
     * @param index : index to pop
     */
    function popAnion(bytes32 polyhash, uint index) external onlyRegistry {
        Polycules[polyhash]._hooks[Polycules[polyhash]._rules[index]] = address(
            0
        );
        delete Polycules[polyhash]._anions[index];
        delete Polycules[polyhash]._rules[index];
    }

    /**
     * @dev set new label for polycule
     * @param polyhash : hash of polycule
     * @param _label : bash of label
     */
    function setLabel(bytes32 polyhash, bytes32 _label) external onlyRegistry {
        Polycules[polyhash]._label = _label;
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
    ) external onlyRegistry {
        Polycules[polyhash]._covalence = _covalence;
    }

    /**
     * @dev set resolver for a polycule
     * @param polyhash : hash of polycule
     * @param _resolver : new resolver
     */
    function setResolver(
        bytes32 polyhash,
        address _resolver
    ) external onlyRegistry {
        Polycules[polyhash]._resolver = _resolver;
    }

    /**
     * @dev set expiry for a polycule
     * @param polyhash : hash of polycule
     * @param _expiry : new expiry
     */
    function setExpiry(bytes32 polyhash, uint _expiry) external onlyRegistry {
        Polycules[polyhash]._expiry = _expiry;
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
        uint256 rule
    ) external onlyRegistry {
        Polycules[polyhash]._rules.push(rule);
        Polycules[polyhash]._hooks[rule] = config;
        Polycules[polyhash]._anions.push(_anion);
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
        uint256 rule
    ) external onlyRegistry {
        Polycules[polyhash]._hooks[rule] = config;
    }

    /**
     * @dev removes a hook in a polycule
     * @param polyhash : hash of the polycule
     * @param rule : rule to unhook
     * @param index : index to unhook
     */
    function unhook(
        bytes32 polyhash,
        uint256 rule,
        uint index
    ) external onlyRegistry {
        Polycules[polyhash]._hooks[rule] = address(0);
        delete Polycules[polyhash]._rules[index];
        delete Polycules[polyhash]._anions[index];
    }

    /**
     * @dev removes all hooks (and anions) in a polycule
     * @param polyhash : hash of the polycule
     */
    function unhookAll(bytes32 polyhash) external onlyRegistry {
        for (uint i = 0; i < Polycules[polyhash]._rules.length; i++) {
            Polycules[polyhash]._hooks[Polycules[polyhash]._rules[i]] = address(
                0
            );
        }
        delete Polycules[polyhash]._rules;
        delete Polycules[polyhash]._anions;
    }

    /**
     * @dev return cation of a polycule
     * @param polyhash : hash of polycule to query
     * @return hash of cation
     */
    function cation(bytes32 polyhash) public view returns (bytes32) {
        return Polycules[polyhash]._cation;
    }

    /**
     * @dev return controller of a polycule
     * @param polyhash : hash of polycule to query
     * @return address of controller
     */
    function controller(bytes32 polyhash) public view returns (address) {
        return Polycules[polyhash]._controller;
    }

    /**
     * @dev shows mutuality state of a polycule
     * @param polyhash : hash of polycule to query
     * @return mutuality state of the polycule
     */
    function covalence(bytes32 polyhash) public view returns (bool) {
        return Polycules[polyhash]._covalence;
    }

    /**
     * @dev shows label of a polycule
     * @param polyhash : hash of polycule to query
     * @return label of the polycule
     */
    function label(bytes32 polyhash) public view returns (bytes32) {
        return Polycules[polyhash]._label;
    }

    /**
     * @dev return hooks & rules of a polycule
     * @param polyhash : hash of polycule to query
     * @return _rules
     * @return _hooks
     */
    function hooksWithRules(
        bytes32 polyhash
    ) public view returns (uint256[] memory _rules, address[] memory _hooks) {
        _rules = Polycules[polyhash]._rules;
        _hooks = new address[](_rules.length);
        for (uint i = 0; i < _rules.length; i++) {
            _hooks[i] = Polycules[polyhash]._hooks[
                Polycules[polyhash]._rules[i]
            ];
        }
    }

    /**
     * @dev return anions of a polycule
     * @param polyhash : hash of polycule to query
     * @return array of anions
     */
    function anions(bytes32 polyhash) public view returns (bytes32[] memory) {
        return Polycules[polyhash]._anions;
    }

    /**
     * @dev return expiry of a polycule
     * @param polyhash : hash of polycule to query
     * @return expiry
     */
    function expiry(bytes32 polyhash) public view returns (uint) {
        return Polycules[polyhash]._expiry;
    }

    /**
     * @dev return resolver of a polycule
     * @param polyhash : hash of polycule to query
     * @return address of resolver
     */
    function resolver(bytes32 polyhash) public view returns (address) {
        return Polycules[polyhash]._resolver;
    }

    /**
     * @dev check if a polycule is registered
     * @param polyhash : hash of polycule to query
     * @return true or false
     */
    function recordExists(bytes32 polyhash) public view returns (bool) {
        return block.timestamp < Polycules[polyhash]._expiry;
    }
}
