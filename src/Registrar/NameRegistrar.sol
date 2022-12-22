//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Interface/iName.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Name Base
 */
abstract contract NameRegistrar {
    /// @dev : Helix2 Names events
    event NewDev(address Dev, address newDev);
    event NewName(bytes32 indexed namehash, address owner);
    event NewOwner(bytes32 indexed namehash, address owner);
    event NewController(bytes32 indexed namehash, address controller);
    event NewExpiry(bytes32 indexed namehash, uint expiry);
    event NewRecord(bytes32 indexed namehash, address resolver);
    event NewResolver(bytes32 indexed namehash, address resolver);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /// Constants
    mapping (address => mapping(address => bool)) Operators;
    uint256 public registrationPeriod = 90 * 24 * 60 * 60 * 1000; // 90 days

    /// Dev
    address public Dev;

    /// Name Registry
    iNAME public NAMES;

    /// @dev : Name roothash
    bytes32 public constant roothash = keccak256(abi.encodePacked(bytes32(0), keccak256(".")));

    constructor() {
        NAMES = iNAME(address(this));
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

    /**
     * @dev : verify name belongs to root
     * @param labelhash : hash of name
     */
    modifier isNew(bytes32 labelhash) {
        address owner =  NAMES.owner(keccak256(abi.encodePacked(roothash, labelhash)));
        require(owner == address(0x0), "NAME_EXISTS");
        _;
    }

    /**
     * @dev : verify ownership of name
     * @param namehash : hash of name
     */
    modifier onlyOwner(bytes32 namehash) {
        address owner = NAMES.owner(namehash);
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
        bytes32 namehash = keccak256(abi.encodePacked(roothash, labelhash));
        require(NAMES.expiry(namehash) < block.timestamp, 'NAME_EXISTS');
        NAMES.setExpiry(namehash, block.timestamp + registrationPeriod);  
        NAMES.setOwner(namehash, owner);
        emit NewName(namehash, owner);
        return namehash;
    }

}
