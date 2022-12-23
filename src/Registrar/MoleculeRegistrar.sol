//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/ERC721.sol";
import "src/Interface/iMolecule.sol";
import "src/Utils/LibString.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Molecule Base
 */
contract MoleculeRegistrar is ERC721 {
    using LibString for string[];
    using LibString for string;

    /// @dev : Contract metadata
    string public constant molecule = "Helix2 Molecule Service";
    string public constant symbol = "HMS";

    /// @dev : Helix2 Molecule events
    event NewMolecule(bytes32 indexed moleculehash, address owner);
    event NewOwner(bytes32 indexed moleculehash, address owner);
    event NewController(bytes32 indexed moleculehash, address controller);
    event NewExpiry(bytes32 indexed moleculehash, uint expiry);
    event NewRecord(bytes32 indexed moleculehash, address resolver);
    event NewResolver(bytes32 indexed moleculehash, address resolver);

    /// Constants
    mapping (address => mapping(address => bool)) Operators;
    uint256 public defaultLifespan = 7_776_000_000; // default registration duration: 90 days

    /// Molecule Registry
    iMOLECULE public MOLECULES;

    /// @dev : Default resolver used by this contract
    address public defaultResolver;

    constructor(address _registry) {
        MOLECULES = iMOLECULE(_registry);
        Dev = msg.sender;
    }

    /**
     * @dev : verify molecule belongs to root
     * @param label : label of molecule
     */
    modifier isNew(string calldata label) {
        address owner =  MOLECULES.owner(keccak256(abi.encodePacked(roothash[0], keccak256(abi.encodePacked(label)))));
        require(owner == address(0x0), "MOLECULE_EXISTS");
        _;
    }

    /**
     * @dev : verify molecule belongs to root
     * @param label : label of molecule
     */
    modifier isLegal(string calldata label) {
        require(bytes(label).length > sizes[2], 'ILLEGAL_LABEL'); /// check for oversized label
        require(!label.existsIn(illegalBlocks), 'ILLEGAL_CHARS'); /// check for forbidden characters
        _;
    }

    /**
     * @dev : verify molecule belongs to root
     * @param label : label of molecule
     */
    modifier isNotExpired(string calldata label, uint lifespan) {
        bytes32 moleculehash = keccak256(abi.encodePacked(roothash[0], keccak256(abi.encodePacked(label))));
        require(MOLECULES.expiry(moleculehash) < block.timestamp + lifespan, 'MOLECULE_NOT_EXPIRED'); /// check if molecule has expired
        _;
    }

    /**
     * @dev : verify ownership of molecule
     * @param moleculehash : hash of molecule
     */
    modifier onlyOwner(bytes32 moleculehash) {
        address owner = MOLECULES.owner(moleculehash);
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
     * @dev registers a new molecule
     * @param label : label of molecule without suffix (maxLength = 32)
     * @param owner : owner to set for new molecule
     * @return hash of new molecule
     */
    function newMolecule(
        string calldata label, 
        address owner, uint lifespan
    ) external 
      isNew(label)
      isLegal(label)
      isNotExpired(label, lifespan) 
      returns(bytes32) 
    {
        bytes32 moleculehash = keccak256(abi.encodePacked(roothash[0], keccak256(abi.encodePacked(label))));
        MOLECULES.setOwner(moleculehash, owner);                        /// set new owner
        MOLECULES.setExpiry(moleculehash, block.timestamp + lifespan);  /// set new expiry
        MOLECULES.setController(moleculehash, owner);                   /// set new controller
        MOLECULES.setResolver(moleculehash, defaultResolver);           /// set new resolver
        _ownerOf[uint256(moleculehash)] = owner; // change ownership record
        unchecked {                          // update balances
            _balanceOf[owner]++;
        }
        emit NewMolecule(moleculehash, owner);
        return moleculehash;
    }

}
