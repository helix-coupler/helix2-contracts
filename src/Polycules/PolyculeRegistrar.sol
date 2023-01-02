//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Polycules/iPolycule.sol";
import "src/Utils/LibString.sol";
import "src/Names/iName.sol";
import "src/Interface/iHelix2.sol";

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

    /// Dev
    address public Dev;

    /// @dev : Contract metadata
    string public constant polycule = "Helix2 Polycule Service";
    string public constant symbol = "HPS";

    /// @dev : Helix2 Polycule events
    event NewPolycule(bytes32 indexed polyhash, bytes32 cation);
    event NewDev(address Dev, address newDev);
    error OnlyDev(address _dev, address _you);

    /// Constants
    mapping(address => mapping(address => bool)) Operators;
    uint256 public defaultLifespan; // default registration duration: 90 days
    uint256 public basePrice; // default base price
    uint256 public sizeLimit; // name length limit
    bytes32 public roothash; // roothash
    string[4] public illegalBlocks; // illegal blocks

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
     * @dev : transfer contract ownership to new Dev
     * @param newDev : new Dev
     */
    function changeDev(address newDev) external onlyDev {
        emit NewDev(Dev, newDev);
        Dev = newDev;
    }

    /**
     * @dev : Initialise a new HELIX2 Polycules Registrar
     * @notice : constructor notes
     * @param _helix2 : address of HELIX2 Manager
     * @param _registry : address of HELIX2 Name Registry
     * @param __registry : address of HELIX2 Polycule Registry
     */
    constructor(address __registry, address _registry, address _helix2) {
        HELIX2 = iHELIX2(_helix2);
        NAMES = iNAME(_registry);
        POLYCULES = iPOLYCULE(__registry);
        basePrice = HELIX2.getPrices()[3];
        sizeLimit = HELIX2.getSizes()[3];
        defaultLifespan = HELIX2.getLifespans()[3];
        illegalBlocks = HELIX2.getIllegalBlocks();
        roothash = HELIX2.getRoothash()[3];
        Dev = msg.sender;
    }

    /**
     * @dev : verify alias has legal form
     * @param _alias : alias of polycule
     */
    modifier isLegal(string memory _alias) {
        require(bytes(_alias).length < sizeLimit, "ILLEGAL_LABEL"); /// check for oversized label <<< SIZE LIMIT
        require(!_alias.existsIn(illegalBlocks), "ILLEGAL_CHARS"); /// check for forbidden characters
        _;
    }

    /**
     * @dev : verify if each anion has a hook
     * @param _anion : array of anions
     * @param _config : array of config addresses
     */
    modifier isLegalMap(bytes32[] memory _anion, address[] memory _config) {
        require(_anion.length == _config.length, "BAD_MAP");
        _;
    }

    /**
     * @dev : verify polycule has expired and can be registered
     * @param _cation : cation of polycule
     * @param _alias : alias of polycule
     */
    modifier isAvailable(bytes32 _cation, string memory _alias) {
        require(
            !POLYCULES.recordExists(
                keccak256(
                    abi.encodePacked(
                        _cation,
                        HELIX2.getRoothash()[3],
                        keccak256(abi.encodePacked(_alias))
                    )
                )
            ),
            "POLYCULE_EXISTS"
        );
        _;
    }

    /**
     * @dev : verify ownership of polycule
     * @param polyhash : hash of polycule
     */
    modifier onlyCation(bytes32 polyhash) {
        require(POLYCULES.recordExists(polyhash), "NO_RECORD");
        address cation = NAMES.owner(POLYCULES.cation(polyhash));
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
     * @dev registers a new polycule
     * @param _alias : alias of polycule without suffix
     * @param cation : cation to set for new polycule
     * @param anion : array of target anions
     * @param lifespan : duration of registration
     * @param config : array of contract config addresses
     * @param rules : rules for hooks
     * @return hash of new polycule
     */
    function newPolycule(
        string memory _alias,
        bytes32 cation,
        bytes32[] memory anion,
        uint lifespan,
        address[] memory config,
        uint8[] memory rules
    )
        external
        payable
        isLegal(_alias)
        isLegalMap(anion, config)
        returns (bytes32)
    {
        address _cation = NAMES.owner(cation);
        require(lifespan >= defaultLifespan, "LIFESPAN_TOO_SHORT");
        require(msg.value >= basePrice * lifespan, "INSUFFICIENT_ETHER");
        bytes32 aliashash = keccak256(abi.encodePacked(_alias));
        bytes32 polyhash = keccak256(
            abi.encodePacked(cation, roothash, aliashash)
        );
        /// @notice : availability is checked inline (not as modifier) to avoid deep stack
        require(!POLYCULES.recordExists(polyhash), "POLYCULE_EXISTS");
        POLYCULES.register(polyhash, cation); /// set new cation (= from)
        POLYCULES.setAnions(polyhash, anion, config, rules); /// set anions (= to)
        POLYCULES.setExpiry(polyhash, block.timestamp + lifespan); /// set new expiry
        POLYCULES.setController(polyhash, _cation); /// set new controller
        POLYCULES.setResolver(polyhash, defaultResolver); /// set new resolver
        POLYCULES.setAlias(polyhash, aliashash); /// set new alias
        emit NewPolycule(polyhash, cation);
        return polyhash;
    }
}
