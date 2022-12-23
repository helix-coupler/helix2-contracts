//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/ERC721.sol";
import "src/Interface/iPolycule.sol";
import "src/Utils/LibString.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Polycule Base
 */
contract PolyculeRegistrar is ERC721 {
    using LibString for string[];
    using LibString for string;

    /// @dev : Contract metadata
    string public constant polycule = "Helix2 Polycule Service";
    string public constant symbol = "HPS";

    /// @dev : Helix2 Polycule events
    event NewPolycule(bytes32 indexed polyculehash, address owner);
    event NewOwner(bytes32 indexed polyculehash, address owner);
    event NewController(bytes32 indexed polyculehash, address controller);
    event NewExpiry(bytes32 indexed polyculehash, uint expiry);
    event NewRecord(bytes32 indexed polyculehash, address resolver);
    event NewResolver(bytes32 indexed polyculehash, address resolver);

    /// Constants
    mapping (address => mapping(address => bool)) Operators;
    uint256 public defaultLifespan = 7_776_000_000; // default registration duration: 90 days

    /// Polycule Registry
    iPOLYCULE public POLYCULES;

    /// @dev : Default resolver used by this contract
    address public defaultResolver;

    constructor(address _registry) {
        POLYCULES = iPOLYCULE(_registry);
        Dev = msg.sender;
    }

    /**
     * @dev : verify polycule belongs to root
     * @param label : label of polycule
     */
    modifier isNew(string calldata label) {
        address owner =  POLYCULES.owner(keccak256(abi.encodePacked(roothash[0], keccak256(abi.encodePacked(label)))));
        require(owner == address(0x0), "POLYCULE_EXISTS");
        _;
    }

    /**
     * @dev : verify polycule belongs to root
     * @param label : label of polycule
     */
    modifier isLegal(string calldata label) {
        require(bytes(label).length > sizes[3], 'ILLEGAL_LABEL'); /// check for oversized label
        require(!label.existsIn(illegalBlocks), 'ILLEGAL_CHARS'); /// check for forbidden characters
        _;
    }

    /**
     * @dev : verify polycule belongs to root
     * @param label : label of polycule
     */
    modifier isNotExpired(string calldata label, uint lifespan) {
        bytes32 polyculehash = keccak256(abi.encodePacked(roothash[0], keccak256(abi.encodePacked(label))));
        require(POLYCULES.expiry(polyculehash) < block.timestamp + lifespan, 'POLYCULE_NOT_EXPIRED'); /// check if polycule has expired
        _;
    }

    /**
     * @dev : verify ownership of polycule
     * @param polyculehash : hash of polycule
     */
    modifier onlyOwner(bytes32 polyculehash) {
        address owner = POLYCULES.owner(polyculehash);
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
     * @dev registers a new polycule
     * @param label : label of polycule without suffix (maxLength = 32)
     * @param owner : owner to set for new polycule
     * @return hash of new polycule
     */
    function newPolycule(
        string calldata label, 
        address owner, uint lifespan
    ) external 
      isNew(label)
      isLegal(label)
      isNotExpired(label, lifespan) 
      returns(bytes32) 
    {
        bytes32 polyculehash = keccak256(abi.encodePacked(roothash[0], keccak256(abi.encodePacked(label))));
        POLYCULES.setOwner(polyculehash, owner);                        /// set new owner
        POLYCULES.setExpiry(polyculehash, block.timestamp + lifespan);  /// set new expiry
        POLYCULES.setController(polyculehash, owner);                   /// set new controller
        POLYCULES.setResolver(polyculehash, defaultResolver);           /// set new resolver
        _ownerOf[uint256(polyculehash)] = owner; // change ownership record
        unchecked {                          // update balances
            _balanceOf[owner]++;
        }
        emit NewPolycule(polyculehash, owner);
        return polyculehash;
    }

}
