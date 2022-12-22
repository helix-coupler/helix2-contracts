//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Interface/iPolycule.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Polycule Base
 */
abstract contract Helix2Polycules {
    /// @dev : Helix2 Polycules events
    event NewDev(address Dev, address newDev);
    event NewPolycule(bytes32 indexed polyculehash, address owner);
    event NewOwner(bytes32 indexed polyculehash, address owner);
    event NewController(bytes32 indexed polyculehash, address controller);
    event NewExpiry(bytes32 indexed polyculehash, uint expiry);
    event NewRecord(bytes32 indexed polyculehash, address resolver);
    event NewResolver(bytes32 indexed polyculehash, address resolver);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    /// Dev
    address public Dev;

    /// @dev : Polycule roothash
    bytes32 public constant roothash = keccak256(abi.encodePacked(bytes32(0), keccak256("#")));

    /// @dev : Helix2 POLYCULE struct
    struct Polycule {
        mapping(bytes32 => address[]) _hooks;
        address _owner;
        address[] to;
        bytes32 _alias;
        address _resolver;
        address _controller;
        bool[] secure;
        uint _expiry;
    }
    mapping (bytes32 => Polycule) public Polycules;
    mapping (address => mapping(address => bool)) Operators;

    /**
    * @dev Initialise a new HELIX2 Polycules Registry
    * @notice : grants ownership of '0x0' to contract
    */
    constructor() {
        /// give ownership of '0x0' and <roothash> to Dev
        Polycules[0x0]._owner = msg.sender;
        Polycules[roothash]._owner = msg.sender;
        Dev = msg.sender;
    }

    /// @dev : Modifier to allow only dev
    modifier onlyDev() virtual {
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

    /// @dev : Modifier to allow Owner or Controller
    modifier isOwnerOrController(bytes32 polyculehash) {
        address _owner = Polycules[polyculehash]._owner;
        require(_owner == msg.sender || Operators[_owner][msg.sender] || msg.sender == Polycules[polyculehash]._controller, "NOT_OWNER_OR_CONTROLLER");
        _;
    }

    /**
     * @dev : verify polycule belongs to root
     * @param labelhash : hash of polycule
     */
    modifier isNew(bytes32 labelhash) {
        address _owner =  Polycules[keccak256(abi.encodePacked(roothash, labelhash))]._owner;
        require(_owner == address(0x0), "POLYCULE_EXISTS");
        _;
    }

    /**
     * @dev : verify ownership of polycule
     * @param polyculehash : hash of polycule
     */
    modifier onlyOwner(bytes32 polyculehash) {
        address _owner = Polycules[polyculehash]._owner;
        require(_owner == msg.sender || Operators[_owner][msg.sender], "NOT_OWNER");
        _;
    }

    /**
     * @dev : set owner of a polycule
     * @param polyculehash : hash of polycule
     * @param _owner : new owner
     */
    function setOwner(bytes32 polyculehash, address _owner) external onlyOwner(polyculehash) {
        Polycules[polyculehash]._owner = _owner;
        emit NewOwner(polyculehash, _owner);
    }

    /**
     * @dev : set controller of a polycule
     * @param polyculehash : hash of polycule
     * @param _controller : new controller
     */
    function setController(bytes32 polyculehash, address _controller) external isOwnerOrController(polyculehash) {
        Polycules[polyculehash]._controller = _controller;
        emit NewController(polyculehash, _controller);
    }

    /**
     * @dev : set resolver for a polycule
     * @param polyculehash : hash of polycule
     * @param _resolver : new resolver
     */
    function setResolver(bytes32 polyculehash, address _resolver) external isOwnerOrController(polyculehash) {
        Polycules[polyculehash]._resolver = _resolver;
        emit NewResolver(polyculehash, _resolver);
    }

    /**
     * @dev : set expiry for a polycule
     * @param polyculehash : hash of polycule
     * @param _expiry : new expiry
     */
    function setExpiry(bytes32 polyculehash, uint _expiry) external isOwnerOrController(polyculehash) {
        Polycules[polyculehash]._expiry = _expiry;
        emit NewExpiry(polyculehash, _expiry);
    }

    /**
     * @dev : set record for a polycule
     * @param polyculehash : hash of polycule
     * @param _resolver : new record
     */
    function setRecord(bytes32 polyculehash, address _resolver) external isOwnerOrController(polyculehash) {
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
     * @dev return owner of a polycule
     * @param polyculehash hash of polycule to query
     * @return address of owner
     */
    function owner(bytes32 polyculehash) public view returns (address) {
        address addr = Polycules[polyculehash]._owner;
        if (addr == address(this)) {
            return address(0x0);
        }
        return addr;
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
        return Polycules[polyculehash]._owner != address(0x0);
    }

    /**
     * @dev check if an address is set as operator
     * @param _owner owner of polycule to query
     * @param operator operator to check
     * @return true or false
     */
    function isApprovedForAll(address _owner, address operator) external view returns (bool) {
        return Operators[_owner][operator];
    }

}

