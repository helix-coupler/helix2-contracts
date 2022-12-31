// SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "test/GenAddr.sol";
// Helix2 Manager Contract
import "src/Helix2.sol";
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
// Resolver
import "src/Names/NameResolver.sol";
// Interface
import "src/Names/iName.sol";
import "src/Bonds/iBond.sol";
import "src/Molecules/iMolecule.sol";
import "src/Polycules/iPolycule.sol";
import "src/Names/iERC721.sol";
import "src/Names/iNameResolver.sol";
import "src/Interface/iHelix2.sol";
import "src/Interface/iENS.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Constructor Tests
 * @notice Tests Constructors of all Helix2 Contracts
 */
contract Helix2ConstructorTest is Test {
    using GenAddr for address;

    HELIX2 public HELIX2_;
    NameResolver public NameResolver_;
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

    /// Constants
    address public deployer;
    uint256 public theEnd = 250_000_000_000_000_000; // roughly 80,000,000,000 years in the future

    constructor() {
        deployer = address(this);

        // HELIX2 ------------------------------------------------
        // deploy Helix2
        HELIX2_ = new HELIX2();
        address _HELIX2 = address(HELIX2_);

        // NAMES -------------------------------------------------
        // deploy NameRegistry
        NAMES = new Helix2NameRegistry(_HELIX2);
        address _NAMES = address(NAMES);
        // deploy NameRegistrar
        _NAME_ = new Helix2NameRegistrar(_NAMES, _HELIX2);

        // BONDS -------------------------------------------------
        // deploy BondRegistry
        BONDS = new Helix2BondRegistry(_NAMES, _HELIX2);
        address _BONDS = address(BONDS);
        // deploy BondRegistrar
        _BOND_ = new Helix2BondRegistrar(_BONDS, _NAMES, _HELIX2);

        // MOLECULES ---------------------------------------------
        // deploy MoleculeRegistry
        MOLECULES = new Helix2MoleculeRegistry(_NAMES, _HELIX2);
        address _MOLECULES = address(MOLECULES);
        // deploy MoleculeRegistrar
        _MOLY_ = new Helix2MoleculeRegistrar(_MOLECULES, _NAMES, _HELIX2);

        // POLYCULES ---------------------------------------------
        // deploy PolyculeRegistry
        POLYCULES = new Helix2PolyculeRegistry(_NAMES, _HELIX2);
        address _POLYCULES = address(POLYCULES);
        // deploy PolyculeRegistrar
        _POLY_ = new Helix2PolyculeRegistrar(_POLYCULES, _NAMES, _HELIX2);

        // RESOLVERS ---------------------------------------------
        // deploy Name Resolver
        NameResolver_ = new NameResolver(_HELIX2);
    }

    /// forge setup
    function setUp() public {}

    // Test Constructor Name
    function testConstructor_Name() public {
        // 0x0
        assertEq(NAMES.owner(bytes32(0x0)), deployer);
        assertEq(NAMES.controller(bytes32(0x0)), deployer);
        assertEq(NAMES.resolver(bytes32(0x0)), deployer);
        assertEq(NAMES.expiry(bytes32(0x0)), theEnd);
        // roothash
        bytes32 roothash = HELIX2_.getRoothash()[0];
        assertEq(NAMES.owner(roothash), deployer);
        assertEq(NAMES.controller(roothash), deployer);
        assertEq(NAMES.resolver(roothash), deployer);
        assertEq(NAMES.expiry(roothash), theEnd);
    }

    // Test Constructor Bond
    function testConstructor_Bond() public {
        // 0x0
        (uint8[] memory rules, address[] memory hooks) = BONDS.hooksWithRules(
            bytes32(0x0)
        );
        assertEq(hooks.length, 1);
        assertEq(hooks[0], address(0x0));
        assertEq(rules[0], uint8(0));
        assertEq(BONDS.cation(bytes32(0x0)), bytes32(0x0));
        assertEq(BONDS.anion(bytes32(0x0)), bytes32(0x0));
        assertEq(BONDS.alias_(bytes32(0x0)), bytes32(0x0));
        assertEq(BONDS.covalence(bytes32(0x0)), true);
        assertEq(BONDS.controller(bytes32(0x0)), deployer);
        assertEq(BONDS.resolver(bytes32(0x0)), deployer);
        assertEq(BONDS.expiry(bytes32(0x0)), theEnd);
        // roothash
        bytes32[4] memory hashes = HELIX2_.getRoothash();
        for (uint i = 0; i < hashes.length; i++) {
            (uint8[] memory _rules, address[] memory _hooks) = BONDS
                .hooksWithRules(hashes[i]);
            assertEq(_hooks.length, 1);
            assertEq(_hooks[0], address(0x0));
            assertEq(_rules[0], uint8(0x0));
            assertEq(BONDS.cation(hashes[i]), hashes[i]);
            assertEq(BONDS.anion(hashes[i]), hashes[i]);
            assertEq(BONDS.alias_(hashes[i]), hashes[i]);
            assertEq(BONDS.covalence(hashes[i]), true);
            assertEq(BONDS.controller(hashes[i]), deployer);
            assertEq(BONDS.resolver(hashes[i]), deployer);
            assertEq(BONDS.expiry(hashes[i]), theEnd);
        }
    }

    // Test Constructor Molecule
    function testConstructor_Molecule() public {
        // 0x0
        (uint8[] memory rules, address[] memory hooks) = MOLECULES
            .hooksWithRules(bytes32(0x0));
        assertEq(hooks.length, 1);
        assertEq(hooks[0], address(0x0));
        assertEq(rules[0], uint8(0x0));
        assertEq(MOLECULES.cation(bytes32(0x0)), bytes32(0x0));
        assertEq(MOLECULES.anion(bytes32(0x0)).length, 1);
        assertEq(MOLECULES.anion(bytes32(0x0))[0], bytes32(0x0));
        assertEq(MOLECULES.alias_(bytes32(0x0)), bytes32(0x0));
        assertEq(MOLECULES.covalence(bytes32(0x0)), true);
        assertEq(MOLECULES.controller(bytes32(0x0)), deployer);
        assertEq(MOLECULES.resolver(bytes32(0x0)), deployer);
        assertEq(MOLECULES.expiry(bytes32(0x0)), theEnd);
        // roothash
        bytes32[4] memory hashes = HELIX2_.getRoothash();
        for (uint i = 0; i < hashes.length; i++) {
            (uint8[] memory _rules, address[] memory _hooks) = MOLECULES
                .hooksWithRules(hashes[i]);
            assertEq(_hooks.length, 1);
            assertEq(_hooks[0], address(0x0));
            assertEq(_rules[0], uint8(0x0));
            assertEq(MOLECULES.cation(hashes[i]), hashes[i]);
            assertEq(MOLECULES.anion(hashes[i]).length, 1);
            assertEq(MOLECULES.anion(hashes[i])[0], hashes[i]);
            assertEq(MOLECULES.alias_(hashes[i]), hashes[i]);
            assertEq(MOLECULES.covalence(hashes[i]), true);
            assertEq(MOLECULES.controller(hashes[i]), deployer);
            assertEq(MOLECULES.resolver(hashes[i]), deployer);
            assertEq(MOLECULES.expiry(hashes[i]), theEnd);
        }
    }

    // Test Constructor Polycule
    function testConstructor_Polycule() public {
        // 0x0
        (uint8[] memory rules, address[] memory hooks) = POLYCULES
            .hooksWithRules(bytes32(0x0));
        assertEq(hooks.length, 1);
        assertEq(hooks[0], address(0x0));
        assertEq(rules[0], uint8(0x0));
        assertEq(POLYCULES.cation(bytes32(0x0)), bytes32(0x0));
        assertEq(POLYCULES.anion(bytes32(0x0)).length, 1);
        assertEq(POLYCULES.anion(bytes32(0x0))[0], bytes32(0x0));
        assertEq(POLYCULES.alias_(bytes32(0x0)), bytes32(0x0));
        assertEq(POLYCULES.covalence(bytes32(0x0)), true);
        assertEq(POLYCULES.controller(bytes32(0x0)), deployer);
        assertEq(POLYCULES.resolver(bytes32(0x0)), deployer);
        assertEq(POLYCULES.expiry(bytes32(0x0)), theEnd);
        // roothash
        bytes32[4] memory hashes = HELIX2_.getRoothash();
        for (uint i = 0; i < hashes.length; i++) {
            (uint8[] memory _rules, address[] memory _hooks) = POLYCULES
                .hooksWithRules(hashes[i]);
            assertEq(_hooks.length, 1);
            assertEq(_hooks[0], address(0x0));
            assertEq(_rules[0], uint8(0x0));
            assertEq(POLYCULES.cation(hashes[i]), hashes[i]);
            assertEq(POLYCULES.anion(hashes[i]).length, 1);
            assertEq(POLYCULES.anion(hashes[i])[0], hashes[i]);
            assertEq(POLYCULES.alias_(hashes[i]), hashes[i]);
            assertEq(POLYCULES.covalence(hashes[i]), true);
            assertEq(POLYCULES.controller(hashes[i]), deployer);
            assertEq(POLYCULES.resolver(hashes[i]), deployer);
            assertEq(POLYCULES.expiry(hashes[i]), theEnd);
        }
    }
}
