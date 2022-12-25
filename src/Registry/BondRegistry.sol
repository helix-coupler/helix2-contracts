//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Interface/iBond.sol";
import "src/Interface/iName.sol";
import "src/Interface/iHelix2.sol";
import "src/Interface/iERC721.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Bond Base
 */
abstract contract Helix2Bonds {

    iHELIX2 public HELIX2 = iHELIX2(address(0x0));
    iNAME public NAMES = iNAME(HELIX2.getRegistry()[1]);

    /// @dev : Helix2 Bond events
    event NewDev(address Dev, address newDev);
    event NewBond(bytes32 indexed bondhash, bytes32 cation);
    event NewCation(bytes32 indexed bondhash, bytes32 cation);
    event NewTarget(bytes32 indexed bondhash, bytes32 anion);
    event NewAlias(bytes32 indexed bondhash, bytes32 _alias);
    event NewController(bytes32 indexed bondhash, address controller);
    event NewExpiry(bytes32 indexed bondhash, uint expiry);
    event NewRecord(bytes32 indexed bondhash, address resolver);
    event NewResolver(bytes32 indexed bondhash, address resolver);
    event ApprovalForAll(address indexed cation, address indexed operator, bool approved);

    /// Dev
    address public Dev;

    /// @dev : Bond roothash
    bytes32 public roothash = HELIX2.getRoothash()[1];

    /// @dev : Helix2 Bond struct
    struct Bond {
        mapping(bytes32 => mapping(uint8 => address)) _hooks;     /// Hooks with Rules
        bytes32 _cation;                                          /// Source of Bond (= Owner)
        bytes32 _anion;                                           /// Target of Bond
        bytes32 _alias;                                           /// Hash of Bond
        address _resolver;                                        /// Resolver of Bond
        address _controller;                                      /// Controller of Bond
        bool _secure;                                             /// Mutuality Flag
        uint _expiry;                                             /// Expiry of Bond
    }
    mapping (bytes32 => Bond) public Bonds;
    mapping (address => mapping(address => bool)) Operators;

    /**
    * @dev Initialise a new HELIX2 Bonds Registry
    * @notice : grants ownership of '0x0' to contract
    */
    constructor() {
        /// give ownership of '0x0' and <roothash> to Dev
        Bonds[0x0]._cation = roothash;
        Bonds[roothash]._cation = roothash;
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
    modifier onlyController(bytes32 bondhash) {
        require(msg.sender == Bonds[bondhash]._controller, 'NOT_CONTROLLER');
        _;
    }

    /// @dev : Modifier to allow Cation or Controller
    modifier isCationOrController(bytes32 bondhash) {
        bytes32 __cation = Bonds[bondhash]._cation;
        address _cation = NAMES.owner(__cation);
        require(_cation == msg.sender || Operators[_cation][msg.sender] || msg.sender == Bonds[bondhash]._controller, "NOT_OWNER_OR_CONTROLLER");
        _;
    }

    /**
     * @dev : verify bond belongs to root
     * @param labelhash : hash of bond
     */
    modifier isNew(bytes32 labelhash) {
        bytes32 __cation =  Bonds[keccak256(abi.encodePacked(roothash, labelhash))]._cation;
        address _cation = NAMES.owner(__cation);
        require(_cation == address(0x0), "BOND_EXISTS");
        _;
    }

    /**
     * @dev : verify ownership of bond
     * @param bondhash : hash of bond
     */
    modifier onlyCation(bytes32 bondhash) {
        bytes32 __cation = Bonds[bondhash]._cation;
        address _cation = NAMES.owner(__cation);
        require(_cation == msg.sender || Operators[_cation][msg.sender], "NOT_OWNER");
        _;
    }

    /**
     * @dev : set cation of a bond
     * @param bondhash : hash of bond
     * @param _cation : new cation
     */
    function setCation(bytes32 bondhash, bytes32 _cation) external onlyCation(bondhash) {
        Bonds[bondhash]._cation = _cation;
        emit NewCation(bondhash, _cation);
    }

    /**
     * @dev : set controller of a bond
     * @param bondhash : hash of bond
     * @param _controller : new controller
     */
    function setController(bytes32 bondhash, address _controller) external isCationOrController(bondhash) {
        Bonds[bondhash]._controller = _controller;
        emit NewController(bondhash, _controller);
    }

    /**
     * @dev : set new anion of a bond
     * @param bondhash : hash of anion
     * @param _anion : address of anion
     */
    function setTarget(bytes32 bondhash, bytes32 _anion) external isCationOrController(bondhash) {
        Bonds[bondhash]._anion = _anion;
        emit NewTarget(bondhash, _anion);
    }

    /**
     * @dev : set new alias for bond
     * @param bondhash : hash of bond
     * @param _alias : bash of alias
     */
    function setAlias(bytes32 bondhash, bytes32 _alias) external isCationOrController(bondhash) {
        Bonds[bondhash]._alias = _alias;
        emit NewAlias(bondhash, _alias);
    }

    /**
     * @dev : set resolver for a bond
     * @param bondhash : hash of bond
     * @param _resolver : new resolver
     */
    function setResolver(bytes32 bondhash, address _resolver) external isCationOrController(bondhash) {
        Bonds[bondhash]._resolver = _resolver;
        emit NewResolver(bondhash, _resolver);
    }

    /**
     * @dev : set expiry for a bond
     * @param bondhash : hash of bond
     * @param _expiry : new expiry
     */
    function setExpiry(bytes32 bondhash, uint _expiry) external isCationOrController(bondhash) {
        Bonds[bondhash]._expiry = _expiry;
        emit NewExpiry(bondhash, _expiry);
    }

    /**
     * @dev : set record for a bond
     * @param bondhash : hash of bond
     * @param _resolver : new record
     */
    function setRecord(bytes32 bondhash, address _resolver) external isCationOrController(bondhash) {
        Bonds[bondhash]._resolver = _resolver;
        emit NewRecord(bondhash, _resolver);
    }

    /**
     * @dev : set operator for a bond
     * @param operator : new operator
     * @param approved : state to set
     */
    function setApprovalForAll(address operator, bool approved) external {
        Operators[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev return cation of a bond
     * @param bondhash hash of bond to query
     * @return hash of cation
     */
    function cation(bytes32 bondhash) public view returns (bytes32) {
        bytes32 __cation = Bonds[bondhash]._cation;
        address _cation = NAMES.owner(__cation);
        if (_cation == address(this)) {
            return roothash;
        }
        return __cation;
    }

    /**
     * @dev return controller of a bond
     * @param bondhash hash of bond to query
     * @return address of controller
     */
    function controller(bytes32 bondhash) public view returns (address) {
        address _controller = Bonds[bondhash]._controller;
        return _controller;
    }

    /**
     * @dev return anion of a bond
     * @param bondhash hash of bond to query
     * @return hash of anion
     */
    function anion(bytes32 bondhash) public view returns (bytes32) {
        bytes32 _anion = Bonds[bondhash]._anion;
        return _anion;
    }

    /**
     * @dev shows mutuality state of a bond
     * @param bondhash hash of bond to query
     * @return mutuality state of the bond
     */
    function secure(bytes32 bondhash) public view returns (bool) {
        bool _secure = Bonds[bondhash]._secure;
        return _secure;
    }

    /**
     * @dev return expiry of a bond
     * @param bondhash hash of bond to query
     * @return expiry
     */
    function expiry(bytes32 bondhash) public view returns (uint) {
        uint _expiry = Bonds[bondhash]._expiry;
        return _expiry;
    }   

    /**
     * @dev return resolver of a bond
     * @param bondhash hash of bond to query
     * @return address of resolver
     */
    function resolver(bytes32 bondhash) public view returns (address) {
        address _resolver = Bonds[bondhash]._resolver;
        return _resolver;
    }

    /**
     * @dev check if a bond is registered
     * @param bondhash hash of bond to query
     * @return true or false
     */
    function recordExists(bytes32 bondhash) public view returns (bool) {
        return NAMES.owner(Bonds[bondhash]._cation) != address(0x0);
    }

    /**
     * @dev check if an address is set as operator
     * @param _cation cation of bond to query
     * @param operator operator to check
     * @return true or false
     */
    function isApprovedForAll(bytes32 _cation, address operator) external view returns (bool) {
        address __cation = NAMES.owner(_cation);
        return Operators[__cation][operator];
    }

    /**
     * @dev : withdraw ether to Dev, anyone can trigger
     */
    function withdrawEther() external payable {
        (bool ok,) = Dev.call{value: address(this).balance}("");
        require(ok, "ETH_TRANSFER_FAILED");
    }

    /**
     * @dev : to be used in case some tokens get locked in the contract
     * @param token : token to release
     */
    function withdrawToken(address token) external payable {
        iERC20(token).transferFrom(address(this), Dev, iERC20(token).balanceOf(address(this)));
    }
}
