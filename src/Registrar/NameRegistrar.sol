//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Interface/iName.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Name Base
 */
contract NameRegistrar is NameRegistrar {
    /// Dev
    address public Dev;

    /// Name Registry
    iNAME public NAMES;

    /// @dev : Name roothash
    bytes32 public constant roothash = keccak256(abi.encodePacked(bytes32(0), keccak256(".")));

    constructor(address _NameRegistry) public {
        NAMES = iNAME(_NameRegistry);
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
