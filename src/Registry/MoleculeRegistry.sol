//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Interface/iMolecule.sol";
import "src/Interface/iName.sol";
import "src/Interface/iHelix2.sol";
import "src/Interface/iERC721.sol";
import "src/Utils/LibString.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Molecule Base
 */
abstract contract Helix2Molecules {
    using LibString for bytes32[];
    using LibString for bytes32;
    using LibString for address[];
    using LibString for address;
    using LibString for string[];
    using LibString for string;

    iHELIX2 public HELIX2 = iHELIX2(address(0x0));
    iNAME public NAMES = iNAME(HELIX2.getRegistry()[2]);

    /// @dev : Helix2 Molecule events
    event NewDev(address Dev, address newDev);
    event NewMolecule(bytes32 indexed moleculehash, bytes32 cation);
    event Hooked(bytes32 indexed moleculehash, address config, uint8 rule);
    event Rehooked(bytes32 indexed moleculehash, address config, uint8 rule);
    event Unhooked(bytes32 indexed moleculehash, address config);
    event UnhookedAll(bytes32 indexed moleculehash);
    event NewCation(bytes32 indexed moleculehash, bytes32 cation);
    event NewAnion(bytes32 indexed moleculehash, bytes32 anion);
    event NewAnions(bytes32 indexed moleculehash, bytes32[] anion);
    event PopAnion(bytes32 indexed moleculehash, bytes32 anion);
    event NewAlias(bytes32 indexed moleculehash, bytes32 _alias);
    event NewController(bytes32 indexed moleculehash, address controller);
    event NewExpiry(bytes32 indexed moleculehash, uint expiry);
    event NewRecord(bytes32 indexed moleculehash, address resolver);
    event NewSecureFlag(bytes32 indexed moleculehash, bool secure);
    event NewResolver(bytes32 indexed moleculehash, address resolver);
    event ApprovalForAll(
        address indexed cation,
        address indexed operator,
        bool approved
    );

    error AnionNotFound(bytes32 polyculehash, bytes32 anion);

    /// Dev
    address public Dev;

    /// @dev : Molecule roothash
    bytes32 public roothash = HELIX2.getRoothash()[2];
    uint256 public basePrice = HELIX2.getPrices()[2];

    /// @dev : Helix2 MOLECULE struct
    struct Molecule {
        address[] _hooks; /// Hooks
        mapping(address => uint8) _rules; /// Rules for Hooks
        bytes32 _cation; /// Source of Molecule (= Owner)
        bytes32[] _anion; /// Targets of Molecule
        bytes32 _alias; /// Hash of Molecule
        address _resolver; /// Resolver of Molecule
        address _controller; /// Controller of Molecule
        bool _secure; /// Mutuality Flag
        uint _expiry; /// Expiry of Molecule
    }
    mapping(bytes32 => Molecule) public Molecules;
    mapping(address => mapping(address => bool)) Operators;

    /**
     * @dev Initialise a new HELIX2 Molecules Registry
     * @notice : grants ownership of '0x0' to contract
     */
    constructor() {
        /// give ownership of '0x0' and <roothash> to Dev
        Molecules[0x0]._cation = roothash;
        Molecules[roothash]._cation = roothash;
        Dev = msg.sender;
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
    modifier onlyController(bytes32 moleculehash) {
        require(
            block.timestamp < Molecules[moleculehash]._expiry,
            "MOLECULE_EXPIRED"
        ); // expiry check
        require(
            msg.sender == Molecules[moleculehash]._controller,
            "NOT_CONTROLLER"
        );
        _;
    }

    /// @dev : Modifier to allow Cation or Controller
    modifier isCationOrController(bytes32 moleculehash) {
        require(
            block.timestamp < Molecules[moleculehash]._expiry,
            "MOLECULE_EXPIRED"
        ); // expiry check
        bytes32 __cation = Molecules[moleculehash]._cation;
        address _cation = NAMES.owner(__cation);
        require(
            _cation == msg.sender ||
                Operators[_cation][msg.sender] ||
                msg.sender == Molecules[moleculehash]._controller,
            "NOT_OWNER_OR_CONTROLLER"
        );
        _;
    }

    /**
     * @dev : verify molecule is not expired
     * @param moleculehash : hash of molecule
     */
    modifier isNotExpired(bytes32 moleculehash) {
        require(
            block.timestamp < Molecules[moleculehash]._expiry,
            "MOLECULE_EXPIRED"
        ); // expiry check
        _;
    }

    /**
     * @dev : check if new config is a duplicate
     * @param moleculehash : hash of molecule
     * @param config : config to check
     */
    function isNotDuplicateHook(
        bytes32 moleculehash,
        address config
    ) public view returns (bool) {
        return !config.existsIn(Molecules[moleculehash]._hooks);
    }

    /**
     * @dev : check if new anion is a duplicate
     * @param moleculehash : hash of molecule
     * @param _anion : anion to check
     */
    function isNotDuplicateAnion(
        bytes32 moleculehash,
        bytes32 _anion
    ) public view returns (bool) {
        return !_anion.existsIn(Molecules[moleculehash]._anion);
    }

    /**
     * @dev : verify ownership of molecule
     * @param moleculehash : hash of molecule
     */
    modifier onlyCation(bytes32 moleculehash) {
        require(
            block.timestamp < Molecules[moleculehash]._expiry,
            "MOLECULE_EXPIRED"
        ); // expiry check
        bytes32 __cation = Molecules[moleculehash]._cation;
        address _cation = NAMES.owner(__cation);
        require(
            _cation == msg.sender || Operators[_cation][msg.sender],
            "NOT_OWNER"
        );
        _;
    }

    /**
     * @dev : set cation of a molecule
     * @param moleculehash : hash of molecule
     * @param _cation : new cation
     */
    function setCation(
        bytes32 moleculehash,
        bytes32 _cation
    ) external onlyCation(moleculehash) {
        Molecules[moleculehash]._cation = _cation;
        emit NewCation(moleculehash, _cation);
    }

    /**
     * @dev : set controller of a molecule
     * @param moleculehash : hash of molecule
     * @param _controller : new controller
     */
    function setController(
        bytes32 moleculehash,
        address _controller
    ) external isCationOrController(moleculehash) {
        Molecules[moleculehash]._controller = _controller;
        emit NewController(moleculehash, _controller);
    }

    /**
     * @dev : adds one anion to the molecule
     * @param moleculehash : hash of target molecule
     * @param _anion : hash of new anion
     */
    function addAnion(
        bytes32 moleculehash,
        bytes32 _anion
    ) external isCationOrController(moleculehash) {
        require(isNotDuplicateAnion(moleculehash, _anion), "ANION_EXISTS");
        Molecules[moleculehash]._anion.push(_anion);
        emit NewAnion(moleculehash, _anion);
    }

    /**
     * @dev : adds new array of anions to the molecule
     * @notice : will overwrite pre-existing anions
     * @param moleculehash : hash of target molecule
     * @param _anion : array of new anions
     */
    function setAnions(
        bytes32 moleculehash,
        bytes32[] memory _anion
    ) external isCationOrController(moleculehash) {
        for (uint i = 0; i < _anion.length; i++) {
            if (_anion[i].existsIn(Molecules[moleculehash]._anion)) {
                Molecules[moleculehash]._anion.push(_anion[i]);
            }
        }
        emit NewAnions(moleculehash, _anion);
    }

    /**
     * @dev : pops an anion from the molecule
     * @param moleculehash : hash of target molecule
     * @param __anion : hash of anion to remove
     */
    function popAnion(
        bytes32 moleculehash,
        bytes32 __anion
    ) external isCationOrController(moleculehash) {
        bytes32[] memory _anion = Molecules[moleculehash]._anion;
        if (__anion.existsIn(_anion)) {
            uint index = __anion.findIn(_anion);
            delete Molecules[moleculehash]._anion[index];
            emit PopAnion(moleculehash, __anion);
        } else {
            revert AnionNotFound(moleculehash, __anion);
        }
    }

    /**
     * @dev : set new alias for molecule
     * @param moleculehash : hash of molecule
     * @param _alias : bash of alias
     */
    function setAlias(
        bytes32 moleculehash,
        bytes32 _alias
    ) external isCationOrController(moleculehash) {
        Molecules[moleculehash]._alias = _alias;
        emit NewAlias(moleculehash, _alias);
    }

    /**
     * @dev : set new mutuality flag for molecule
     * @param moleculehash : hash of molecule
     * @param _secure : bool
     */
    function setSecure(
        bytes32 moleculehash,
        bool _secure
    ) external isCationOrController(moleculehash) {
        Molecules[moleculehash]._secure = _secure;
        emit NewSecureFlag(moleculehash, _secure);
    }

    /**
     * @dev : set resolver for a molecule
     * @param moleculehash : hash of molecule
     * @param _resolver : new resolver
     */
    function setResolver(
        bytes32 moleculehash,
        address _resolver
    ) external isCationOrController(moleculehash) {
        Molecules[moleculehash]._resolver = _resolver;
        emit NewResolver(moleculehash, _resolver);
    }

    /**
     * @dev : set expiry for a molecule
     * @param moleculehash : hash of molecule
     * @param _expiry : new expiry
     */
    function setExpiry(
        bytes32 moleculehash,
        uint _expiry
    ) external payable isCationOrController(moleculehash) {
        require(_expiry > Molecules[moleculehash]._expiry, "BAD_EXPIRY");
        uint newDuration = _expiry - Molecules[moleculehash]._expiry;
        require(msg.value >= newDuration * basePrice, "INSUFFICIENT_ETHER");
        Molecules[moleculehash]._expiry = _expiry;
        emit NewExpiry(moleculehash, _expiry);
    }

    /**
     * @dev : set record for a molecule
     * @param moleculehash : hash of molecule
     * @param _resolver : new record
     */
    function setRecord(
        bytes32 moleculehash,
        address _resolver
    ) external isCationOrController(moleculehash) {
        Molecules[moleculehash]._resolver = _resolver;
        emit NewRecord(moleculehash, _resolver);
    }

    /**
     * @dev adds a new hook with rule
     * @param moleculehash : hash of the molecule
     * @param rule : rule for the hook
     * @param config : address of config contract
     */
    function hook(
        bytes32 moleculehash,
        uint8 rule,
        address config
    ) external onlyCation(moleculehash) {
        require(isNotDuplicateHook(moleculehash, config), "HOOK_EXISTS");
        Molecules[moleculehash]._hooks.push(config);
        Molecules[moleculehash]._rules[config] = rule;
        emit Hooked(moleculehash, config, rule);
    }

    /**
     * @dev rehooks a hook to a new rule
     * @param moleculehash : hash of the molecule
     * @param rule : rule for the new hook
     * @param config : address of config contract
     */
    function rehook(
        bytes32 moleculehash,
        uint8 rule,
        address config
    ) external onlyCation(moleculehash) {
        require(Molecules[moleculehash]._rules[config] != rule, "RULE_EXISTS");
        Molecules[moleculehash]._rules[config] = rule;
        emit Rehooked(moleculehash, config, rule);
    }

    /**
     * @dev removes a hook in a molecule
     * @param moleculehash : hash of the molecule
     * @param config : contract address of config
     */
    function unhook(
        bytes32 moleculehash,
        address config
    ) external onlyCation(moleculehash) {
        address[] memory _hooks = Molecules[moleculehash]._hooks;
        if (config.existsIn(_hooks)) {
            uint index = config.findIn(_hooks);
            if (index == uint(0)) {
                emit Unhooked(moleculehash, address(0));
            } else {
                Molecules[moleculehash]._rules[config] = uint8(0);
                emit Unhooked(moleculehash, config);
                delete Molecules[moleculehash]._hooks[index];
            }
        } else {
            emit Unhooked(moleculehash, address(0));
        }
    }

    /**
     * @dev removes all hooks in a molecule
     * @param moleculehash : hash of the molecule
     */
    function unhookAll(bytes32 moleculehash) external onlyCation(moleculehash) {
        address[] memory _hooks = Molecules[moleculehash]._hooks;
        for (uint i = 0; i < _hooks.length; i++) {
            Molecules[moleculehash]._rules[_hooks[i]] = uint8(0);
            emit Unhooked(moleculehash, _hooks[i]);
        }
        delete Molecules[moleculehash]._hooks;
        emit UnhookedAll(moleculehash);
        Molecules[moleculehash]._hooks.push(address(0));
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
     * @param moleculehash : hash of molecule to query
     * @return hash of cation
     */
    function cation(
        bytes32 moleculehash
    ) public view isNotExpired(moleculehash) returns (bytes32) {
        bytes32 __cation = Molecules[moleculehash]._cation;
        address _cation = NAMES.owner(__cation);
        if (_cation == address(this)) {
            return roothash;
        }
        return __cation;
    }

    /**
     * @dev return controller of a molecule
     * @param moleculehash : hash of molecule to query
     * @return address of controller
     */
    function controller(
        bytes32 moleculehash
    ) public view isNotExpired(moleculehash) returns (address) {
        address _controller = Molecules[moleculehash]._controller;
        return _controller;
    }

    /**
     * @dev shows mutuality state of a molecule
     * @param moleculehash : hash of molecule to query
     * @return mutuality state of the molecule
     */
    function secure(
        bytes32 moleculehash
    ) public view isNotExpired(moleculehash) returns (bool) {
        bool _secure = Molecules[moleculehash]._secure;
        return _secure;
    }

    /**
     * @dev return hooks of a molecule
     * @param moleculehash : hash of molecule to query
     * @return tuple of (hooks, rules)
     */
    function hooks(
        bytes32 moleculehash
    )
        public
        view
        isNotExpired(moleculehash)
        returns (address[] memory, uint8[] memory)
    {
        address[] memory _hooks = Molecules[moleculehash]._hooks;
        uint8[] memory _rules = new uint8[](_hooks.length);
        for (uint i = 0; i < _hooks.length; i++) {
            _rules[i] = Molecules[moleculehash]._rules[_hooks[i]];
        }
        return (_hooks, _rules);
    }

    /**
     * @dev return anions of a molecule
     * @param moleculehash : hash of molecule to query
     * @return array of anions
     */
    function anion(
        bytes32 moleculehash
    ) public view isNotExpired(moleculehash) returns (bytes32[] memory) {
        bytes32[] memory _anion = Molecules[moleculehash]._anion;
        return _anion;
    }

    /**
     * @dev return expiry of a molecule
     * @param moleculehash : hash of molecule to query
     * @return expiry
     */
    function expiry(bytes32 moleculehash) public view returns (uint) {
        uint _expiry = Molecules[moleculehash]._expiry;
        return _expiry;
    }

    /**
     * @dev return resolver of a molecule
     * @param moleculehash : hash of molecule to query
     * @return address of resolver
     */
    function resolver(
        bytes32 moleculehash
    ) public view isNotExpired(moleculehash) returns (address) {
        address _resolver = Molecules[moleculehash]._resolver;
        return _resolver;
    }

    /**
     * @dev check if a molecule is registered
     * @param moleculehash : hash of molecule to query
     * @return true or false
     */
    function recordExists(bytes32 moleculehash) public view returns (bool) {
        return block.timestamp < Molecules[moleculehash]._expiry;
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
    function withdrawEther() external payable {
        (bool ok, ) = Dev.call{value: address(this).balance}("");
        require(ok, "ETH_TRANSFER_FAILED");
    }

    /**
     * @dev : to be used in case some tokens get locked in the contract
     * @param token : token to release
     */
    function withdrawToken(address token) external payable {
        iERC20(token).transferFrom(
            address(this),
            Dev,
            iERC20(token).balanceOf(address(this))
        );
    }
}
