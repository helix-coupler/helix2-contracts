//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Interface/iPolycule.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Polycule Base
 */
contract PolyculeRegistry is POLYCULE {

    /// @dev : Polycule roothash
    bytes32 public constant roothash = keccak256(abi.encodePacked(bytes32(0), keccak256("#")));

    /// @dev : Helix2 POLYCULE struct
    struct Polycule {
        mapping(bytes32 => address[]) _hooks;
        address _from;
        address[] _to;
        bytes32 _alias;
        address _resolver;
        address _operator;
        bool[] _secure
    }
    mapping(uint => Polycule) public Polycules;
    mapping (address => mapping(address => bool)) Operators;

    /// @dev : expiry records
    mapping (bytes32 => uint) public Expiry;
    /// @dev : controller records
    mapping (bytes32 => mapping(address => bool)) Controllers;

    /**
    * @dev Initialise a new HELIX2 Polycules Registry
    * @notice : grants ownership of '0x0' to contract
    */
    constructor() public {
        /// give ownership of '0x0' and <roothash> to contract
        Polycules[0x0].owner = msg.sender;
        Polycules[roothash].owner = msg.sender;
    }

    /// @dev : Modifier to allow only Controller
    modifier onlyController(bytes32 polyculehash) {
        require(Controllers[polyculehash][msg.sender], 'NOT_CONTROLLER');
        _;
    }

    /**
     * @dev : verify polycule belongs to root
     * @param labelhash : hash of polycule
     */
    modifier isNew(bytes32 labelhash) {
        address owner =  Polycules[keccak256(abi.encodePacked(roothash, labelhash))].owner;
        require(owner == address(0x0), "POLYCULE_EXISTS");
        _;
    }

    /**
     * @dev : verify ownership of polycule
     * @param polyculehash : hash of polycule
     */
    modifier onlyOwner(bytes32 polyculehash) {
        address owner = Polycules[polyculehash].owner;
        require(owner == msg.sender || Operators[owner][msg.sender], "NOT_OWNER");
        _;
    }

    /**
     * @dev : set owner of a polycule
     * @param polyculehash : hash of polycule
     * @param owner : new owner
     */
    function setOwner(bytes32 polyculehash, address owner) external onlyOwner(polyculehash) {
        Polycules[polyculehash].owner = owner;
        emit NewOwner(polyculehash, owner);
    }

    /**
     * @dev : set resolver for a polycule
     * @param polyculehash : hash of polycule
     * @param resolver : new resolver
     */
    function setResolver(bytes32 polyculehash, address resolver) external onlyOwner(polyculehash) {
        Polycules[polyculehash].resolver = resolver;
        emit NewResolver(polyculehash, resolver);
    }

    /**
     * @dev : set operator for a polycule
     * @param operator : new operator
     * @param approved : state to set
     */
    function setApprovalForAll(address operator, bool approved) external onlyOwner(polyculehash) {
        Operators[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev return owner of a polycule
     * @param polyculehash hash of polycule to query
     * @return address of owner
     */
    function owner(bytes32 polyculehash) public view returns (address) {
        address addr = Polycules[polyculehash].owner;
        if (addr == address(this)) {
            return address(0x0);
        }
        return addr;
    }

    /**
     * @dev return resolver of a polycule
     * @param polyculehash hash of polycule to query
     * @return address of resolver
     */
    function resolver(bytes32 polyculehash) public view returns (address) {
        address resolver = Polycules[polyculehash].resolver;
        return resolver;
    }

    /**
     * @dev check if a polycule is registered
     * @param polyculehash hash of polycule to query
     * @return true or false
     */
    function recordExists(bytes32 polyculehash) public view returns (bool) {
        return Polycules[polyculehash].owner != address(0x0);
    }

    /**
     * @dev check if an address is set as operator
     * @param owner owner of polycule to query
     * @param operator operator to check
     * @return true or false
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return Operators[owner][operator];
    }

}

