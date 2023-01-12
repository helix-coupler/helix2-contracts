//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Names/iName.sol";
import "src/Bonds/iBond.sol";
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
 * @title Helix2 Bond Registry
 */
contract Helix2BondRegistry {
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
    iBOND public STORE;
    iPriceOracle public PRICES;

    /// @dev : Helix2 Bond events
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event Hooked(bytes32 indexed bondhash, address config, uint8 rule);
    event Rehooked(bytes32 indexed bondhash, address config, uint8 rule);
    event Unhooked(bytes32 indexed bondhash, uint8 rule);
    event UnhookedAll(bytes32 indexed bondhash);
    event NewCation(bytes32 indexed bondhash, bytes32 cation);
    event NewAnion(bytes32 indexed bondhash, bytes32 anion);
    event NewController(bytes32 indexed bondhash, address controller);
    event NewExpiry(bytes32 indexed bondhash, uint expiry);
    event NewCovalence(bytes32 indexed bondhash, bool covalence);
    event NewResolver(bytes32 indexed bondhash, address resolver);

    error BAD_RULE();
    error BAD_HOOK();

    /// Dev
    address public Dev;

    /// @dev : Pause/Resume contract
    bool public active = true;
    /// @dev : EIP-165
    mapping(bytes4 => bool) public supportedInterfaces;

    /// @dev : Bond roothash
    bytes32 public roothash;
    uint256 public basePrice;
    address public Registrar;
    uint256 public theEnd = 250_000_000_000_000_000; // roughly 80,000,000,000 years in the future

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
    mapping(address => mapping(address => bool)) Operators;

    /**
     * @dev Initialise a new HELIX2 Bonds Registry
     * @notice
     * @param _helix2 : address of HELIX2 Manager
     * @param _registry : address of HELIX2 Name Registry
     */
    constructor(address _registry, address _helix2, address _priceOracle) {
        Dev = msg.sender;
        HELIX2 = iHELIX2(_helix2);
        NAMES = iNAME(_registry);
        roothash = HELIX2.getRoothash()[1];
        PRICES = iPriceOracle(_priceOracle);
        basePrice = PRICES.getPrices()[1];
        // Interface
        supportedInterfaces[type(iERC165).interfaceId] = true;
        supportedInterfaces[type(iERC173).interfaceId] = true;
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
            roothash = HELIX2.getRoothash()[1];
            Registrar = HELIX2.getRegistrar()[1];
        }
        if (_store != address(0)) {
            STORE = iBOND(_store);
        }
        if (_priceOracle != address(0)) {
            PRICES = iPriceOracle(_priceOracle);
            basePrice = PRICES.getPrices()[1];
        }
    }

    /**
     * @dev returns owner of contract
     * @notice EIP-173
     */
    function owner() external view returns (address) {
        return Dev;
    }

    /**
     * @dev transfer contract ownership to new Dev
     * @notice EIP-173
     * @param newDev : new Dev
     */
    function transferOwnership(address newDev) external onlyDev {
        emit OwnershipTransferred(Dev, newDev);
        Dev = newDev;
    }

    /**
     * @dev check if an interface is supported
     * @notice EIP-165
     * @param sig : bytes4 identifier
     */
    function supportsInterface(bytes4 sig) external view returns (bool) {
        return supportedInterfaces[sig];
    }

    /**
     * @dev sets supportInterface flag
     * @notice EIP-165
     * @param sig : bytes4 identifier
     * @param value : boolean
     */
    function setInterface(bytes4 sig, bool value) external payable onlyDev {
        require(sig != 0xffffffff, "INVALID_INTERFACE_SELECTOR");
        supportedInterfaces[sig] = value;
    }

    /// @dev : Modifier to allow Cation or Controller
    modifier isCationOrController(bytes32 bondhash) {
        require(block.timestamp < STORE.expiry(bondhash), "BOND_EXPIRED");
        bytes32 _cation = STORE.cation(bondhash);
        address _owner = NAMES.owner(_cation);
        require(
            _owner == msg.sender || msg.sender == STORE.controller(bondhash),
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
    modifier isAuthorised(bytes32 bondhash) {
        bytes32 _cation = STORE.cation(bondhash);
        address _owner = NAMES.owner(_cation);
        require(
            msg.sender == Registrar ||
                _owner == msg.sender ||
                msg.sender == STORE.controller(bondhash),
            "NOT_AUTHORISED"
        );
        _;
    }

    /**
     * @dev check if polycule is not expired
     * and can emit records
     * @param bondhash : hash of polycule
     */
    modifier canEmit(bytes32 bondhash) {
        require(block.timestamp < STORE.expiry(bondhash), "BOND_EXPIRED");
        _;
    }

    /**
     * @dev verify ownership of bond
     * @param bondhash : hash of bond
     */
    modifier isCation(bytes32 bondhash) {
        require(block.timestamp < STORE.expiry(bondhash), "BOND_EXPIRED");
        address _owner = NAMES.owner(STORE.cation(bondhash));
        require(_owner == msg.sender, "NOT_OWNER");
        _;
    }

    /**
     * @dev check if the bond is not duplicate
     * @param bondhash : hash of bond
     * @param newAnion : hash of new anion
     */
    function isNotDuplicateAnion(
        bytes32 bondhash,
        bytes32 newAnion
    ) public view returns (bool) {
        return STORE.anion(bondhash) != newAnion;
    }

    /**
     * @dev check if new config is a duplicate
     * @param bondhash : hash of bond
     * @param rule : rule to check
     */
    function isNotDuplicateRule(
        bytes32 bondhash,
        uint8 rule
    ) public view returns (bool) {
        (uint8[] memory _rules, ) = STORE.hooksWithRules(bondhash);
        return !rule.existsIn(_rules);
    }

    /**
     * @dev register owner of new bond
     * @param bondhash : hash of bond
     * @param _cation : new cation
     */
    function register(bytes32 bondhash, bytes32 _cation) external isRegistrar {
        require(NAMES.owner(_cation) != address(0), "CANNOT_BURN");
        STORE.setCation(bondhash, _cation);
        emit NewCation(bondhash, _cation);
    }

    /**
     * @dev set cation of a bond
     * @param bondhash : hash of bond
     * @param _cation : new cation
     */
    function setCation(
        bytes32 bondhash,
        bytes32 _cation
    ) external isCation(bondhash) {
        require(NAMES.owner(_cation) != address(0), "CANNOT_BURN");
        STORE.setCation(bondhash, _cation);
        emit NewCation(bondhash, _cation);
    }

    /**
     * @dev set controller of a bond
     * @param bondhash : hash of bond
     * @param _controller : new controller
     */
    function setController(
        bytes32 bondhash,
        address _controller
    ) external isAuthorised(bondhash) {
        STORE.setController(bondhash, _controller);
        emit NewController(bondhash, _controller);
    }

    /**
     * @dev set new anion of a bond
     * @param bondhash : hash of anion
     * @param _anion : address of anion
     */
    function setAnion(
        bytes32 bondhash,
        bytes32 _anion
    ) external isAuthorised(bondhash) {
        STORE.setAnion(bondhash, _anion);
        emit NewAnion(bondhash, _anion);
    }

    /**
     * @dev set new label for bond
     * @param bondhash : hash of bond
     * @param _label : bash of label
     */
    function setLabel(bytes32 bondhash, bytes32 _label) external isRegistrar {
        STORE.setLabel(bondhash, _label);
    }

    /**
     * @dev set new mutuality flag for bond
     * @param bondhash : hash of bond
     * @param _covalence : bool
     */
    function setCovalence(
        bytes32 bondhash,
        bool _covalence
    ) external isAuthorised(bondhash) {
        STORE.setCovalence(bondhash, _covalence);
        emit NewCovalence(bondhash, _covalence);
    }

    /**
     * @dev set resolver for a bond
     * @param bondhash : hash of bond
     * @param _resolver : new resolver
     */
    function setResolver(
        bytes32 bondhash,
        address _resolver
    ) external isAuthorised(bondhash) {
        STORE.setResolver(bondhash, _resolver);
        emit NewResolver(bondhash, _resolver);
    }

    /**
     * @dev set expiry for a bond
     * @param bondhash : hash of bond
     * @param _expiry : new expiry
     */
    function setExpiry(bytes32 bondhash, uint _expiry) external isRegistrar {
        require(_expiry > STORE.expiry(bondhash), "BAD_EXPIRY");
        STORE.setExpiry(bondhash, _expiry);
        emit NewExpiry(bondhash, _expiry);
    }

    /**
     * @dev set expiry for a bond
     * @param bondhash : hash of bond
     * @param _expiry : new expiry
     */
    function renew(
        bytes32 bondhash,
        uint _expiry
    ) external payable isCationOrController(bondhash) {
        uint currentExpiry = STORE.expiry(bondhash);
        require(_expiry > currentExpiry, "BAD_EXPIRY");
        require(
            msg.value >= (_expiry - currentExpiry) * basePrice,
            "INSUFFICIENT_ETHER"
        );
        STORE.setExpiry(bondhash, _expiry);
        emit NewExpiry(bondhash, _expiry);
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
    ) external isCationOrController(bondhash) {
        require(isNotDuplicateRule(bondhash, rule), "RULE_EXISTS");
        STORE.hook(bondhash, config, rule);
        emit Hooked(bondhash, config, rule);
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
    ) external isCationOrController(bondhash) {
        (uint8[] memory _rules, address[] memory _hooks) = STORE.hooksWithRules(
            bondhash
        );
        if (rule.existsIn(_rules)) {
            uint index = rule.findIn(_rules);
            require(_hooks[index] != config, "RULE_EXISTS");
            STORE.rehook(bondhash, config, rule);
            emit Rehooked(bondhash, config, rule);
        } else {
            revert BAD_RULE();
        }
    }

    /**
     * @dev removes a hook in a bond
     * @param bondhash : hash of the bond
     * @param rule : rule to unhook
     */
    function unhook(
        bytes32 bondhash,
        uint8 rule
    ) external isCationOrController(bondhash) {
        (uint8[] memory _rules, ) = STORE.hooksWithRules(bondhash);
        if (rule.existsIn(_rules)) {
            uint index = rule.findIn(_rules);
            STORE.unhook(bondhash, rule, index);
            emit Unhooked(bondhash, rule);
        } else {
            revert BAD_HOOK();
        }
    }

    /**
     * @dev removes all hooks in a bond
     * @param bondhash : hash of the bond
     */
    function unhookAll(bytes32 bondhash) external isAuthorised(bondhash) {
        STORE.unhookAll(bondhash);
        emit UnhookedAll(bondhash);
    }

    /**
     * @dev return cation of a bond
     * @param bondhash : hash of bond to query
     * @return hash of cation
     */
    function cation(
        bytes32 bondhash
    ) public view canEmit(bondhash) returns (bytes32) {
        bytes32 _cation = STORE.cation(bondhash);
        address _owner = NAMES.owner(_cation);
        if (_owner == address(this)) {
            return bytes32(0);
        }
        return _cation;
    }

    /**
     * @dev return controller of a bond
     * @param bondhash : hash of bond to query
     * @return address of controller
     */
    function controller(
        bytes32 bondhash
    ) public view canEmit(bondhash) returns (address) {
        return STORE.controller(bondhash);
    }

    /**
     * @dev return anion of a bond
     * @param bondhash : hash of bond to query
     * @return hash of anion
     */
    function anion(
        bytes32 bondhash
    ) public view canEmit(bondhash) returns (bytes32) {
        return STORE.anion(bondhash);
    }

    /**
     * @dev shows mutuality state of a bond
     * @param bondhash : hash of bond to query
     * @return mutuality state of the bond
     */
    function covalence(
        bytes32 bondhash
    ) public view canEmit(bondhash) returns (bool) {
        return STORE.covalence(bondhash);
    }

    /**
     * @dev shows label of a bond
     * @param bondhash : hash of bond to query
     * @return label of the bond
     */
    function label(
        bytes32 bondhash
    ) public view canEmit(bondhash) returns (bytes32) {
        return STORE.label(bondhash);
    }

    /**
     * @dev return hooks of a bond
     * @param bondhash : hash of bond to query
     * @return _rules
     * @return _hooks
     */
    function hooksWithRules(
        bytes32 bondhash
    )
        public
        view
        canEmit(bondhash)
        returns (uint8[] memory _rules, address[] memory _hooks)
    {
        (_rules, _hooks) = STORE.hooksWithRules(bondhash);
    }

    /**
     * @dev return expiry of a bond
     * @param bondhash : hash of bond to query
     * @return expiry
     */
    function expiry(bytes32 bondhash) public view returns (uint) {
        return STORE.expiry(bondhash);
    }

    /**
     * @dev return resolver of a bond
     * @param bondhash : hash of bond to query
     * @return address of resolver
     */
    function resolver(
        bytes32 bondhash
    ) public view canEmit(bondhash) returns (address) {
        return STORE.resolver(bondhash);
    }

    /**
     * @dev check if a bond is registered
     * @param bondhash : hash of bond to query
     * @return true or false
     */
    function recordExists(bytes32 bondhash) public view returns (bool) {
        return block.timestamp < STORE.expiry(bondhash);
    }

    /**
     * @dev withdraw ether to Dev, anyone can trigger
     */
    function withdrawEther() external {
        (bool ok, ) = Dev.call{value: address(this).balance}("");
        require(ok, "ETH_TRANSFER_FAILED");
    }

    /// @notice re-entrancy guard
    /// @dev : revert on fallback
    fallback() external payable {
        revert();
    }

    /// @dev : revert on receive
    receive() external payable {
        revert();
    }
}
