// SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "test/GenAddr.sol";
// Helix2 Manager Contract
import "src/Helix2.sol";
// Registrar
import "src/Registrar/NameRegistrar.sol";
// Registry
import "src/Registry/NameRegistry.sol";
// Resolver
import "src/Resolver/NameResolver.sol";
// Interface
import "src/Interface/iName.sol";
import "src/Interface/iHelix2.sol";
import "src/Interface/iERC721.sol";
import "src/Interface/iNameResolver.sol";
import "src/Interface/iENS.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Registrar and Registry Tests
 * @notice Tests functions of Helix2 Name Registrar and Name Registry
 */
contract Helix2NamesTest is Test {
    using GenAddr for address;

    HELIX2 public HELIX2_;
    NameResolver public NameResolver_;
    // Registry
    Helix2NameRegistry public NAMES;
    // Registrar
    Helix2NameRegistrar public _NAME_;

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

        // RESOLVERS ---------------------------------------------
        // deploy Name Resolver
        NameResolver_ = new NameResolver(_HELIX2);
    }

    /// forge setup
    function setUp() public {}

    function testRegisterName() public {
        address pill = address(0xc0de4c0ca19e);
        _NAME_.setDefaultResolver(pill);
    }
}
