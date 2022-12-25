//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/ERC721.sol";
import "src/Interface/iMolecule.sol";
import "src/Utils/LibString.sol";
import "src/Interface/iName.sol";
import "src/Interface/iHelix2.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Molecule Base
 */
contract MoleculeRegistrar is ERC721 {
    using LibString for string[];
    using LibString for string;

    iHELIX2 public HELIX2 = iHELIX2(address(0x0));
    iNAME public NAMES = iNAME(HELIX2.getRegistry()[2]);

    /// @dev : Contract metadata
    string public constant molecule = "Helix2 Molecule Service";
    string public constant symbol = "HMS";

    /// @dev : Helix2 Molecule events
    event NewMolecule(bytes32 indexed moleculehash, bytes32 cation);
    event NewCation(bytes32 indexed moleculehash, bytes32 cation);
    event NewExpiry(bytes32 indexed moleculehash, uint expiry);
    event NewRecord(bytes32 indexed moleculehash, address resolver);
    event NewResolver(bytes32 indexed moleculehash, address resolver);
    event NewController(bytes32 indexed moleculehash, address controller);

    /// Constants
    mapping (address => mapping(address => bool)) Operators;
    uint256 public defaultLifespan = 7_776_000_000;    // default registration duration: 90 days
    uint256 public basePrice = HELIX2.getPrices()[2];  // default base price

    /// Molecule Registry
    iMOLECULE public MOLECULES = iMOLECULE(address(0x0));

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
    modifier isNew(string memory label) {
        bytes32 _cation =  MOLECULES.cation(
            keccak256(
                abi.encodePacked(
                    roothash[2], 
                    keccak256(abi.encodePacked(label))
                )
            )
        );
        address cation = NAMES.owner(_cation);
        require(cation == address(0x0), "MOLECULE_EXISTS");
        _;
    }

    /**
     * @dev : verify molecule belongs to root
     * @param label : label of molecule
     */
    modifier isLegal(string memory label) {
        require(bytes(label).length > sizes[2], 'ILLEGAL_LABEL'); /// check for oversized label
        require(!label.existsIn(illegalBlocks), 'ILLEGAL_CHARS'); /// check for forbidden characters
        _;
    }

    /**
     * @dev : verify molecule belongs to root
     * @param label : label of molecule
     */
    modifier isNotExpired(string memory label) {
        bytes32 moleculehash = keccak256(
            abi.encodePacked(
                roothash[2], 
                keccak256(abi.encodePacked(label))
            )
        );
        require(MOLECULES.expiry(moleculehash) < block.timestamp, 'MOLECULE_NOT_EXPIRED'); /// check if molecule has expired
        _;
    }

    /**
     * @dev : verify ownership of molecule
     * @param moleculehash : hash of molecule
     */
    modifier onlyCation(bytes32 moleculehash) {
        address cation = NAMES.owner(
            MOLECULES.cation(moleculehash)
        );
        require(cation == msg.sender || Operators[cation][msg.sender], "NOT_OWNER");
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
     * @param cation : cation to set for new molecule
     * @param lifespan : duration of registration
     * @return hash of new molecule
     */
    function newMolecule(
        string memory label, 
        bytes32 cation, 
        bytes32[] calldata anion,
        uint lifespan
    ) external 
      payable
      isNew(label)
      isLegal(label)
      isNotExpired(label) 
      returns(bytes32) 
    {
        address _cation = NAMES.owner(cation);
        require(lifespan >= defaultLifespan, 'LIFESPAN_TOO_SHORT');
        require(msg.value >= basePrice * lifespan, 'INSUFFICIENT_ETHER');
        bytes32 moleculehash = keccak256(abi.encodePacked(roothash[2], keccak256(abi.encodePacked(label))));
        MOLECULES.setCation(moleculehash, cation);                      /// set new cation (= from)
        MOLECULES.setAnion(moleculehash, anion);                        /// set anions (= to)
        MOLECULES.setExpiry(moleculehash, block.timestamp + lifespan);  /// set new expiry
        MOLECULES.setController(moleculehash, _cation);                 /// set new controller
        MOLECULES.setResolver(moleculehash, defaultResolver);           /// set new resolver
        _ownerOf[uint256(moleculehash)] = _cation; // change ownership record
        unchecked {                                // update balances
            _balanceOf[_cation]++;
        }
        emit NewMolecule(moleculehash, cation);
        return moleculehash;
    }

}
