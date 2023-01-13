// SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "test/GenAddr.sol";
// Helix2 Manager Contract
import "src/Classic/Helix2.sol";
// Price Oracle
import "src/Oracle/PriceOracle.sol";
// Registrar
import "src/Names/NameRegistrar.sol";
import "src/Bonds/BondRegistrar.sol";
import "src/Molecules/MoleculeRegistrar.sol";
import "src/Polycules/PolyculeRegistrar.sol";
// Registry
import "src/Names/NameRegistry.sol";
import "src/Bonds/BondRegistry.sol";
import "src/Molecules/MoleculeRegistry.sol";
import "src/Polycules/PolyculeRegistry.sol";
// Storage
import "src/Names/NameStorage.sol";
import "src/Polycules/PolyculeStorage.sol";
// Resolver
import "src/Names/NameResolver.sol";
import "src/Bonds/BondResolver.sol";
import "src/Molecules/MoleculeResolver.sol";
import "src/Polycules/PolyculeResolver.sol";
// Interface
import "src/Names/iName.sol";
import "src/Bonds/iBond.sol";
import "src/Molecules/iMolecule.sol";
import "src/Polycules/iPolycule.sol";
import "src/Names/iERC721.sol";
import "src/Names/iNameResolver.sol";
import "src/Bonds/iBondResolver.sol";
import "src/Molecules/iMoleculeResolver.sol";
import "src/Polycules/iPolyculeResolver.sol";
import "src/Interface/iHelix2.sol";
import "src/Interface/iENS.sol";
import "src/Oracle/iPriceOracle.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Constructor Tests
 * @notice Tests Constructors of all Helix2 Contracts
 */
contract Helix2ConstructorTest is Test {
    using GenAddr for address;

    HELIX2 public HELIX2_;
    NameResolver public NameResolver_;
    BondResolver public BondResolver_;
    MoleculeResolver public MoleculeResolver_;
    PolyculeResolver public PolyculeResolver_;
    // Registry
    Helix2NameRegistry public NAMES;
    Helix2BondRegistry public BONDS;
    Helix2MoleculeRegistry public MOLECULES;
    Helix2PolyculeRegistry public POLYCULES;
    // Registrar
    Helix2NameRegistrar public _NAME_;
    Helix2BondRegistrar public _BOND_;
    Helix2MoleculeRegistrar public _MOLY_;
    Helix2PolyculeRegistrar public _POLY_;
    // Storage
    Helix2NameStorage public NAMESTORE;
    Helix2PolyculeStorage public POLYSTORE;

    // Price Oracle
    Helix2PriceOracle public PriceOracle;

    /// Constants
    address public deployer;
    uint256 public theEnd = 250_000_000_000_000_000; // roughly 80,000,000,000 years in the future

    constructor() {
        deployer = address(this);

        // HELIX2 ------------------------------------------------
        // deploy Helix2
        HELIX2_ = new HELIX2();
        // deploy Price Oracle
        PriceOracle = new Helix2PriceOracle();

        // NAMES -------------------------------------------------
        // deploy NameRegistry
        NAMES = new Helix2NameRegistry(address(HELIX2_), address(PriceOracle));
        address _NAMES = address(NAMES);
        // deploy NameStorage
        NAMESTORE = new Helix2NameStorage(_NAMES);
        // deploy NameRegistrar
        _NAME_ = new Helix2NameRegistrar(
            _NAMES,
            address(HELIX2_),
            address(PriceOracle)
        );
        NAMES.setConfig(
            address(HELIX2_),
            address(PriceOracle),
            address(NAMESTORE)
        );

        // BONDS -------------------------------------------------
        // deploy BondRegistry
        BONDS = new Helix2BondRegistry(
            _NAMES,
            address(HELIX2_),
            address(PriceOracle)
        );
        address _BONDS = address(BONDS);
        // deploy BondRegistrar
        _BOND_ = new Helix2BondRegistrar(
            _BONDS,
            _NAMES,
            address(HELIX2_),
            address(PriceOracle)
        );

        // MOLECULES ---------------------------------------------
        // deploy MoleculeRegistry
        MOLECULES = new Helix2MoleculeRegistry(
            _NAMES,
            address(HELIX2_),
            address(PriceOracle)
        );
        address _MOLECULES = address(MOLECULES);
        // deploy MoleculeRegistrar
        _MOLY_ = new Helix2MoleculeRegistrar(
            _MOLECULES,
            _NAMES,
            address(HELIX2_),
            address(PriceOracle)
        );

        // POLYCULES ---------------------------------------------
        // deploy PolyculeRegistry
        POLYCULES = new Helix2PolyculeRegistry(
            _NAMES,
            address(HELIX2_),
            address(PriceOracle)
        );
        address _POLYCULES = address(POLYCULES);
        // deploy PolyculeStorage
        POLYSTORE = new Helix2PolyculeStorage(_POLYCULES);
        // deploy PolyculeRegistrar
        _POLY_ = new Helix2PolyculeRegistrar(
            _POLYCULES,
            _NAMES,
            address(HELIX2_),
            address(PriceOracle)
        );

        // RESOLVERS ---------------------------------------------
        // deploy Name Resolver
        NameResolver_ = new NameResolver(address(HELIX2_));
        // deploy Bond Resolver
        BondResolver_ = new BondResolver(address(HELIX2_));
        // deploy Molecule Resolver
        MoleculeResolver_ = new MoleculeResolver(address(HELIX2_));
        // deploy Polycule Resolver
        PolyculeResolver_ = new PolyculeResolver(address(HELIX2_));
    }

    /// forge setup
    function setUp() public {}

    // Test Constructor Name
    function testConstructor_Name() public {}

    // Test Constructor Bond
    function testConstructor_Bond() public {}

    // Test Constructor Molecule
    function testConstructor_Molecule() public {}

    // Test Constructor Polycule
    function testConstructor_Polycule() public {}
}
