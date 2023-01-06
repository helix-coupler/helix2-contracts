//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Names/iName.sol";
import "src/Molecules/iMolecule.sol";
import "src/Interface/iHelix2.sol";
import "src/Interface/iERC173.sol";
import "src/Oracle/iPriceOracle.sol";
import "src/Utils/LibString.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @notice GitHub: https://github.com/helix-coupler/helix2-contracts
 * @notice README: https://github.com/helix-coupler/resources
 * @dev testnet v0.0.1
 * @title Helix2 Molecule Registrar
 */
contract Helix2MoleculeRegistrar {
    using LibString for bytes32[];
    using LibString for bytes32;
    using LibString for address[];
    using LibString for address;
    using LibString for string[];
    using LibString for string;
    using LibString for uint256;

    /// Dev
    address public Dev;

    /// @dev : Contract metadata
    string public constant molecule = "Helix2 Molecule Service";
    string public constant symbol = "HMS";

    /// @dev : Helix2 Molecule events
    event NewMolecule(string _alias, bytes32 indexed molyhash, bytes32 cation);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    error OnlyDev(address _dev, address _you);

    /// Constants
    mapping(address => mapping(address => bool)) Operators;
    uint256 public defaultLifespan; // default registration duration: 90 days
    uint256 public basePrice; // default base price
    uint256[2] public sizeLimit; // name length limit
    bytes32 public roothash; // roothash
    string[4] public illegalBlocks; // illegal blocks

    /// Price Oracle
    iPriceOracle public PRICES;

    /// Interfaces
    iHELIX2 public HELIX2;
    iNAME public NAMES;
    iMOLECULE public MOLECULES;

    /// @dev : Default resolver used by this contract
    address public defaultResolver;

    /// @dev : Pause/Resume contract
    bool public active = true;

    /// @dev : Modifier to allow only dev
    modifier onlyDev() {
        if (msg.sender != Dev) {
            revert OnlyDev(Dev, msg.sender);
        }
        _;
    }

    /**
     * @dev pauses or resumes contract
     */
    function toggleActive() external onlyDev {
        active = !active;
    }

    /**
     * @dev get owner of contract
     * @return address of controlling dev or multi-sig wallet
     */
    function owner() external view returns (address) {
        return Dev;
    }

    /**
     * @dev transfer contract ownership to new Dev
     * @param newDev : new Dev
     */
    function transferOwnership(address newDev) external onlyDev {
        emit OwnershipTransferred(Dev, newDev);
        Dev = newDev;
    }

    /**
     * @dev Initialise a new HELIX2 Molecules Registrar
     * @notice
     * @param _helix2 : address of HELIX2 Manager
     * @param _registry : address of HELIX2 Name Registry
     * @param __registry : address of HELIX2 Molecule Registry
     */
    constructor(
        address __registry,
        address _registry,
        address _helix2,
        address _priceOracle
    ) {
        HELIX2 = iHELIX2(_helix2);
        NAMES = iNAME(_registry);
        MOLECULES = iMOLECULE(__registry);
        PRICES = iPriceOracle(_priceOracle);
        basePrice = PRICES.getPrices()[2];
        sizeLimit = HELIX2.getSizes()[2];
        defaultLifespan = HELIX2.getLifespans()[2];
        illegalBlocks = HELIX2.getIllegalBlocks();
        roothash = HELIX2.getRoothash()[2];
        Dev = msg.sender;
    }

    /**
     * @dev verify alias has legal form
     * @param _alias : alias of molecule
     */
    modifier isLegal(string memory _alias) {
        require(
            _alias.strlen() > sizeLimit[0] && _alias.strlen() < sizeLimit[1],
            "ILLEGAL_LABEL"
        ); /// check for undersized or oversized alias
        require(!_alias.existsIn(illegalBlocks), "ILLEGAL_CHARS"); /// check for forbidden characters
        _;
    }

    /**
     * @dev verify molecule has expired and can be registered
     * @param _cation : cation of molecule
     * @param _alias : alias of molecule
     */
    modifier isAvailable(bytes32 _cation, string memory _alias) {
        require(
            !MOLECULES.recordExists(
                keccak256(
                    abi.encodePacked(
                        _cation,
                        roothash,
                        keccak256(abi.encodePacked(_alias))
                    )
                )
            ),
            "MOLECULE_EXISTS"
        );
        _;
    }

    /**
     * @dev verify ownership of molecule
     * @param molyhash : hash of molecule
     */
    modifier onlyCation(bytes32 molyhash) {
        require(MOLECULES.recordExists(molyhash), "NO_RECORD");
        address cation = NAMES.owner(MOLECULES.cation(molyhash));
        require(
            cation == msg.sender || Operators[cation][msg.sender],
            "NOT_OWNER"
        );
        _;
    }

    /**
     * @dev sets Default Resolver
     * @param _resolver : resolver address
     */
    function setDefaultResolver(address _resolver) external onlyDev {
        defaultResolver = _resolver;
    }

    /**
     * @dev sets Default Lifespan
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
            abi.encodePacked(cation, roothash, aliashash)
        );
        /// @notice : availability is checked inline (not as modifier) to avoid deep stack
        require(!MOLECULES.recordExists(molyhash), "MOLECULE_EXISTS");
        MOLECULES.register(molyhash, cation); /// set new cation (= from)
        MOLECULES.setAnions(molyhash, anion); /// set anions (= to)
        MOLECULES.setExpiry(molyhash, block.timestamp + lifespan); /// set new expiry
        MOLECULES.setController(molyhash, _cation); /// set new controller
        MOLECULES.setResolver(molyhash, defaultResolver); /// set new resolver
        MOLECULES.setAlias(molyhash, aliashash); /// set new alias
        MOLECULES.setCovalence(molyhash, false); /// set new covalence flag
        MOLECULES.unhookAll(molyhash); /// reset hooks
        emit NewMolecule(_alias, molyhash, cation);
        return molyhash;
    }
}
