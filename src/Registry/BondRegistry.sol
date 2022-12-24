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
    event NewBond(bytes32 indexed bondhash, bytes32 owner);
    event NewOwner(bytes32 indexed bondhash, bytes32 owner);
    event NewController(bytes32 indexed bondhash, address controller);
    event NewExpiry(bytes32 indexed bondhash, uint expiry);
    event NewRecord(bytes32 indexed bondhash, address resolver);
    event NewResolver(bytes32 indexed bondhash, address resolver);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /// Dev
    address public Dev;

    /// @dev : Bond roothash
    bytes32 public roothash = HELIX2.getRoothash()[1];

    /// @dev : Helix2 Bond struct
    struct Bond {
        mapping(bytes32 => mapping(uint8 => address)) _hooks;     /// Hooks with Rules
        bytes32 _owner;                                           /// Source of Bond (= Owner)
        bytes32 _to;                                              /// Target of Bond
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
        Bonds[0x0]._owner = roothash;
        Bonds[roothash]._owner = roothash;
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

    /// @dev : Modifier to allow Owner or Controller
    modifier isOwnerOrController(bytes32 bondhash) {
        bytes32 __owner = Bonds[bondhash]._owner;
        address _owner = NAMES.owner(__owner);
        require(_owner == msg.sender || Operators[_owner][msg.sender] || msg.sender == Bonds[bondhash]._controller, "NOT_OWNER_OR_CONTROLLER");
        _;
    }

    /**
     * @dev : verify bond belongs to root
     * @param labelhash : hash of bond
     */
    modifier isNew(bytes32 labelhash) {
        bytes32 __owner =  Bonds[keccak256(abi.encodePacked(roothash, labelhash))]._owner;
        address _owner = NAMES.owner(__owner);
        require(_owner == address(0x0), "BOND_EXISTS");
        _;
    }

    /**
     * @dev : verify ownership of bond
     * @param bondhash : hash of bond
     */
    modifier onlyOwner(bytes32 bondhash) {
        bytes32 __owner = Bonds[bondhash]._owner;
        address _owner = NAMES.owner(__owner);
        require(_owner == msg.sender || Operators[_owner][msg.sender], "NOT_OWNER");
        _;
    }

    /**
     * @dev : set owner of a bond
     * @param bondhash : hash of bond
     * @param _owner : new owner
     */
    function setOwner(bytes32 bondhash, bytes32 _owner) external onlyOwner(bondhash) {
        Bonds[bondhash]._owner = _owner;
        emit NewOwner(bondhash, _owner);
    }

    /**
     * @dev : set controller of a bond
     * @param bondhash : hash of bond
     * @param _controller : new controller
     */
    function setController(bytes32 bondhash, address _controller) external isOwnerOrController(bondhash) {
        Bonds[bondhash]._controller = _controller;
        emit NewController(bondhash, _controller);
    }

    /**
     * @dev : set resolver for a bond
     * @param bondhash : hash of bond
     * @param _resolver : new resolver
     */
    function setResolver(bytes32 bondhash, address _resolver) external isOwnerOrController(bondhash) {
        Bonds[bondhash]._resolver = _resolver;
        emit NewResolver(bondhash, _resolver);
    }

    /**
     * @dev : set expiry for a bond
     * @param bondhash : hash of bond
     * @param _expiry : new expiry
     */
    function setExpiry(bytes32 bondhash, uint _expiry) external isOwnerOrController(bondhash) {
        Bonds[bondhash]._expiry = _expiry;
        emit NewExpiry(bondhash, _expiry);
    }

    /**
     * @dev : set record for a bond
     * @param bondhash : hash of bond
     * @param _resolver : new record
     */
    function setRecord(bytes32 bondhash, address _resolver) external isOwnerOrController(bondhash) {
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
     * @dev return owner of a bond
     * @param bondhash hash of bond to query
     * @return hash of owner
     */
    function owner(bytes32 bondhash) public view returns (bytes32) {
        bytes32 __owner = Bonds[bondhash]._owner;
        address _owner = NAMES.owner(__owner);
        if (_owner == address(this)) {
            return roothash;
        }
        return __owner;
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
        return NAMES.owner(Bonds[bondhash]._owner) != address(0x0);
    }

    /**
     * @dev check if an address is set as operator
     * @param _owner owner of bond to query
     * @param operator operator to check
     * @return true or false
     */
    function isApprovedForAll(bytes32 _owner, address operator) external view returns (bool) {
        address __owner = NAMES.owner(_owner);
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
