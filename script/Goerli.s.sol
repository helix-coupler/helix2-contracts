// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.8.13;

import "forge-std/Script.sol";
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

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Constructor Tests
 * @notice Tests Constructors of all Helix2 Contracts
 */
contract Helix2Deploy is Script {
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

    /// Constants
    address public deployer;
    uint256 public theEnd = 250_000_000_000_000_000; // roughly 80,000,000,000 years in the future

    function run() external {
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
        // deploy Bond Resolver
        BondResolver_ = new BondResolver(_HELIX2);
        // deploy Molecule Resolver
        MoleculeResolver_ = new MoleculeResolver(_HELIX2);
        // deploy Polycule Resolver
        PolyculeResolver_ = new PolyculeResolver(_HELIX2);
    }
}
