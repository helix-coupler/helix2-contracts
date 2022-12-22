//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Interface/iBond.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Bond Base
 */
contract BondRegistry is BONDS {
    /// Dev
    address public Dev;

    /// @dev : Bond roothash
    bytes32 public constant roothash = keccak256(abi.encodePacked(bytes32(0), keccak256("?")));

    /// @dev : Helix2 Bond struct
    struct Bond {
        mapping(bytes32 => address) _hooks;
        address from;
        address to;
        bytes32 alias;
        address resolver;
        address controller;
        bool secure
        uint expiry
    }
    mapping(uint => Bond) public Bonds;
    mapping (address => mapping(address => bool)) Operators;

    /**
    * @dev Initialise a new HELIX2 Bonds Registry
    * @notice : grants ownership of '0x0' to contract
    */
    constructor() public {
        /// give ownership of '0x0' and <roothash> to Dev
        Bonds[0x0].owner = msg.sender;
        Bonds[roothash].owner = msg.sender;
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
        require(Bonds[bondhash].controller, 'NOT_CONTROLLER');
        _;
    }

    /// @dev : Modifier to allow Owner or Controller
    modifier isOwnerOrController(bytes32 bondhash) {
        address owner = Bonds[bondhash].owner;
        require(owner == msg.sender || Operators[owner][msg.sender] || Bonds[bondhash].controller, "NOT_OWNER_OR_CONTROLLER");
        _;
    }

    /**
     * @dev : verify bond belongs to root
     * @param labelhash : hash of bond
     */
    modifier isNew(bytes32 labelhash) {
        address owner =  Bonds[keccak256(abi.encodePacked(roothash, labelhash))].owner;
        require(owner == address(0x0), "BOND_EXISTS");
        _;
    }

    /**
     * @dev : verify ownership of bond
     * @param bondhash : hash of bond
     */
    modifier onlyOwner(bytes32 bondhash) {
        address owner = Bonds[bondhash].owner;
        require(owner == msg.sender || Operators[owner][msg.sender], "NOT_OWNER");
        _;
    }

    /**
     * @dev : set owner of a bond
     * @param bondhash : hash of bond
     * @param owner : new owner
     */
    function setOwner(bytes32 bondhash, address owner) external onlyOwner(bondhash) {
        Bonds[bondhash].owner = owner;
        emit NewOwner(bondhash, owner);
    }

    /**
     * @dev : set controller of a bond
     * @param bondhash : hash of bond
     * @param controller : new controller
     */
    function setController(bytes32 bondhash, address controller) external isOwnerOrController(bondhash) {
        Bonds[bondhash].controller = controller;
        emit NewController(bondhash, controller);
    }

    /**
     * @dev : set resolver for a bond
     * @param bondhash : hash of bond
     * @param resolver : new resolver
     */
    function setResolver(bytes32 bondhash, address resolver) external isOwnerOrController(bondhash) {
        Bonds[bondhash].resolver = resolver;
        emit NewResolver(bondhash, resolver);
    }

    /**
     * @dev : set resolver for a bond
     * @param bondhash : hash of bond
     * @param expiry : new expiry
     */
    function setExpiry(bytes32 bondhash, uint expiry) external isOwnerOrController(bondhash) {
        Bonds[bondhash].expiry = expiry;
        emit NewExpiry(bondhash, expiry);
    }

    /**
     * @dev : set record for a bond
     * @param bondhash : hash of bond
     * @param expiry : new expiry
     */
    function setRecord(bytes32 bondhash, address resolver) external isOwnerOrController(bondhash) {
        Bonds[bondhash].resolver = resolver;
        emit NewRecord(bondhash, resolver);
    }

    /**
     * @dev : set operator for a bond
     * @param operator : new operator
     * @param approved : state to set
     */
    function setApprovalForAll(address operator, bool approved) external onlyOwner(bondhash) {
        Operators[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev return owner of a bond
     * @param bondhash hash of bond to query
     * @return address of owner
     */
    function owner(bytes32 bondhash) public view returns (address) {
        address addr = Bonds[bondhash].owner;
        if (addr == address(this)) {
            return address(0x0);
        }
        return addr;
    }

    /**
     * @dev return resolver of a bond
     * @param bondhash hash of bond to query
     * @return address of resolver
     */
    function resolver(bytes32 bondhash) public view returns (address) {
        address resolver = Bonds[bondhash].resolver;
        return resolver;
    }

    /**
     * @dev check if a bond is registered
     * @param bondhash hash of bond to query
     * @return true or false
     */
    function recordExists(bytes32 bondhash) public view returns (bool) {
        return Bonds[bondhash].owner != address(0x0);
    }

    /**
     * @dev check if an address is set as operator
     * @param owner owner of bond to query
     * @param operator operator to check
     * @return true or false
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return Operators[owner][operator];
    }

}
