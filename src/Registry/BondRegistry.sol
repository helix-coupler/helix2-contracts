//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Interface/iBond.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Bond Base
 */
contract BondRegistry is BOND {

    /// @dev : Bond roothash
    bytes32 public constant roothash = keccak256(abi.encodePacked(bytes32(0), keccak256("?")));

    /// @dev : Helix2 Bond struct
    struct Bond {
        mapping(bytes32 => address) _hooks;
        address _from;
        address _to;
        bytes32 _alias;
        address _resolver;
        address _operator;
        bool _secure
    }
    mapping(uint => Bond) public Bonds;
    mapping (address => mapping(address => bool)) Operators;

    /// @dev : expiry records
    mapping (bytes32 => uint) public Expiry;
    /// @dev : controller records
    mapping (bytes32 => mapping(address => bool)) Controllers;

    /**
    * @dev Initialise a new HELIX2 Bonds Registry
    * @notice : grants ownership of '0x0' to contract
    */
    constructor() public {
        /// give ownership of '0x0' and <roothash> to contract
        Bonds[0x0].owner = msg.sender;
        Bonds[roothash].owner = msg.sender;
    }

    /// @dev : Modifier to allow only Controller
    modifier onlyController(bytes32 bondhash) {
        require(Controllers[bondhash][msg.sender], 'NOT_CONTROLLER');
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
     * @dev : set resolver for a bond
     * @param bondhash : hash of bond
     * @param resolver : new resolver
     */
    function setResolver(bytes32 bondhash, address resolver) external onlyOwner(bondhash) {
        Bonds[bondhash].resolver = resolver;
        emit NewResolver(bondhash, resolver);
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
