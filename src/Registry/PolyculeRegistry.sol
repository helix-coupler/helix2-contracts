//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Interface/iPolycule.sol";
import "src/Interface/iName.sol";
import "src/Interface/iHelix2.sol";
import "src/Interface/iERC721.sol";
import "src/Utils/LibString.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Polycule Base
 */
abstract contract Helix2Polycules {
    using LibString for bytes32[];
    using LibString for bytes32;
    using LibString for address[];
    using LibString for address;
    using LibString for string[];
    using LibString for string;

    iHELIX2 public HELIX2 = iHELIX2(address(0x0));
    iNAME public NAMES = iNAME(HELIX2.getRegistry()[3]);

    /// @dev : Helix2 Polycule events
    event NewDev(address Dev, address newDev);
    event NewPolycule(bytes32 indexed polyculehash, bytes32 cation);
    event Hooked(bytes32 indexed polyculehash, address config, uint8 rule);
    event RehookedConfig(
        bytes32 indexed polyculehash,
        address config,
        uint8 rule
    );
    event UnhookedConfig(bytes32 indexed polyculehash, address config);
    event RehookedAnion(
        bytes32 indexed polyculehash,
        bytes32 anion,
        uint8 rule
    );
    event UnhookedAnion(bytes32 indexed polyculehash, bytes32 anion);
    event UnhookedAll(bytes32 indexed polyculehash);
    event NewCation(bytes32 indexed polyculehash, bytes32 cation);
    event NewAnion(bytes32 indexed polyculehash, bytes32 anion);
    event NewAnions(bytes32 indexed polyculehash, bytes32[] anion);
    event PopAnion(bytes32 indexed polyculehash, bytes32 anion);
    event NewAlias(bytes32 indexed polyculehash, bytes32 _alias);
    event NewController(bytes32 indexed polyculehash, address controller);
    event NewExpiry(bytes32 indexed polyculehash, uint expiry);
    event NewRecord(bytes32 indexed polyculehash, address resolver);
    event NewSecureFlag(
        bytes32 indexed polyculehash,
        bytes32 anion,
        bool secure
    );
    event NewSecureSet(bytes32 indexed polyculehash, bool[] secure);
    event NewResolver(bytes32 indexed polyculehash, address resolver);
    event ApprovalForAll(
        address indexed cation,
        address indexed operator,
        bool approved
    );

    error AnionNotFound(bytes32 polyculehash, bytes32 anion);

    /// Dev
    address public Dev;

    /// @dev : Polycule roothash
    bytes32 public roothash = HELIX2.getRoothash()[3];
    uint256 public basePrice = HELIX2.getPrices()[3];

    /// @dev : Helix2 POLYCULE struct
    struct Polycule {
        address[] _hooks; /// Hooks
        mapping(address => uint8) _rules; /// Rules for Hooks
        bytes32 _cation; /// Source of Polycule (= Owner)
        bytes32[] _anion; /// Targets of Polycule
        bytes32 _alias; /// Hash of Polycule
        address _resolver; /// Resolver of Polycule
        address _controller; /// Controller of Polycule
        bool[] _secure; /// Mutuality Flags
        uint _expiry; /// Expiry of Polycule
    }
    mapping(bytes32 => Polycule) public Polycules;
    mapping(address => mapping(address => bool)) Operators;

    /**
     * @dev Initialise a new HELIX2 Polycules Registry
     * @notice : grants ownership of '0x0' to contract
     */
    constructor() {
        /// give ownership of '0x0' and <roothash> to Dev
        Polycules[0x0]._cation = roothash;
        Polycules[roothash]._cation = roothash;
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
    modifier onlyController(bytes32 polyculehash) {
        require(
            block.timestamp < Polycules[polyculehash]._expiry,
            "POLYCULE_EXPIRED"
        ); // expiry check
        require(
            msg.sender == Polycules[polyculehash]._controller,
            "NOT_CONTROLLER"
        );
        _;
    }

    /// @dev : Modifier to allow Cation or Controller
    modifier isCationOrController(bytes32 polyculehash) {
        require(
            block.timestamp < Polycules[polyculehash]._expiry,
            "POLYCULE_EXPIRED"
        ); // expiry check
        bytes32 __cation = Polycules[polyculehash]._cation;
        address _cation = NAMES.owner(__cation);
        require(
            _cation == msg.sender ||
                Operators[_cation][msg.sender] ||
                msg.sender == Polycules[polyculehash]._controller,
            "NOT_OWNER_OR_CONTROLLER"
        );
        _;
    }

    /**
     * @dev : verify polycule is not expired
     * @param polyculehash : hash of polycule
     */
    modifier isNotExpired(bytes32 polyculehash) {
        require(
            block.timestamp < Polycules[polyculehash]._expiry,
            "POLYCULE_EXPIRED"
        ); // expiry check
        _;
    }

    /**
     * @dev : check if new config is a duplicate
     * @param polyculehash : hash of polycule
     * @param config : config to check
     */
    function isNotDuplicateHook(
        bytes32 polyculehash,
        address config
    ) public view returns (bool) {
        return !config.existsIn(Polycules[polyculehash]._hooks);
    }

    /**
     * @dev : check if new anion is a duplicate
     * @param polyculehash : hash of polycule
     * @param _anion : anion to check
     */
    function isNotDuplicateAnion(
        bytes32 polyculehash,
        bytes32 _anion
    ) public view returns (bool) {
        return !_anion.existsIn(Polycules[polyculehash]._anion);
    }

    /**
     * @dev : verify if each anion has a hook
     * @param _anion : array of anions
     * @param _config : array of config addresses
     */
    function isLegalMap(
        bytes32[] memory _anion,
        address[] memory _config
    ) public pure returns (bool) {
        if (_anion.length == _config.length) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev : verify ownership of polycule
     * @param polyculehash : hash of polycule
     */
    modifier onlyCation(bytes32 polyculehash) {
        require(
            block.timestamp < Polycules[polyculehash]._expiry,
            "POLYCULE_EXPIRED"
        ); // expiry check
        bytes32 __cation = Polycules[polyculehash]._cation;
        address _cation = NAMES.owner(__cation);
        require(
            _cation == msg.sender || Operators[_cation][msg.sender],
            "NOT_OWNER"
        );
        _;
    }

    /**
     * @dev : set cation of a polycule
     * @param polyculehash : hash of polycule
     * @param _cation : new cation
     */
    function setCation(
        bytes32 polyculehash,
        bytes32 _cation
    ) external onlyCation(polyculehash) {
        Polycules[polyculehash]._cation = _cation;
        emit NewCation(polyculehash, _cation);
    }

    /**
     * @dev : set controller of a polycule
     * @param polyculehash : hash of polycule
     * @param _controller : new controller
     */
    function setController(
        bytes32 polyculehash,
        address _controller
    ) external isCationOrController(polyculehash) {
        Polycules[polyculehash]._controller = _controller;
        emit NewController(polyculehash, _controller);
    }

    /**
     * @dev : adds one anion to the polycule
     * @param polyculehash : hash of target polycule
     * @param _anion : hash of new anion
     */
    function addAnion(
        bytes32 polyculehash,
        bytes32 _anion,
        address config,
        uint8 rule
    ) external isCationOrController(polyculehash) {
        require(isNotDuplicateAnion(polyculehash, _anion), "ANION_EXISTS");
        require(isNotDuplicateHook(polyculehash, config), "HOOK_EXISTS");
        require(Polycules[polyculehash]._rules[config] != rule, "RULE_EXISTS");
        Polycules[polyculehash]._anion.push(_anion);
        Polycules[polyculehash]._hooks.push(config);
        Polycules[polyculehash]._rules[config] == rule;
        emit NewAnion(polyculehash, _anion);
        emit Hooked(polyculehash, config, rule);
    }

    /**
     * @dev : adds new array of anions to the polycule
     * @notice : will overwrite pre-existing anions
     * @param polyculehash : hash of target polycule
     * @param _anion : array of new anions
     * @param _config : array of new config
     * @param _rules : array of rules for hooks
     */
    function setAnions(
        bytes32 polyculehash,
        bytes32[] memory _anion,
        address[] memory _config,
        uint8[] memory _rules
    ) external isCationOrController(polyculehash) {
        require(isLegalMap(_anion, _config), "BAD_MAP");
        for (uint i = 0; i < _anion.length; i++) {
            if (!_anion[i].existsIn(Polycules[polyculehash]._anion)) {
                Polycules[polyculehash]._anion.push(_anion[i]);
                Polycules[polyculehash]._hooks.push(_config[i]);
                Polycules[polyculehash]._rules[_config[i]] = _rules[i];
                Polycules[polyculehash]._secure.push(false);
            }
        }
        emit NewAnions(polyculehash, _anion);
    }

    /**
     * @dev : pops an anion from the polycule
     * @param polyculehash : hash of target polycule
     * @param __anion : hash of anion to remove
     */
    function popAnion(
        bytes32 polyculehash,
        bytes32 __anion
    ) external isCationOrController(polyculehash) {
        bytes32[] memory _anion = Polycules[polyculehash]._anion;
        if (__anion.existsIn(_anion)) {
            uint index = __anion.findIn(_anion);
            delete Polycules[polyculehash]._anion[index];
            emit PopAnion(polyculehash, __anion);
        } else {
            revert AnionNotFound(polyculehash, __anion);
        }
    }

    /**
     * @dev : set new alias for polycule
     * @param polyculehash : hash of polycule
     * @param _alias : bash of alias
     */
    function setAlias(
        bytes32 polyculehash,
        bytes32 _alias
    ) external isCationOrController(polyculehash) {
        Polycules[polyculehash]._alias = _alias;
        emit NewAlias(polyculehash, _alias);
    }

    /**
     * @dev : switches mutuality flag for an anion
     * @param polyculehash : hash of polycule
     * @param __anion : anion to switch flag for
     */
    function switchSecure(
        bytes32 polyculehash,
        bytes32 __anion
    ) external isCationOrController(polyculehash) {
        bytes32[] memory _anion = Polycules[polyculehash]._anion;
        if (__anion.existsIn(_anion)) {
            uint index = __anion.findIn(_anion);
            bool _flag = Polycules[polyculehash]._secure[index];
            Polycules[polyculehash]._secure[index] = !_flag;
            emit NewSecureFlag(polyculehash, __anion, !_flag);
        } else {
            revert AnionNotFound(polyculehash, __anion);
        }
    }

    /**
     * @dev : switches mutuality flag for an anion
     * @param polyculehash : hash of polycule
     * @param _secure : anion to switch flag for
     */
    function setSecure(
        bytes32 polyculehash,
        bool[] memory _secure
    ) external isCationOrController(polyculehash) {
        delete Polycules[polyculehash]._secure;
        Polycules[polyculehash]._secure = _secure;
        emit NewSecureSet(polyculehash, _secure);
    }

    /**
     * @dev : set resolver for a polycule
     * @param polyculehash : hash of polycule
     * @param _resolver : new resolver
     */
    function setResolver(
        bytes32 polyculehash,
        address _resolver
    ) external isCationOrController(polyculehash) {
        Polycules[polyculehash]._resolver = _resolver;
        emit NewResolver(polyculehash, _resolver);
    }

    /**
     * @dev : set expiry for a polycule
     * @param polyculehash : hash of polycule
     * @param _expiry : new expiry
     */
    function setExpiry(
        bytes32 polyculehash,
        uint _expiry
    ) external payable isCationOrController(polyculehash) {
        require(_expiry > Polycules[polyculehash]._expiry, "BAD_EXPIRY");
        uint newDuration = _expiry - Polycules[polyculehash]._expiry;
        require(msg.value >= newDuration * basePrice, "INSUFFICIENT_ETHER");
        Polycules[polyculehash]._expiry = _expiry;
        emit NewExpiry(polyculehash, _expiry);
    }

    /**
     * @dev : set record for a polycule
     * @param polyculehash : hash of polycule
     * @param _resolver : new record
     */
    function setRecord(
        bytes32 polyculehash,
        address _resolver
    ) external isCationOrController(polyculehash) {
        Polycules[polyculehash]._resolver = _resolver;
        emit NewRecord(polyculehash, _resolver);
    }

    /**
     * @dev adds a new hook with rule (must specify anion for the hook)
     * @param __anion : anion to add hook for
     * @param polyculehash : hash of the polycule
     * @param rule : rule for the hook
     * @param config : address of config contract
     */
    function hook(
        bytes32 __anion,
        bytes32 polyculehash,
        uint8 rule,
        address config
    ) external onlyCation(polyculehash) {
        require(isNotDuplicateHook(polyculehash, config), "HOOK_EXISTS");
        Polycules[polyculehash]._hooks.push(config);
        Polycules[polyculehash]._rules[config] = rule;
        Polycules[polyculehash]._anion.push(__anion);
        emit Hooked(polyculehash, config, rule);
    }

    /**
     * @dev rehooks a hook to a new rule
     * @param polyculehash : hash of the polycule
     * @param rule : rule for the new hook
     * @param config : address of config contract
     */
    function rehook(
        bytes32 polyculehash,
        uint8 rule,
        address config
    ) external onlyCation(polyculehash) {
        require(Polycules[polyculehash]._rules[config] != rule, "RULE_EXISTS");
        Polycules[polyculehash]._rules[config] = rule;
        emit RehookedConfig(polyculehash, config, rule);
    }

    /**
     * @dev rehooks a hook to a new rule
     * @param polyculehash : hash of the polycule
     * @param rule : rule for the new hook
     * @param __anion : hash of anion
     */
    function rehook(
        bytes32 polyculehash,
        uint8 rule,
        bytes32 __anion
    ) external onlyCation(polyculehash) {
        address[] memory _hooks = Polycules[polyculehash]._hooks;
        bytes32[] memory _anion = Polycules[polyculehash]._anion;
        if (__anion.existsIn(_anion)) {
            uint index = __anion.findIn(_anion);
            require(
                Polycules[polyculehash]._rules[_hooks[index]] != rule,
                "RULE_EXISTS"
            );
            Polycules[polyculehash]._rules[_hooks[index]] = rule;
            emit RehookedAnion(polyculehash, __anion, rule);
        } else {
            revert AnionNotFound(polyculehash, __anion);
        }
    }

    /**
     * @dev removes a hook in a polycule
     * @param polyculehash : hash of the polycule
     * @param config : contract address of config
     */
    function unhook(
        bytes32 polyculehash,
        address config
    ) external onlyCation(polyculehash) {
        address[] memory _hooks = Polycules[polyculehash]._hooks;
        if (config.existsIn(_hooks)) {
            uint index = config.findIn(_hooks);
            if (index == uint(0)) {
                emit UnhookedConfig(polyculehash, address(0));
            } else {
                Polycules[polyculehash]._rules[config] = uint8(0);
                emit UnhookedConfig(polyculehash, config);
                delete Polycules[polyculehash]._hooks[index];
            }
        } else {
            emit UnhookedConfig(polyculehash, address(0));
        }
    }

    /**
     * @dev removes a hook in a polycule
     * @param polyculehash : hash of the polycule
     * @param __anion : __anion to unhook
     */
    function unhook(
        bytes32 polyculehash,
        bytes32 __anion
    ) external onlyCation(polyculehash) {
        address[] memory _hooks = Polycules[polyculehash]._hooks;
        bytes32[] memory _anion = Polycules[polyculehash]._anion;
        if (__anion.existsIn(_anion)) {
            uint index = __anion.findIn(_anion);
            Polycules[polyculehash]._rules[_hooks[index]] = uint8(0);
            emit UnhookedAnion(polyculehash, __anion);
            delete Polycules[polyculehash]._hooks[index];
        } else {
            emit UnhookedAnion(polyculehash, bytes32(0));
        }
    }

    /**
     * @dev removes all hooks in a polycule
     * @param polyculehash : hash of the polycule
     */
    function unhookAll(bytes32 polyculehash) external onlyCation(polyculehash) {
        address[] memory _hooks = Polycules[polyculehash]._hooks;
        for (uint i = 0; i < _hooks.length; i++) {
            Polycules[polyculehash]._rules[_hooks[i]] = uint8(0);
            emit UnhookedConfig(polyculehash, _hooks[i]);
        }
        delete Polycules[polyculehash]._hooks;
        emit UnhookedAll(polyculehash);
        Polycules[polyculehash]._hooks.push(address(0));
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
     * @param polyculehash : hash of polycule to query
     * @return hash of cation
     */
    function cation(
        bytes32 polyculehash
    ) public view isNotExpired(polyculehash) returns (bytes32) {
        bytes32 __cation = Polycules[polyculehash]._cation;
        address _cation = NAMES.owner(__cation);
        if (_cation == address(this)) {
            return roothash;
        }
        return __cation;
    }

    /**
     * @dev return controller of a polycule
     * @param polyculehash : hash of polycule to query
     * @return address of controller
     */
    function controller(
        bytes32 polyculehash
    ) public view isNotExpired(polyculehash) returns (address) {
        address _controller = Polycules[polyculehash]._controller;
        return _controller;
    }

    /**
     * @dev shows mutuality state of a polycule
     * @param polyculehash : hash of polycule to query
     * @return mutuality state of the polycule
     */
    function secure(
        bytes32 polyculehash
    ) public view isNotExpired(polyculehash) returns (bool[] memory) {
        bool[] memory _secure = Polycules[polyculehash]._secure;
        return _secure;
    }

    /**
     * @dev return hooks of a polycule
     * @param polyculehash : hash of polycule to query
     * @return tuple of (hooks, rules)
     */
    function hooks(
        bytes32 polyculehash
    )
        public
        view
        isNotExpired(polyculehash)
        returns (address[] memory, uint8[] memory)
    {
        address[] memory _hooks = Polycules[polyculehash]._hooks;
        uint8[] memory _rules = new uint8[](_hooks.length);
        for (uint i = 0; i < _hooks.length; i++) {
            _rules[i] = Polycules[polyculehash]._rules[_hooks[i]];
        }
        return (_hooks, _rules);
    }

    /**
     * @dev return anions of a polycule
     * @param polyculehash : hash of polycule to query
     * @return array of anions
     */
    function anion(
        bytes32 polyculehash
    ) public view isNotExpired(polyculehash) returns (bytes32[] memory) {
        bytes32[] memory _anion = Polycules[polyculehash]._anion;
        return _anion;
    }

    /**
     * @dev return expiry of a polycule
     * @param polyculehash : hash of polycule to query
     * @return expiry
     */
    function expiry(bytes32 polyculehash) public view returns (uint) {
        uint _expiry = Polycules[polyculehash]._expiry;
        return _expiry;
    }

    /**
     * @dev return resolver of a polycule
     * @param polyculehash : hash of polycule to query
     * @return address of resolver
     */
    function resolver(
        bytes32 polyculehash
    ) public view isNotExpired(polyculehash) returns (address) {
        address _resolver = Polycules[polyculehash]._resolver;
        return _resolver;
    }

    /**
     * @dev check if a polycule is registered
     * @param polyculehash : hash of polycule to query
     * @return true or false
     */
    function recordExists(bytes32 polyculehash) public view returns (bool) {
        return block.timestamp < Polycules[polyculehash]._expiry;
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
