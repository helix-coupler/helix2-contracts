//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Name Base
 */
abstract contract Name is HELIX2 {
    /// Helix2 Name struct
    struct NAME {
        address owner;
        address resolver;
    }
    mapping(uint => NAME) public NAMES;
    mapping (address => mapping(address => bool)) operators;

    /**
     * @dev : verify ownership of name
     * @param name : namehash of name
     */
    modifier onlyOwner(bytes32 name) {
        require(msg.sender == HELIX2.owner(name), "NOT_OWNER");
        _;
    }

    /**
     * @dev : register a name
     * @param namehash : namehash of name
     * @param owner : namehash of name
     */
    function name(bytes32 namehash, address owner) public onlyOwner(namehash) {
        ENS.setSubnodeOwner(namehash, owner);
    }
}