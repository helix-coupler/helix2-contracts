//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/interface/iName.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Name Base
 */
abstract contract Name is HELIX2 {

    /// Helix2 Name struct
    struct Name {
        address owner;
        address resolver;
    }
    mapping(uint => Name) public Names;
    mapping (address => mapping(address => bool)) Controllers;

     /**
     * @dev : Initialise a new HELIX2 Names Registry
     * @notice : grants ownership of '0x0' to contract
     */
    constructor() public {
        /// give ownership of '0x0' and <roothash> to contract
        Names[0x0].owner = msg.sender;
        Names[roothash].owner = msg.sender;
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
        require(owner == msg.sender || Controllers[owner][msg.sender], "NOT_OWNER");
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
     * @dev : set resolver for a name
     * @param namehash : hash of name
     * @param resolver : new resolver
     */
    function setResolver(bytes32 namehash, address resolver) external onlyOwner(namehash) {
        Names[namehash].resolver = resolver;
        emit NewResolver(namehash, resolver);
    }

    /**
     * @dev : set controller for a name
     * @param controller : new controller
     * @param approved : state to set
     */
    function setApprovalForAll(address controller, bool approved) external onlyOwner(namehash) {
        Controllers[msg.sender][controller] = approved;
        emit ApprovalForAll(msg.sender, controller, approved);
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
     * @dev check if an address is set as controller
     * @param owner owner of name to query
     * @param controller controller to check
     * @return true or false
     */
    function isApprovedForAll(address owner, address controller) external view returns (bool) {
        return Controllers[owner][controller];
    }

    /**
     * @dev registers a new name
     * @param labelhash label of name without suffix
     * @param owner owner to set for new name
     * @return hash of new name
     */
    function newName(bytes32 labelhash, address owner) external isNew(labelhash) returns(bytes32) {
        bytes32 namehash = keccak256(abi.encodePacked(roothash, labelhash));
        Names[namehash].owner = owner;
        emit NewName(namehash, owner);
        return namehash;
    }
}