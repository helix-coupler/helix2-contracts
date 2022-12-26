// SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "test/GenAddr.sol";
// Helix2 Manager Contract
import "src/Helix2.sol";
// Registrar
import "src/Registrar/NameRegistrar.sol";
import "src/Registrar/BondRegistrar.sol";
import "src/Registrar/MoleculeRegistrar.sol";
import "src/Registrar/PolyculeRegistrar.sol";
// Registry
import "src/Registry/NameRegistry.sol";
import "src/Registry/BondRegistry.sol";
import "src/Registry/MoleculeRegistry.sol";
import "src/Registry/PolyculeRegistry.sol";
// Resolver
import "src/Resolver/NameResolver.sol";
// Interface
import "src/Interface/iName.sol";
import "src/Interface/iBond.sol";
import "src/Interface/iMolecule.sol";
import "src/Interface/iPolycule.sol";
import "src/Interface/iHelix2.sol";
import "src/Interface/iERC721.sol";
import "src/Interface/iNameResolver.sol";
import "src/Interface/iENS.sol";

contract Helix2Test is Test {
    using GenAddr for address;

    HELIX2 public Helix2;
    NameResolver public resolverName;
    // Registry
    Helix2Names public NAMES;
    Helix2Bonds public BONDS;
    Helix2Molecules public MOLYCULES;
    Helix2Polycules public POLYCULES;
    // Registrar
    NameRegistrar public _NAME_;
    BondRegistrar public _BOND_;
    MoleculeRegistrar public _MOLY_;
    PolyculeRegistrar public _POLY_;

    constructor() {
        address deployer = address(this);

        // HELIX2 ------------------------------------------------
        // deploy Helix2
        Helix2 = new HELIX2();
        address _HELIX2 = address(Helix2);

        // NAMES -------------------------------------------------
        // deploy NameRegistry
        NAMES = new Helix2Names(_HELIX2);
        address _NAMES = address(NAMES);
        // deploy NameRegistrar
        _NAME_ = new NameRegistrar(_NAMES, _HELIX2);

        // BONDS -------------------------------------------------
        // deploy BondRegistry
        BONDS = new Helix2Bonds(_NAMES, _HELIX2);
        address _BONDS = address(BONDS);
        // deploy BondRegistrar
        _BOND_ = new BondRegistrar(_BONDS, _NAMES, _HELIX2);

        // MOLYCULES ---------------------------------------------
        // deploy MoleculeRegistry
        MOLYCULES = new Helix2Molecules(_NAMES, _HELIX2);
        address _MOLYCULES = address(MOLYCULES);
        // deploy MoleculeRegistrar
        _MOLY_ = new MoleculeRegistrar(_MOLYCULES, _NAMES, _HELIX2);

        // POLYCULES ---------------------------------------------
        // deploy PolyculeRegistry
        POLYCULES = new Helix2Polycules(_NAMES, _HELIX2);
        address _POLYCULES = address(POLYCULES);
        // deploy PolyculeRegistrar
        _POLY_ = new PolyculeRegistrar(_POLYCULES, _NAMES, _HELIX2);

        // RESOLVERS ---------------------------------------------
        // deploy Name Resolver
        resolverName = new NameResolver(_HELIX2);

        deployer; // supress warning
    }

    /// forge setup
    function setUp() public {}

    /// Tests for Name Registry

    // Test Constructor
    function testSetup() public view {
        address _owner = NAMES.owner(bytes32(0x0));
        console.log(_owner);
    }
}
