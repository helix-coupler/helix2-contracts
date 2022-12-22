//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/interface/iMolecule.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Molecule Base
 */
abstract contract Molecule is HELIX2 {
    /// Helix2 MOLECULE struct
    struct Molecule {
        mapping(bytes32 => address) _hooks;
        address _from;
        address[] _to;
        bytes32 _alias;
        address _resolver;
        address _controller;
        bool _secure
    }
    mapping(uint => Molecule) public Molecules;
    mapping (address => mapping(address => bool)) Controllers;

     /**
     * @dev Initialise a new HELIX2 Molecules Registry
     * @notice : grants ownership of '0x0' to contract
     */
    constructor() public {
        /// give ownership of '0x0' and <roothash> to contract
        Molecules[0x0].owner = msg.sender;
        Molecules[roothash].owner = msg.sender;
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
        require(owner == msg.sender || Controllers[owner][msg.sender], "NOT_OWNER");
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
     * @dev : set resolver for a molecule
     * @param moleculehash : hash of molecule
     * @param resolver : new resolver
     */
    function setResolver(bytes32 moleculehash, address resolver) external onlyOwner(moleculehash) {
        Molecules[moleculehash].resolver = resolver;
        emit NewResolver(moleculehash, resolver);
    }

    /**
     * @dev : set controller for a molecule
     * @param controller : new controller
     * @param approved : state to set
     */
    function setApprovalForAll(address controller, bool approved) external onlyOwner(moleculehash) {
        Controllers[msg.sender][controller] = approved;
        emit ApprovalForAll(msg.sender, controller, approved);
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
     * @dev check if an address is set as controller
     * @param owner owner of molecule to query
     * @param controller controller to check
     * @return true or false
     */
    function isApprovedForAll(address owner, address controller) external view returns (bool) {
        return Controllers[owner][controller];
    }

    /**
     * @dev registers a new molecule
     * @param labelhash label of molecule without suffix
     * @param owner owner to set for new molecule
     * @return hash of new molecule
     */
    function newMolecule(bytes32 labelhash, address owner) external isNew(labelhash) returns(bytes32) {
        bytes32 moleculehash = keccak256(abi.encodePacked(roothash, labelhash));
        Molecules[moleculehash].owner = owner;
        emit NewMolecule(moleculehash, owner);
        return moleculehash;
    }
}
