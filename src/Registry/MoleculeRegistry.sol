//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Interface/iMolecule.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Molecule Base
 */
contract MoleculeRegistry is MOLECULES {
    /// Dev
    address public Dev;

    /// @dev : Molecule roothash
    bytes32 public constant roothash = keccak256(abi.encodePacked(bytes32(0), keccak256("!")));

    /// @dev : Helix2 MOLECULE struct
    struct Molecule {
        mapping(bytes32 => address) _hooks;
        address from;
        address[] to;
        bytes32 alias;
        address resolver;
        address controller;
        bool secure;
        uint expiry;
    }
    mapping(uint => Molecule) public Molecules;
    mapping (address => mapping(address => bool)) Operators;

    /**
    * @dev Initialise a new HELIX2 Molecules Registry
    * @notice : grants ownership of '0x0' to contract
    */
    constructor() public {
        /// give ownership of '0x0' and <roothash> to Dev
        Molecules[0x0].owner = msg.sender;
        Molecules[roothash].owner = msg.sender;
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
        require(Molecules[moleculehash].controller, 'NOT_CONTROLLER');
        _;
    }

    /// @dev : Modifier to allow Owner or Controller
    modifier isOwnerOrController(bytes32 moleculehash) {
        address owner = Molecules[moleculehash].owner;
        require(owner == msg.sender || Operators[owner][msg.sender] || Molecules[moleculehash].controller, "NOT_OWNER_OR_CONTROLLER");
        _;
    }

    /**
     * @dev : verify molecule belongs to root
     * @param labelhash : hash of molecule
     */
    modifier isNew(bytes32 labelhash) {
        address owner =  Molecules[keccak256(abi.encodePacked(roothash, labelhash))].owner;
        require(owner == address(0x0), "MOLECULE_EXISTS");
        _;
    }

    /**
     * @dev : verify ownership of molecule
     * @param moleculehash : hash of molecule
     */
    modifier onlyOwner(bytes32 moleculehash) {
        address owner = Molecules[moleculehash].owner;
        require(owner == msg.sender || Operators[owner][msg.sender], "NOT_OWNER");
        _;
    }

    /**
     * @dev : set owner of a molecule
     * @param moleculehash : hash of molecule
     * @param owner : new owner
     */
    function setOwner(bytes32 moleculehash, address owner) external onlyOwner(moleculehash) {
        Molecules[moleculehash].owner = owner;
        emit NewOwner(moleculehash, owner);
    }

    /**
     * @dev : set controller of a molecule
     * @param moleculehash : hash of molecule
     * @param controller : new controller
     */
    function setController(bytes32 moleculehash, address controller) external isOwnerOrController(moleculehash) {
        Molecules[moleculehash].controller = controller;
        emit NewController(moleculehash, controller);
    }

    /**
     * @dev : set resolver for a molecule
     * @param moleculehash : hash of molecule
     * @param resolver : new resolver
     */
    function setResolver(bytes32 moleculehash, address resolver) external isOwnerOrController(moleculehash) {
        Molecules[moleculehash].resolver = resolver;
        emit NewResolver(moleculehash, resolver);
    }

    /**
     * @dev : set resolver for a molecule
     * @param moleculehash : hash of molecule
     * @param expiry : new expiry
     */
    function setExpiry(bytes32 moleculehash, uint expiry) external isOwnerOrController(moleculehash) {
        Molecules[moleculehash].expiry = expiry;
        emit NewExpiry(moleculehash, expiry);
    }

    /**
     * @dev : set record for a molecule
     * @param moleculehash : hash of molecule
     * @param expiry : new expiry
     */
    function setRecord(bytes32 moleculehash, address resolver) external isOwnerOrController(moleculehash) {
        Molecules[moleculehash].resolver = resolver;
        emit NewRecord(moleculehash, resolver);
    }

    /**
     * @dev : set operator for a molecule
     * @param operator : new operator
     * @param approved : state to set
     */
    function setApprovalForAll(address operator, bool approved) external onlyOwner(moleculehash) {
        Operators[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev return owner of a molecule
     * @param moleculehash hash of molecule to query
     * @return address of owner
     */
    function owner(bytes32 moleculehash) public view returns (address) {
        address addr = Molecules[moleculehash].owner;
        if (addr == address(this)) {
            return address(0x0);
        }
        return addr;
    }

    /**
     * @dev return resolver of a molecule
     * @param moleculehash hash of molecule to query
     * @return address of resolver
     */
    function resolver(bytes32 moleculehash) public view returns (address) {
        address resolver = Molecules[moleculehash].resolver;
        return resolver;
    }

    /**
     * @dev check if a molecule is registered
     * @param moleculehash hash of molecule to query
     * @return true or false
     */
    function recordExists(bytes32 moleculehash) public view returns (bool) {
        return Molecules[moleculehash].owner != address(0x0);
    }

    /**
     * @dev check if an address is set as operator
     * @param owner owner of molecule to query
     * @param operator operator to check
     * @return true or false
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return Operators[owner][operator];
    }

}
