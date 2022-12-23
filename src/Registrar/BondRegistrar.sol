//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/ERC721.sol";
import "src/Interface/iBond.sol";
import "src/Utils/LibString.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Bond Base
 */
contract BondRegistrar is ERC721 {
    using LibString for string[];
    using LibString for string;

    /// @dev : Contract metadata
    string public constant bond = "Helix2 Bond Service";
    string public constant symbol = "HBS";

    /// @dev : Helix2 Bond events
    event NewBond(bytes32 indexed bondhash, address owner);
    event NewOwner(bytes32 indexed bondhash, address owner);
    event NewController(bytes32 indexed bondhash, address controller);
    event NewExpiry(bytes32 indexed bondhash, uint expiry);
    event NewRecord(bytes32 indexed bondhash, address resolver);
    event NewResolver(bytes32 indexed bondhash, address resolver);

    /// Constants
    mapping (address => mapping(address => bool)) Operators;
    uint256 public defaultLifespan = 7_776_000_000; // default registration duration: 90 days

    /// Bond Registry
    iBOND public BONDS;

    /// @dev : Default resolver used by this contract
    address public defaultResolver;

    constructor(address _registry) {
        BONDS = iBOND(_registry);
        Dev = msg.sender;
    }

    /**
     * @dev : verify bond belongs to root
     * @param label : label of bond
     */
    modifier isNew(string calldata label) {
        address owner =  BONDS.owner(keccak256(abi.encodePacked(roothash[0], keccak256(abi.encodePacked(label)))));
        require(owner == address(0x0), "BOND_EXISTS");
        _;
    }

    /**
     * @dev : verify bond belongs to root
     * @param label : label of bond
     */
    modifier isLegal(string calldata label) {
        require(bytes(label).length > sizes[1], 'ILLEGAL_LABEL'); /// check for oversized label
        require(!label.existsIn(illegalBlocks), 'ILLEGAL_CHARS'); /// check for forbidden characters
        _;
    }

    /**
     * @dev : verify bond belongs to root
     * @param label : label of bond
     */
    modifier isNotExpired(string calldata label, uint lifespan) {
        bytes32 bondhash = keccak256(abi.encodePacked(roothash[0], keccak256(abi.encodePacked(label))));
        require(BONDS.expiry(bondhash) < block.timestamp + lifespan, 'BOND_NOT_EXPIRED'); /// check if bond has expired
        _;
    }

    /**
     * @dev : verify ownership of bond
     * @param bondhash : hash of bond
     */
    modifier onlyOwner(bytes32 bondhash) {
        address owner = BONDS.owner(bondhash);
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
     * @dev registers a new bond
     * @param label : label of bond without suffix (maxLength = 32)
     * @param owner : owner to set for new bond
     * @return hash of new bond
     */
    function newBond(
        string calldata label, 
        address owner, uint lifespan
    ) external 
      isNew(label)
      isLegal(label)
      isNotExpired(label, lifespan) 
      returns(bytes32) 
    {
        bytes32 bondhash = keccak256(abi.encodePacked(roothash[0], keccak256(abi.encodePacked(label))));
        BONDS.setOwner(bondhash, owner);                        /// set new owner
        BONDS.setExpiry(bondhash, block.timestamp + lifespan);  /// set new expiry
        BONDS.setController(bondhash, owner);                   /// set new controller
        BONDS.setResolver(bondhash, defaultResolver);           /// set new resolver
        _ownerOf[uint256(bondhash)] = owner; // change ownership record
        unchecked {                          // update balances
            _balanceOf[owner]++;
        }
        emit NewBond(bondhash, owner);
        return bondhash;
    }

}
