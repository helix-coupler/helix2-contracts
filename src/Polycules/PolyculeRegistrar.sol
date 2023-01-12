//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Polycules/iPolycule.sol";
import "src/Utils/LibString.sol";
import "src/Names/iName.sol";
import "src/Interface/iHelix2.sol";
import "src/Interface/iERC173.sol";
import "src/Oracle/iPriceOracle.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @notice GitHub: https://github.com/helix-coupler/helix2-contracts
 * @notice README: https://github.com/helix-coupler/resources
 * @dev testnet v0.0.1
 * @title Helix2 Polycule Registrar
 */
contract Helix2PolyculeRegistrar {
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
    string public constant polycule = "Helix2 Polycule Service";
    string public constant symbol = "HPS";

    /// @dev : Helix2 Polycule events
    event NewPolycule(string _label, bytes32 indexed polyhash, bytes32 cation);
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
    iPOLYCULE public POLYCULES;

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
     * @dev Initialise a new HELIX2 Polycules Registrar
     * @notice
     * @param _helix2 : address of HELIX2 Manager
     * @param _registry : address of HELIX2 Name Registry
     * @param __registry : address of HELIX2 Polycule Registry
     */
    constructor(
        address __registry,
        address _registry,
        address _helix2,
        address _priceOracle
    ) {
        HELIX2 = iHELIX2(_helix2);
        NAMES = iNAME(_registry);
        POLYCULES = iPOLYCULE(__registry);
        PRICES = iPriceOracle(_priceOracle);
        basePrice = PRICES.getPrices()[0];
        sizeLimit = HELIX2.getSizes()[3];
        defaultLifespan = HELIX2.getLifespans()[3];
        illegalBlocks = HELIX2.getIllegalBlocks();
        roothash = HELIX2.getRoothash()[3];
        Dev = msg.sender;
    }

    /**
     * @dev verify label has legal form
     * @param _label : label of polycule
     */
    modifier isLegal(string memory _label) {
        require(
            _label.strlen() > sizeLimit[0] && _label.strlen() < sizeLimit[1],
            "ILLEGAL_LABEL"
        ); /// check for undersized or oversized label
        require(!_label.existsIn(illegalBlocks), "ILLEGAL_CHARS"); /// check for forbidden characters
        _;
    }

    /**
     * @dev verify if each anion has a hook
     * @param _anion : array of anions
     * @param _config : array of config addresses
     */
    modifier isLegalMap(bytes32[] memory _anion, address[] memory _config) {
        require(_anion.length == _config.length, "BAD_MAP");
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
     * @dev registers a new polycule
     * @param _label : label of polycule without suffix
     * @param cation : cation to set for new polycule
     * @param anion : array of target anions
     * @param lifespan : duration of registration
     * @param config : array of contract config addresses
     * @param rules : rules for hooks
     * @return hash of new polycule
     */
    function newPolycule(
        string memory _label,
        bytes32 cation,
        bytes32[] memory anion,
        uint lifespan,
        address[] memory config,
        uint8[] memory rules
    )
        external
        payable
        isLegal(_label)
        isLegalMap(anion, config)
        returns (bytes32)
    {
        address _cation = NAMES.owner(cation);
        require(lifespan >= defaultLifespan, "LIFESPAN_TOO_SHORT");
        require(msg.value >= basePrice * lifespan, "INSUFFICIENT_ETHER");
        bytes32 labelhash = keccak256(abi.encodePacked(_label));
        bytes32 polyhash = keccak256(
            abi.encodePacked(cation, roothash, labelhash)
        );
        /// @notice : availability is checked inline (not as modifier) to avoid deep stack
        require(!POLYCULES.recordExists(polyhash), "POLYCULE_EXISTS");
        POLYCULES.register(polyhash, cation); /// set new cation (= from)
        POLYCULES.setAnions(polyhash, anion, config, rules); /// set anions (= to)
        POLYCULES.setExpiry(polyhash, block.timestamp + lifespan); /// set new expiry
        POLYCULES.setController(polyhash, _cation); /// set new controller
        POLYCULES.setResolver(polyhash, defaultResolver); /// set new resolver
        POLYCULES.setLabel(polyhash, labelhash); /// set new label
        emit NewPolycule(_label, polyhash, cation);
        return polyhash;
    }
}
