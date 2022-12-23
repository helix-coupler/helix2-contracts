//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/ERC721.sol";
import "src/Interface/iName.sol";
import "src/Utils/LibString.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Name Base
 */
contract NameRegistrar is ERC721 {
    using LibString for string[];
    using LibString for string;

    /// @dev : Contract metadata
    string public constant name = "Helix2 Name Service";
    string public constant symbol = "HNS";

    /// @dev : Helix2 Name events
    event NewName(bytes32 indexed namehash, address owner);
    event NewOwner(bytes32 indexed namehash, address owner);
    event NewController(bytes32 indexed namehash, address controller);
    event NewExpiry(bytes32 indexed namehash, uint expiry);
    event NewRecord(bytes32 indexed namehash, address resolver);
    event NewResolver(bytes32 indexed namehash, address resolver);

    /// Constants
    mapping (address => mapping(address => bool)) Operators;
    uint256 public defaultLifespan = 7_776_000_000; // default registration duration: 90 days

    /// Name Registry
    iNAME public NAMES;

    /// @dev : Default resolver used by this contract
    address public defaultResolver;

    constructor(address _registry) {
        NAMES = iNAME(_registry);
        Dev = msg.sender;
    }

    /**
     * @dev : verify name belongs to root
     * @param label : label of name
     */
    modifier isNew(string calldata label) {
        address owner =  NAMES.owner(keccak256(abi.encodePacked(roothash[0], keccak256(abi.encodePacked(label)))));
        require(owner == address(0x0), "NAME_EXISTS");
        _;
    }

    /**
     * @dev : verify name belongs to root
     * @param label : label of name
     */
    modifier isLegal(string calldata label) {
        require(bytes(label).length > 10, 'ILLEGAL_LABEL'); /// check for oversized label
        require(!label.existsIn(illegal), 'ILLEGAL_CHARS'); /// check for forbidden characters
        _;
    }

    /**
     * @dev : verify name belongs to root
     * @param label : label of name
     */
    modifier isNotExpired(string calldata label, uint lifespan) {
        bytes32 namehash = keccak256(abi.encodePacked(roothash[0], keccak256(abi.encodePacked(label))));
        require(NAMES.expiry(namehash) < block.timestamp + lifespan, 'NAME_NOT_EXPIRED'); /// check if name has expired
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
     * @dev : sets Default Resolver
     * @param _resolver : resolver address
     */
    function setDefaultResolver(address _resolver) external onlyDev {
        defaultResolver = _resolver;
    }

    /**
     * @dev : sets Default Lifespan
     * @param _lifespan : new default value
     */
    function setDefaultLifespan(uint _lifespan) external onlyDev {
        defaultLifespan = _lifespan;
    }

    /**
     * @dev registers a new name
     * @param label : label of name without suffix (maxLength = 32)
     * @param owner : owner to set for new name
     * @return hash of new name
     */
    function newName(
        string calldata label, 
        address owner, uint lifespan
    ) external 
      isNew(label)
      isLegal(label)
      isNotExpired(label, lifespan) 
      returns(bytes32) 
    {
        bytes32 namehash = keccak256(abi.encodePacked(roothash[0], keccak256(abi.encodePacked(label))));
        NAMES.setOwner(namehash, owner);                        /// set new owner
        NAMES.setExpiry(namehash, block.timestamp + lifespan);  /// set new expiry
        NAMES.setController(namehash, owner);                   /// set new controller
        NAMES.setResolver(namehash, defaultResolver);           /// set new resolver
        _ownerOf[uint256(namehash)] = owner; // change ownership record
        unchecked {                          // update balances
            _balanceOf[owner]++;
        }
        emit NewName(namehash, owner);
        return namehash;
    }

}
