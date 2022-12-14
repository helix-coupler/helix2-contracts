//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Names/iName.sol";
import "src/Names/ERC721.sol";
import "src/Interface/iHelix2.sol";
import "src/Oracle/iPriceOracle.sol";
import "src/Utils/LibString.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @notice GitHub: https://github.com/helix-coupler/helix2-contracts
 * @notice README: https://github.com/helix-coupler/resources
 * @dev testnet v0.0.1
 * @title Helix2 Name Registrar
 */
contract Helix2NameRegistrar is ERC721 {
    using LibString for address[];
    using LibString for address;
    using LibString for string[];
    using LibString for string;
    using LibString for uint256;

    /// @dev : Helix2 Name events
    event NewName(string label, bytes32 indexed namehash, address owner);
    event NewENSImport(string ens, bytes32 indexed namehash, address owner);

    /// Constants
    mapping(address => mapping(address => bool)) Operators;
    uint256 public defaultLifespan; // minimum registration duration: 90 days
    uint256 public basePrice; // default base price
    uint256[2] public sizeLimit; // name length limit
    bytes32 public roothash; // roothash
    string[4] public illegalBlocks; // illegal blocks

    /// Price Oracle
    iPriceOracle public PRICES;

    /**
     * @dev Initialise a new HELIX2 Names Registrar
     * @notice
     * @param _helix2 : address of HELIX2 Manager
     * @param _registry : address of HELIX2 Name Registry
     */
    constructor(address _registry, address _helix2, address _priceOracle) {
        NAMES = iNAME(_registry);
        HELIX2 = iHELIX2(_helix2);
        ENS = iENS(HELIX2.getENSRegistry());
        PRICES = iPriceOracle(_priceOracle);
        basePrice = PRICES.getPrices()[0];
        sizeLimit = HELIX2.getSizes()[0];
        defaultLifespan = HELIX2.getLifespans()[0];
        illegalBlocks = HELIX2.getIllegalBlocks();
        roothash = HELIX2.getRoothash()[0];
        Dev = msg.sender;
    }

    /**
     * @dev verify name has legal form
     * @param label : label of name
     */
    modifier isLegal(string memory label) {
        require(
            label.strlen() > sizeLimit[0] && label.strlen() < sizeLimit[1],
            "ILLEGAL_LABEL"
        ); /// check for undersized or oversized label
        require(!label.existsIn(illegalBlocks), "ILLEGAL_CHARS"); /// check for forbidden characters
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
     * @dev registers a new name
     * @param label : label of name without suffix
     * @param owner : owner to set for new name
     * @param lifespan : duration of registration in seconds
     * @return hash of new name
     */
    function newName(
        string memory label,
        address owner,
        uint lifespan
    ) external payable isLegal(label) returns (bytes32) {
        require(owner != address(0), "CANNOT_BURN");
        require(lifespan >= defaultLifespan, "LIFESPAN_TOO_SHORT");
        require(msg.value >= basePrice * lifespan, "INSUFFICIENT_ETHER");
        bytes32 namehash = keccak256(
            abi.encodePacked(keccak256(abi.encodePacked(label)), roothash)
        );
        /// @notice : availability is checked inline (not as modifier) to avoid deep stack
        require(!NAMES.recordExists(namehash), "NAME_EXISTS");
        address _owner = NAMES.owner(namehash);
        /// @notice : Balance of previous owner is updated only when the
        /// expired name is re-registered by someone else, aka, an
        /// expired name is accounted to its previous owner until it is re-registered (!= renewed)
        if (_owner != address(0)) {
            unchecked {
                _balanceOf[_owner]--;
            }
            emit Transfer(_owner, address(0), uint256(namehash));
        }
        NAMES.register(label, namehash, owner); /// set new owner
        NAMES.setController(namehash, owner); /// set new controller
        NAMES.setExpiry(namehash, block.timestamp + lifespan); /// set new expiry
        NAMES.setResolver(namehash, defaultResolver); /// set new resolver
        unchecked {
            // update balances
            _balanceOf[owner]++;
        }
        emit NewName(label, namehash, owner);
        return namehash;
    }

    /**
     * @dev calculates hash of ENS domain (...sub.domain.vitalik.eth)
     * @param _ens : ENS domain to hash
     * @return _namehash : hash of ENS domain
     */
    function ensHash(
        bytes calldata _ens
    ) public pure returns (bytes32 _namehash) {
        uint i = _ens.length;
        bytes memory _label;
        _namehash = bytes32(0);
        unchecked {
            while (i > 0) {
                --i;
                if (_ens[i] == bytes1(".")) {
                    _namehash = keccak256(
                        abi.encodePacked(_namehash, keccak256(_label))
                    );
                    _label = "";
                } else {
                    _label = bytes.concat(_ens[i], _label);
                }
            }
            _namehash = keccak256(
                abi.encodePacked(_namehash, keccak256(_label))
            );
        }
    }

    /**
     * @dev registers an ENS name (vitalik.eth)
     * @param ens : ENS to import (vitalik.eth)
     * @param lifespan : duration of registration in seconds
     * @return hash of registered name (vitalik.eth.)
     */
    function claimENS(
        string calldata ens,
        uint lifespan
    ) external payable returns (bytes32) {
        bytes32 node = ensHash(bytes(ens));
        require(msg.sender == ENS.owner(node), "NOT_ENS_OWNER");
        require(lifespan >= defaultLifespan, "LIFESPAN_TOO_SHORT");
        require(msg.value >= basePrice * lifespan, "INSUFFICIENT_ETHER");
        bytes32 namehash = keccak256(abi.encodePacked(node, roothash));
        /// @notice : availability is checked inline (not as modifier) to avoid deep stack
        require(!NAMES.recordExists(namehash), "NAME_EXISTS");
        address _owner = NAMES.owner(namehash);
        /// @notice : Balance of previous owner is updated only when the
        /// expired name is re-registered by someone else, aka, an
        /// expired name is accounted to its previous owner until it is re-registered (!= renewed)
        if (_owner != address(0)) {
            unchecked {
                _balanceOf[_owner]--;
            }
            emit Transfer(_owner, address(0), uint256(namehash));
        }
        NAMES.register(ens, namehash, msg.sender); /// set new owner
        NAMES.setController(namehash, msg.sender); /// set new controller
        NAMES.setExpiry(namehash, block.timestamp + lifespan); /// set new expiry
        NAMES.setResolver(namehash, defaultResolver); /// set new resolver
        unchecked {
            // update balances
            _balanceOf[msg.sender]++;
        }
        emit NewENSImport(ens, namehash, msg.sender);
        return namehash;
    }
}
