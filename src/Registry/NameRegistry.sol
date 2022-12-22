//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Interface/iName.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Name Base
 */
contract NameRegistry is NAMES {
    /// Dev
    address public Dev;

    /// @dev : Name roothash
    bytes32 public constant roothash = keccak256(abi.encodePacked(bytes32(0), keccak256(".")));

    /// @dev : Helix2 Name struct
    struct Name {
        address owner;
        address resolver;
        address controller;
        uint expiry;
    }
    mapping(uint => Name) public Names;
    mapping (address => mapping(address => bool)) Operators;

    /**
    * @dev : Initialise a new HELIX2 Names Registry
    * @notice : grants ownership of '0x0' to contract
    */
    constructor() public {
        /// give ownership of '0x0' and <roothash> to Dev
        Names[0x0].owner = msg.sender;
        Names[roothash].owner = msg.sender;
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
    modifier onlyController(bytes32 namehash) {
        require(Names[namehash].controller, 'NOT_CONTROLLER');
        _;
    }

    /// @dev : Modifier to allow Owner or Controller
    modifier isOwnerOrController(bytes32 namehash) {
        address owner = Names[namehash].owner;
        require(owner == msg.sender || Operators[owner][msg.sender] || Names[namehash].controller, "NOT_OWNER_OR_CONTROLLER");
        _;
    }

    /**
     * @dev : verify name belongs to root
     * @param labelhash : hash of name
     */
    modifier isNew(bytes32 labelhash) {
        address owner =  Names[keccak256(abi.encodePacked(roothash, labelhash))].owner;
        require(owner == address(0x0), "NAME_EXISTS");
        _;
    }

    /**
     * @dev : verify ownership of name
     * @param namehash : hash of name
     */
    modifier onlyOwner(bytes32 namehash) {
        address owner = Names[namehash].owner;
        require(owner == msg.sender || Operators[owner][msg.sender], "NOT_OWNER");
        _;
    }

    /**
     * @dev : set owner of a name
     * @param namehash : hash of name
     * @param owner : new owner
     */
    function setOwner(bytes32 namehash, address owner) external onlyOwner(namehash) {
        Names[namehash].owner = owner;
        emit NewOwner(namehash, owner);
    }

    /**
     * @dev : set controller of a name
     * @param namehash : hash of name
     * @param controller : new controller
     */
    function setController(bytes32 namehash, address controller) external isOwnerOrController(namehash) {
        Names[namehash].controller = controller;
        emit NewController(namehash, controller);
    }

    /**
     * @dev : set resolver for a name
     * @param namehash : hash of name
     * @param resolver : new resolver
     */
    function setResolver(bytes32 namehash, address resolver) external isOwnerOrController(namehash) {
        Names[namehash].resolver = resolver;
        emit NewResolver(namehash, resolver);
    }

    /**
     * @dev : set resolver for a name
     * @param namehash : hash of name
     * @param expiry : new expiry
     */
    function setExpiry(bytes32 namehash, uint expiry) external isOwnerOrController(namehash) {
        Names[namehash].expiry = expiry;
        emit NewExpiry(namehash, expiry);
    }

    /**
     * @dev : set record for a name
     * @param namehash : hash of name
     * @param expiry : new expiry
     */
    function setRecord(bytes32 namehash, address resolver) external isOwnerOrController(namehash) {
        Names[namehash].resolver = resolver;
        emit NewRecord(namehash, resolver);
    }

    /**
     * @dev : set operator for a name
     * @param operator : new operator
     * @param approved : state to set
     */
    function setApprovalForAll(address operator, bool approved) external onlyOwner(namehash) {
        Operators[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev return owner of a name
     * @param namehash hash of name to query
     * @return address of owner
     */
    function owner(bytes32 namehash) public view returns (address) {
        address addr = Names[namehash].owner;
        if (addr == address(this)) {
            return address(0x0);
        }
        return addr;
    }

    /**
     * @dev return resolver of a name
     * @param namehash hash of name to query
     * @return address of resolver
     */
    function resolver(bytes32 namehash) public view returns (address) {
        address resolver = Names[namehash].resolver;
        return resolver;
    }

    /**
     * @dev check if a name is registered
     * @param namehash hash of name to query
     * @return true or false
     */
    function recordExists(bytes32 namehash) public view returns (bool) {
        return Names[namehash].owner != address(0x0);
    }

    /**
     * @dev check if an address is set as operator
     * @param owner owner of name to query
     * @param operator operator to check
     * @return true or false
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return Operators[owner][operator];
    }

}
