//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Interface/iERC173.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @notice GitHub: https://github.com/helix-coupler/helix2-contracts
 * @notice README: https://github.com/helix-coupler/resources
 * @dev testnet v0.0.1
 * @title Helix2 Bond Storage
 */
contract Helix2BondStorage {
    /// @dev : Helix2 Bond events
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

    /// @dev : Helix2 Bond struct
    struct Bond {
        uint8[] _rules; /// Rules
        mapping(uint8 => address) _hooks; /// Rules → Hooks
        bytes32 _cation; /// Source of Bond (= Owner)
        bytes32 _anion; /// Target of Bond
        bytes32 _label; /// Hash of Bond
        address _resolver; /// Resolver of Bond
        address _controller; /// Controller of Bond
        bool _covalence; /// Mutuality Flag
        uint _expiry; /// Expiry of Bond
    }
    mapping(bytes32 => Bond) public Bonds;

    /**
     * @dev Initialise a new HELIX2 Polycules Registry
     * @notice
     * @param _registry : address of HELIX2 Name Registry
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
     * @param _registry : address of new HELIX2 Bonds Registry
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
     * @dev set cation of a bond
     * @param bondhash : hash of bond
     * @param _cation : new cation
     */
    function setCation(
        bytes32 bondhash,
        bytes32 _cation
    ) external onlyRegistry {
        Bonds[bondhash]._cation = _cation;
    }

    /**
     * @dev set controller of a bond
     * @param bondhash : hash of bond
     * @param _controller : new controller
     */
    function setController(
        bytes32 bondhash,
        address _controller
    ) external onlyRegistry {
        Bonds[bondhash]._controller = _controller;
    }

    /**
     * @dev set new anion of a bond
     * @param bondhash : hash of anion
     * @param _anion : address of anion
     */
    function setAnion(bytes32 bondhash, bytes32 _anion) external onlyRegistry {
        Bonds[bondhash]._anion = _anion;
    }

    /**
     * @dev set new label for bond
     * @param bondhash : hash of bond
     * @param _label : bash of label
     */
    function setLabel(bytes32 bondhash, bytes32 _label) external onlyRegistry {
        Bonds[bondhash]._label = _label;
    }

    /**
     * @dev set new mutuality flag for bond
     * @param bondhash : hash of bond
     * @param _covalence : bool
     */
    function setCovalence(
        bytes32 bondhash,
        bool _covalence
    ) external onlyRegistry {
        Bonds[bondhash]._covalence = _covalence;
    }

    /**
     * @dev set resolver for a bond
     * @param bondhash : hash of bond
     * @param _resolver : new resolver
     */
    function setResolver(
        bytes32 bondhash,
        address _resolver
    ) external onlyRegistry {
        Bonds[bondhash]._resolver = _resolver;
    }

    /**
     * @dev set expiry for a bond
     * @param bondhash : hash of bond
     * @param _expiry : new expiry
     */
    function setExpiry(bytes32 bondhash, uint _expiry) external onlyRegistry {
        require(_expiry > Bonds[bondhash]._expiry, "BAD_EXPIRY");
        Bonds[bondhash]._expiry = _expiry;
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
    ) external onlyRegistry {
        Bonds[bondhash]._rules.push(rule);
        Bonds[bondhash]._hooks[rule] = config;
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
    ) external onlyRegistry {
        Bonds[bondhash]._hooks[rule] = config;
    }

    /**
     * @dev removes a hook in a bond
     * @param bondhash : hash of the bond
     * @param rule : rule to unhook
     * @param index : index to unhook
     */
    function unhook(
        bytes32 bondhash,
        uint8 rule,
        uint index
    ) external onlyRegistry {
        Bonds[bondhash]._hooks[rule] = address(0);
        delete Bonds[bondhash]._rules[index];
    }

    /**
     * @dev removes all hooks in a bond
     * @param bondhash : hash of the bond
     */
    function unhookAll(bytes32 bondhash) external onlyRegistry {
        for (uint i = 0; i < Bonds[bondhash]._rules.length; i++) {
            Bonds[bondhash]._hooks[Bonds[bondhash]._rules[i]] = address(0);
        }
        delete Bonds[bondhash]._rules;
    }

    /**
     * @dev return cation of a bond
     * @param bondhash : hash of bond to query
     * @return hash of cation
     */
    function cation(bytes32 bondhash) public view returns (bytes32) {
        return Bonds[bondhash]._cation;
    }

    /**
     * @dev return controller of a bond
     * @param bondhash : hash of bond to query
     * @return address of controller
     */
    function controller(bytes32 bondhash) public view returns (address) {
        return Bonds[bondhash]._controller;
    }

    /**
     * @dev shows mutuality state of a bond
     * @param bondhash : hash of bond to query
     * @return mutuality state of the bond
     */
    function covalence(bytes32 bondhash) public view returns (bool) {
        return Bonds[bondhash]._covalence;
    }

    /**
     * @dev shows label of a bond
     * @param bondhash : hash of bond to query
     * @return label of the bond
     */
    function label(bytes32 bondhash) public view returns (bytes32) {
        return Bonds[bondhash]._label;
    }

    /**
     * @dev return hooks of a bond
     * @param bondhash : hash of bond to query
     * @return _rules
     * @return _hooks
     */
    function hooksWithRules(
        bytes32 bondhash
    ) public view returns (uint8[] memory _rules, address[] memory _hooks) {
        _rules = Bonds[bondhash]._rules;
        _hooks = new address[](_rules.length);
        for (uint i = 0; i < _rules.length; i++) {
            _hooks[i] = Bonds[bondhash]._hooks[_rules[i]];
        }
    }

    /**
     * @dev return anion of a bond
     * @param bondhash : hash of bond to query
     * @return hash of anion
     */
    function anion(bytes32 bondhash) public view returns (bytes32) {
        return Bonds[bondhash]._anion;
    }

    /**
     * @dev return expiry of a bond
     * @param bondhash : hash of bond to query
     * @return expiry
     */
    function expiry(bytes32 bondhash) public view returns (uint) {
        return Bonds[bondhash]._expiry;
    }

    /**
     * @dev return resolver of a bond
     * @param bondhash : hash of bond to query
     * @return address of resolver
     */
    function resolver(bytes32 bondhash) public view returns (address) {
        return Bonds[bondhash]._resolver;
    }

    /**
     * @dev check if a bond is registered
     * @param bondhash : hash of bond to query
     * @return true or false
     */
    function recordExists(bytes32 bondhash) public view returns (bool) {
        return block.timestamp < Bonds[bondhash]._expiry;
    }
}
