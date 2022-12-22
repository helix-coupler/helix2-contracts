//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Interface/iName.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Name Base
 */
contract NameRegistrar is NameRegistrar {

    /// @dev : Name roothash
    bytes32 public constant roothash = keccak256(abi.encodePacked(bytes32(0), keccak256(".")));

    /// @dev : expiry records
    mapping (bytes32 => uint) public Expiry;
    /// @dev : controller records
    mapping (bytes32 => mapping(address => bool)) Controllers;

    constructor() public {
        
    }

    /// @dev : Modifier to allow only Controller
    modifier onlyController(bytes32 namehash) {
        require(Controllers[namehash][msg.sender], 'NOT_CONTROLLER');
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
     * @dev registers a new name
     * @param labelhash label of name without suffix
     * @param owner owner to set for new name
     * @return hash of new name
     */
    function newName(bytes32 labelhash, address owner) external isNew(labelhash) returns(bytes32) {
        require(nameExpiry[labelhash] < block.timestamp, 'NAME_EXISTS');
        nameExpiry[labelhash] = block.timestamp + registrationPeriod;
        bytes32 namehash = keccak256(abi.encodePacked(roothash, labelhash));
        Names[namehash].owner = owner;
        emit NewName(namehash, owner);
        return namehash;
    }

}
