//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Interface/iPolycule.sol";
import "src/Interface/iName.sol";
import "src/Interface/iHelix2.sol";
import "src/Interface/iERC721.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Polycule Base
 */
abstract contract Helix2Polycules {

    iHELIX2 public HELIX2 = iHELIX2(address(0x0));
    iNAME public NAMES = iNAME(HELIX2.getRegistry()[3]);

    /// @dev : Helix2 Polycule events
    event NewDev(address Dev, address newDev);
    event NewPolycule(bytes32 indexed polyculehash, bytes32 cation);
    event NewCation(bytes32 indexed polyculehash, bytes32 cation);
    event NewTarget(bytes32 indexed polyculehash, bytes32[] anion);
    event NewAlias(bytes32 indexed polyculehash, bytes32 _alias);
    event NewController(bytes32 indexed polyculehash, address controller);
    event NewExpiry(bytes32 indexed polyculehash, uint expiry);
    event NewRecord(bytes32 indexed polyculehash, address resolver);
    event NewResolver(bytes32 indexed polyculehash, address resolver);
    event ApprovalForAll(address indexed cation, address indexed operator, bool approved);
    
    /// Dev
    address public Dev;

    /// @dev : Polycule roothash
    bytes32 public roothash = HELIX2.getRoothash()[3];

    /// @dev : Helix2 POLYCULE struct
    struct Polycule {
        mapping(bytes32 => mapping(uint8 => address[])) _hooks;   /// Hooks (ordered list) with Rules
        bytes32 _cation;                                          /// Source of Polycule (= Owner)
        bytes32[] _anion;                                         /// Targets of Polycule (ordered list)
        bytes32 _alias;                                           /// Hash of Polycule
        address _resolver;                                        /// Resolver of Polycule
        address _controller;                                      /// Controller of Polycule
        bool[] _secure;                                           /// Mutuality Flags (ordered list)
        uint _expiry;                                             /// Expiry of Polycule
    }
    mapping (bytes32 => Polycule) public Polycules;
    mapping (address => mapping(address => bool)) Operators;

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
        require(msg.sender == Polycules[polyculehash]._controller, 'NOT_CONTROLLER');
        _;
    }

    /// @dev : Modifier to allow Cation or Controller
    modifier isCationOrController(bytes32 polyculehash) {
        bytes32 __cation = Polycules[polyculehash]._cation;
        address _cation = NAMES.owner(__cation);
        require(_cation == msg.sender || Operators[_cation][msg.sender] || msg.sender == Polycules[polyculehash]._controller, "NOT_OWNER_OR_CONTROLLER");
        _;
    }

    /**
     * @dev : verify polycule belongs to root
     * @param labelhash : hash of polycule
     */
    modifier isNew(bytes32 labelhash) {
        bytes32 __cation =  Polycules[keccak256(abi.encodePacked(roothash, labelhash))]._cation;
        address _cation = NAMES.owner(__cation);
        require(_cation == address(0x0), "POLYCULE_EXISTS");
        _;
    }

    /**
     * @dev : verify ownership of polycule
     * @param polyculehash : hash of polycule
     */
    modifier onlyCation(bytes32 polyculehash) {
        bytes32 __cation = Polycules[polyculehash]._cation;
        address _cation = NAMES.owner(__cation);
        require(_cation == msg.sender || Operators[_cation][msg.sender], "NOT_OWNER");
        _;
    }

    /**
     * @dev : set cation of a polycule
     * @param polyculehash : hash of polycule
     * @param _cation : new cation
     */
    function setCation(bytes32 polyculehash, bytes32 _cation) external onlyCation(polyculehash) {
        Polycules[polyculehash]._cation = _cation;
        emit NewCation(polyculehash, _cation);
    }


    /**
     * @dev : set new anion of a polycule
     * @param polyculehash : hash of anions
     * @param _anion : address of anion
     */
    function setTarget(bytes32 polyculehash, bytes32[] calldata _anion) external isCationOrController(polyculehash) {
        Polycules[polyculehash]._anion = _anion;
        emit NewTarget(polyculehash, _anion);
    }

    /**
     * @dev : set new alias for polycule
     * @param polyculehash : hash of polycule
     * @param _alias : bash of alias
     */
    function setAlias(bytes32 polyculehash, bytes32 _alias) external isCationOrController(polyculehash) {
        Polycules[polyculehash]._alias = _alias;
        emit NewAlias(polyculehash, _alias);
    }

    /**
     * @dev : set controller of a polycule
     * @param polyculehash : hash of polycule
     * @param _controller : new controller
     */
    function setController(bytes32 polyculehash, address _controller) external isCationOrController(polyculehash) {
        Polycules[polyculehash]._controller = _controller;
        emit NewController(polyculehash, _controller);
    }

    /**
     * @dev : set resolver for a polycule
     * @param polyculehash : hash of polycule
     * @param _resolver : new resolver
     */
    function setResolver(bytes32 polyculehash, address _resolver) external isCationOrController(polyculehash) {
        Polycules[polyculehash]._resolver = _resolver;
        emit NewResolver(polyculehash, _resolver);
    }

    /**
     * @dev : set expiry for a polycule
     * @param polyculehash : hash of polycule
     * @param _expiry : new expiry
     */
    function setExpiry(bytes32 polyculehash, uint _expiry) external isCationOrController(polyculehash) {
        Polycules[polyculehash]._expiry = _expiry;
        emit NewExpiry(polyculehash, _expiry);
    }

    /**
     * @dev : set record for a polycule
     * @param polyculehash : hash of polycule
     * @param _resolver : new record
     */
    function setRecord(bytes32 polyculehash, address _resolver) external isCationOrController(polyculehash) {
        Polycules[polyculehash]._resolver = _resolver;
        emit NewRecord(polyculehash, _resolver);
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
     * @param polyculehash hash of polycule to query
     * @return hash of cation
     */
    function cation(bytes32 polyculehash) public view returns (bytes32) {
        bytes32 __cation = Polycules[polyculehash]._cation;
        address _cation = NAMES.owner(__cation);
        if (_cation == address(this)) {
            return roothash;
        }
        return __cation;
    }

    /**
     * @dev return controller of a polycule
     * @param polyculehash hash of polycule to query
     * @return address of controller
     */
    function controller(bytes32 polyculehash) public view returns (address) {
        address _controller = Polycules[polyculehash]._controller;
        return _controller;
    }

    /**
     * @dev shows mutuality state of a polycule
     * @param polyculehash hash of polycule to query
     * @return mutuality state of the polycule
     */
    function secure(bytes32 polyculehash) public view returns (bool[] memory) {
        bool[] memory _secure = Polycules[polyculehash]._secure;
        return _secure;
    }

    /**
     * @dev return anion of a polycule
     * @param polyculehash hash of polycule to query
     * @return hash of anion
     */
    function anion(bytes32 polyculehash) public view returns (bytes32[] memory) {
        bytes32[] memory _anion = Polycules[polyculehash]._anion;
        return _anion;
    }

    /**
     * @dev return expiry of a polycule
     * @param polyculehash hash of polycule to query
     * @return expiry
     */
    function expiry(bytes32 polyculehash) public view returns (uint) {
        uint _expiry = Polycules[polyculehash]._expiry;
        return _expiry;
    }   

    /**
     * @dev return resolver of a polycule
     * @param polyculehash hash of polycule to query
     * @return address of resolver
     */
    function resolver(bytes32 polyculehash) public view returns (address) {
        address _resolver = Polycules[polyculehash]._resolver;
        return _resolver;
    }

    /**
     * @dev check if a polycule is registered
     * @param polyculehash hash of polycule to query
     * @return true or false
     */
    function recordExists(bytes32 polyculehash) public view returns (bool) {
        return NAMES.owner(Polycules[polyculehash]._cation) != address(0x0);
    }

    /**
     * @dev check if an address is set as operator
     * @param _cation cation of polycule to query
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