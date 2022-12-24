//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/ERC721.sol";
import "src/Interface/iPolycule.sol";
import "src/Utils/LibString.sol";
import "src/Interface/iName.sol";
import "src/Interface/iHelix2.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Polycule Base
 */
contract PolyculeRegistrar is ERC721 {
    using LibString for string[];
    using LibString for string;

    iHELIX2 public HELIX2 = iHELIX2(address(0x0));
    iNAME public NAMES = iNAME(HELIX2.getRegistry()[3]);

    /// @dev : Contract metadata
    string public constant polycule = "Helix2 Polycule Service";
    string public constant symbol = "HPS";

    /// @dev : Helix2 Polycule events
    event NewPolycule(bytes32 indexed polyculehash, bytes32 owner);
    event NewOwner(bytes32 indexed polyculehash, bytes32 owner);
    event NewExpiry(bytes32 indexed polyculehash, uint expiry);
    event NewRecord(bytes32 indexed polyculehash, address resolver);
    event NewResolver(bytes32 indexed polyculehash, address resolver);
    event NewController(bytes32 indexed polyculehash, address controller);

    /// Constants
    mapping (address => mapping(address => bool)) Operators;
    uint256 public defaultLifespan = 7_776_000_000;    // default registration duration: 90 days
    uint256 public basePrice = HELIX2.getPrices()[3];  // default base price

    /// Polycule Registry
    iPOLYCULE public POLYCULES = iPOLYCULE(address(0x0));

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
        bytes32 _owner =  POLYCULES.owner(keccak256(abi.encodePacked(roothash[3], keccak256(abi.encodePacked(label)))));
        address owner = NAMES.owner(_owner);
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
    modifier isNotExpired(string calldata label) {
        bytes32 polyculehash = keccak256(abi.encodePacked(roothash[3], keccak256(abi.encodePacked(label))));
        require(POLYCULES.expiry(polyculehash) < block.timestamp, 'POLYCULE_NOT_EXPIRED'); /// check if polycule has expired
        _;
    }

    /**
     * @dev : verify ownership of polycule
     * @param polyculehash : hash of polycule
     */
    modifier onlyOwner(bytes32 polyculehash) {
        bytes32 _owner = POLYCULES.owner(polyculehash);
        address owner = NAMES.owner(_owner);
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
     * @param lifespan : duration of registration
     * @return hash of new polycule
     */
    function newPolycule(
        string calldata label, 
        bytes32 owner, 
        uint lifespan
    ) external
      payable 
      isNew(label)
      isLegal(label)
      isNotExpired(label) 
      returns(bytes32) 
    {
        address _owner = NAMES.owner(owner);
        require(msg.value >= basePrice, 'INSUFFICIENT_ETHER');
        bytes32 polyculehash = keccak256(abi.encodePacked(roothash[3], keccak256(abi.encodePacked(label))));
        POLYCULES.setOwner(polyculehash, owner);                        /// set new owner
        POLYCULES.setExpiry(polyculehash, block.timestamp + lifespan);  /// set new expiry
        POLYCULES.setController(polyculehash, _owner);                  /// set new controller
        POLYCULES.setResolver(polyculehash, defaultResolver);           /// set new resolver
        _ownerOf[uint256(polyculehash)] = _owner; // change ownership record
        unchecked {                               // update balances
            _balanceOf[_owner]++;
        }
        emit NewPolycule(polyculehash, owner);
        return polyculehash;
    }

}
