//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Interface/iMolecule.sol";
import "src/Interface/iName.sol";
import "src/Interface/iHelix2.sol";
import "src/Interface/iERC721.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Molecule Base
 */
abstract contract Helix2Molecules {

    iHELIX2 public HELIX2 = iHELIX2(address(0x0));
    iNAME public NAMES = iNAME(HELIX2.getRegistry()[2]);

    /// @dev : Helix2 Molecule events
    event NewDev(address Dev, address newDev);
    event NewMolecule(bytes32 indexed moleculehash, bytes32 cation);
    event NewCation(bytes32 indexed moleculehash, bytes32 cation);
    event NewTarget(bytes32 indexed moleculehash, bytes32[] anion);
    event NewAlias(bytes32 indexed moleculehash, bytes32 _alias);
    event NewController(bytes32 indexed moleculehash, address controller);
    event NewExpiry(bytes32 indexed moleculehash, uint expiry);
    event NewRecord(bytes32 indexed moleculehash, address resolver);
    event NewResolver(bytes32 indexed moleculehash, address resolver);
    event ApprovalForAll(address indexed cation, address indexed operator, bool approved);
    
    /// Dev
    address public Dev;

    /// @dev : Molecule roothash
    bytes32 public roothash = HELIX2.getRoothash()[2];

    /// @dev : Helix2 MOLECULE struct
    struct Molecule {
        mapping(bytes32 => mapping(uint8 => address)) _hooks;     /// Hooks with Rules
        bytes32 _cation;                                          /// Source of Molecule (= Owner)
        bytes32[] _anion;                                         /// Targets of Molecule
        bytes32 _alias;                                           /// Hash of Molecule
        address _resolver;                                        /// Resolver of Molecule
        address _controller;                                      /// Controller of Molecule
        bool _secure;                                             /// Mutuality Flag
        uint _expiry;                                             /// Expiry of Molecule
    }
    mapping (bytes32 => Molecule) public Molecules;
    mapping (address => mapping(address => bool)) Operators;

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
        require(msg.sender == Molecules[moleculehash]._controller, 'NOT_CONTROLLER');
        _;
    }

    /// @dev : Modifier to allow Cation or Controller
    modifier isCationOrController(bytes32 moleculehash) {
        bytes32 __owner = Molecules[moleculehash]._cation;
        address _cation = NAMES.owner(__owner);
        require(_cation == msg.sender || Operators[_cation][msg.sender] || msg.sender == Molecules[moleculehash]._controller, "NOT_OWNER_OR_CONTROLLER");
        _;
    }

    /**
     * @dev : verify molecule belongs to root
     * @param labelhash : hash of molecule
     */
    modifier isNew(bytes32 labelhash) {
        bytes32 __owner =  Molecules[keccak256(abi.encodePacked(roothash, labelhash))]._cation;
        address _cation = NAMES.owner(__owner);
        require(_cation == address(0x0), "MOLECULE_EXISTS");
        _;
    }

    /**
     * @dev : verify ownership of molecule
     * @param moleculehash : hash of molecule
     */
    modifier onlyCation(bytes32 moleculehash) {
        bytes32 __owner = Molecules[moleculehash]._cation;
        address _cation = NAMES.owner(__owner);
        require(_cation == msg.sender || Operators[_cation][msg.sender], "NOT_OWNER");
        _;
    }

    /**
     * @dev : set cation of a molecule
     * @param moleculehash : hash of molecule
     * @param _cation : new cation
     */
    function setCation(bytes32 moleculehash, bytes32 _cation) external onlyCation(moleculehash) {
        Molecules[moleculehash]._cation = _cation;
        emit NewCation(moleculehash, _cation);
    }


    /**
     * @dev : set new anion of a polycule
     * @param polyculehash : hash of anions
     * @param _anion : address of anion
     */
    function setTarget(bytes32 polyculehash, bytes32[] calldata _anion) external isCationOrController(polyculehash) {
        Molecules[polyculehash]._anion = _anion;
        emit NewTarget(polyculehash, _anion);
    }

    /**
     * @dev : set new alias for molecule
     * @param moleculehash : hash of molecule
     * @param _alias : bash of alias
     */
    function setAlias(bytes32 moleculehash, bytes32 _alias) external isCationOrController(moleculehash) {
        Molecules[moleculehash]._alias = _alias;
        emit NewAlias(moleculehash, _alias);
    }

    /**
     * @dev : set controller of a molecule
     * @param moleculehash : hash of molecule
     * @param _controller : new controller
     */
    function setController(bytes32 moleculehash, address _controller) external isCationOrController(moleculehash) {
        Molecules[moleculehash]._controller = _controller;
        emit NewController(moleculehash, _controller);
    }

    /**
     * @dev : set resolver for a molecule
     * @param moleculehash : hash of molecule
     * @param _resolver : new resolver
     */
    function setResolver(bytes32 moleculehash, address _resolver) external isCationOrController(moleculehash) {
        Molecules[moleculehash]._resolver = _resolver;
        emit NewResolver(moleculehash, _resolver);
    }

    /**
     * @dev : set expiry for a molecule
     * @param moleculehash : hash of molecule
     * @param _expiry : new expiry
     */
    function setExpiry(bytes32 moleculehash, uint _expiry) external isCationOrController(moleculehash) {
        Molecules[moleculehash]._expiry = _expiry;
        emit NewExpiry(moleculehash, _expiry);
    }

    /**
     * @dev : set record for a molecule
     * @param moleculehash : hash of molecule
     * @param _resolver : new record
     */
    function setRecord(bytes32 moleculehash, address _resolver) external isCationOrController(moleculehash) {
        Molecules[moleculehash]._resolver = _resolver;
        emit NewRecord(moleculehash, _resolver);
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
     * @param moleculehash hash of molecule to query
     * @return hash of cation
     */
    function cation(bytes32 moleculehash) public view returns (bytes32) {
        bytes32 __owner = Molecules[moleculehash]._cation;
        address _cation = NAMES.owner(__owner);
        if (_cation == address(this)) {
            return roothash;
        }
        return __owner;
    }

    /**
     * @dev return controller of a molecule
     * @param moleculehash hash of molecule to query
     * @return address of controller
     */
    function controller(bytes32 moleculehash) public view returns (address) {
        address _controller = Molecules[moleculehash]._controller;
        return _controller;
    }

    /**
     * @dev shows mutuality state of a molecule
     * @param moleculehash hash of molecule to query
     * @return mutuality state of the molecule
     */
    function secure(bytes32 moleculehash) public view returns (bool) {
        bool _secure = Molecules[moleculehash]._secure;
        return _secure;
    }


    /**
     * @dev return anion of a molecule
     * @param moleculehash hash of molecule to query
     * @return hash of anion
     */
    function anion(bytes32 moleculehash) public view returns (bytes32[] memory) {
        bytes32[] memory _anion = Molecules[moleculehash]._anion;
        return _anion;
    }

    /**
     * @dev return expiry of a molecule
     * @param moleculehash hash of molecule to query
     * @return expiry
     */
    function expiry(bytes32 moleculehash) public view returns (uint) {
        uint _expiry = Molecules[moleculehash]._expiry;
        return _expiry;
    }   

    /**
     * @dev return resolver of a molecule
     * @param moleculehash hash of molecule to query
     * @return address of resolver
     */
    function resolver(bytes32 moleculehash) public view returns (address) {
        address _resolver = Molecules[moleculehash]._resolver;
        return _resolver;
    }

    /**
     * @dev check if a molecule is registered
     * @param moleculehash hash of molecule to query
     * @return true or false
     */
    function recordExists(bytes32 moleculehash) public view returns (bool) {
        return NAMES.owner(Molecules[moleculehash]._cation) != address(0x0);
    }

    /**
     * @dev check if an address is set as operator
     * @param _cation cation of molecule to query
     * @param operator operator to check
     * @return true or false
     */
    function isApprovedForAll(bytes32 _cation, address operator) external view returns (bool) {
        address __owner = NAMES.owner(_cation);
        return Operators[__owner][operator];
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
