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
contract Helix2MoleculeRegistrar is ERC721 {
    using LibString for bytes32[];
    using LibString for bytes32;
    using LibString for address[];
    using LibString for address;
    using LibString for string[];
    using LibString for string;

    /// @dev : Contract metadata
    string public constant molecule = "Helix2 Molecule Service";
    string public constant symbol = "HMS";

    /// @dev : Helix2 Molecule events
    event NewMolecule(bytes32 indexed molyhash, bytes32 cation);
    event NewCation(bytes32 indexed molyhash, bytes32 cation);
    event NewExpiry(bytes32 indexed molyhash, uint expiry);
    event NewRecord(bytes32 indexed molyhash, address resolver);
    event NewResolver(bytes32 indexed molyhash, address resolver);
    event NewController(bytes32 indexed molyhash, address controller);

    /// Constants
    mapping(address => mapping(address => bool)) Operators;
    uint256 public defaultLifespan = 7_776_000_000; // default registration duration: 90 days
    uint256 public basePrice; // default base price

    /// Name Registry
    iNAME public NAMES;
    /// Molecule Registry
    iMOLECULE public MOLECULES;
    /// HELIX2 Manager
    iHELIX2 public HELIX2;

    /// @dev : Default resolver used by this contract
    address public defaultResolver;

    /**
     * @dev : Initialise a new HELIX2 Molecules Registrar
     * @notice : constructor notes
     * @param _helix2 : address of HELIX2 Manager
     * @param _registry : address of HELIX2 Name Registry
     * @param __registry : address of HELIX2 Molecule Registry
     */
    constructor(address __registry, address _registry, address _helix2) {
        HELIX2 = iHELIX2(_helix2);
        NAMES = iNAME(_registry);
        MOLECULES = iMOLECULE(__registry);
        basePrice = HELIX2.getPrices()[2];
        Dev = msg.sender;
    }

    /**
     * @dev : verify alias has legal form
     * @param _alias : alias of molecule
     */
    modifier isLegal(string memory _alias) {
        require(bytes(_alias).length < sizes[1], "ILLEGAL_LABEL"); /// check for oversized label <<< SIZE LIMIT
        require(!_alias.existsIn4(illegalBlocks), "ILLEGAL_CHARS"); /// check for forbidden characters
        _;
    }

    /**
     * @dev : verify ownership of molecule
     * @param molyhash : hash of molecule
     */
    modifier onlyCation(bytes32 molyhash) {
        require(
            block.timestamp < MOLECULES.expiry(molyhash),
            "MOLECULE_EXPIRED"
        ); // expiry check
        address cation = NAMES.owner(MOLECULES.cation(molyhash));
        require(
            cation == msg.sender || Operators[cation][msg.sender],
            "NOT_OWNER"
        );
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
     * @param _alias : alias of molecule without suffix
     * @param cation : cation to set for new molecule
     * @param anion : array of target anions
     * @param lifespan : duration of registration
     * @return hash of new molecule
     */
    function newMolecule(
        string memory _alias,
        bytes32 cation,
        bytes32[] memory anion,
        uint lifespan
    ) external payable isLegal(_alias) returns (bytes32) {
        address _cation = NAMES.owner(cation);
        require(lifespan >= defaultLifespan, "LIFESPAN_TOO_SHORT");
        require(msg.value >= basePrice * lifespan, "INSUFFICIENT_ETHER");
        bytes32 aliashash = keccak256(abi.encodePacked(_alias));
        bytes32 molyhash = keccak256(
            abi.encodePacked(cation, roothash[2], aliashash)
        );
        MOLECULES.setCation(molyhash, cation); /// set new cation (= from)
        MOLECULES.setAnions(molyhash, anion); /// set anions (= to)
        MOLECULES.setExpiry(molyhash, block.timestamp + lifespan); /// set new expiry
        MOLECULES.setController(molyhash, _cation); /// set new controller
        MOLECULES.setResolver(molyhash, defaultResolver); /// set new resolver
        MOLECULES.setAlias(molyhash, aliashash); /// set new alias
        MOLECULES.setCovalence(molyhash, false); /// set new covalence flag
        MOLECULES.unhookAll(molyhash); /// reset hooks
        _ownerOf[uint256(molyhash)] = _cation; /// change ownership record
        unchecked {
            /// update balances
            _balanceOf[_cation]++;
        }
        emit NewMolecule(molyhash, cation);
        return molyhash;
    }
}
