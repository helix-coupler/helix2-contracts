// SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

/// @dev : Helix2 Structs
import "src/Names/NameRegistry.sol";
import "src/Bonds/BondRegistry.sol";
import "src/Molecules/MoleculeRegistry.sol";
import "src/Polycules/PolyculeRegistry.sol";

/// @dev : Helix2 Interfaces
import "src/Interface/iHelix2.sol";
import "src/Names/iName.sol";
import "src/Bonds/iBond.sol";
import "src/Molecules/iMolecule.sol";
import "src/Polycules/iPolycule.sol";
//import "src/interface/iResolver.sol";

/// @dev : Other Interfaces
import "src/Interface/iENS.sol";

/**
 * @author sshmatrix
 * @title Helix2 Base
 */
abstract contract Base {
    /// Events
    error OnlyDev(address _dev, address _you);
    event NewDev(address Dev, address newDev);

    /// Dev
    address public Dev;

    /// @dev : Forbidden characters
    string[4] public illegalBlocks = [".", "?", "!", "#"];

    /// @dev : Label sizes for each struct in order [<name>, <bond>, <molecule>, <polycule>]
    uint256[4] public sizes = [32, 32, 32, 32];

    /// @dev : Lifespans in seconds for each struct in order [<name>, <bond>, <molecule>, <polycule>]
    uint256[4] public lifespans = [1, 1, 1, 1];

    /// @dev : Root Identifier
    bytes32[4] public roothash = [
        keccak256(abi.encodePacked(bytes32(0), keccak256("."))), /// Name Roothash
        keccak256(abi.encodePacked(bytes32(0), keccak256("?"))), /// Bond Roothash
        keccak256(abi.encodePacked(bytes32(0), keccak256("!"))), /// Molecule Roothash
        keccak256(abi.encodePacked(bytes32(0), keccak256("#"))) /// Polycule Roothash
    ];

    /// @dev : ENS Registry
    address public ensRegistry = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;

    /// @dev : Helix2 Registry array
    address[4] public helix2Registry = [
        address(0), /// Name Registry
        address(0), /// Bond Registry
        address(0), /// Molecule Registry
        address(0) /// Polycule Registry
    ];

    /// @dev : Initialise Registers
    iENS public ENS = iENS(ensRegistry);
    iNAME public NAMES = iNAME(helix2Registry[0]);
    iBOND public BONDS = iBOND(helix2Registry[1]);
    iMOLECULE public MOLECULES = iMOLECULE(helix2Registry[2]);
    iPOLYCULE public POLYCULES = iPOLYCULE(helix2Registry[3]);

    /// @dev : Helix2 Registrar array
    address[4] public helix2Registrar = [
        address(0), /// Name Registry
        address(0), /// Bond Registry
        address(0), /// Molecule Registry
        address(0) /// Polycule Registry
    ];

    /// @dev : Helix2 base prices per second (Wei/second value)
    uint256[4] public prices = [
        0.0000000000002 ether, /// Name Base Price (= 200 Kwei/second)
        0.0000000000002 ether, /// Bond Base Price (= 200 Kwei/second)
        0.0000000000002 ether, /// Molecule Base Price (= 200 Kwei/second)
        0.0000000000002 ether /// Polycule Base Price (= 200 Kwei/second)
    ];

    /// @dev : Pause/Resume contract
    bool public active = true;

    mapping(bytes4 => bool) public supportsInterface;

    constructor() {
        Dev = msg.sender;
    }

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
     * @dev : setInterface
     * @param sig : signature
     * @param value : boolean
     */
    function setInterface(bytes4 sig, bool value) external payable onlyDev {
        require(sig != 0xffffffff, "INVALID_INTERFACE_SELECTOR");
        supportsInterface[sig] = value;
    }

    /**
     * @dev : withdraw ether to Dev, anyone can trigger
     */
    function withdrawEther() external payable {
        (bool ok, ) = Dev.call{value: address(this).balance}("");
        require(ok, "ETH_TRANSFER_FAILED");
    }

    /**
     * @dev : returns illegal blocks list
     */
    function getIllegalBlocks() public view returns (string[4] memory) {
        return illegalBlocks;
    }

    /**
     * @dev : returns illegal sizes list
     */
    function getSizes() public view returns (uint256[4] memory) {
        return sizes;
    }

    /**
     * @dev : returns lifespans array
     */
    function getLifespans() public view returns (uint256[4] memory) {
        return lifespans;
    }

    /**
     * @dev : returns Base Price list
     */
    function getPrices() public view returns (uint256[4] memory) {
        return prices;
    }

    /**
     * @dev : returns Registers
     */
    function getRegistry() public view returns (address[4] memory) {
        return helix2Registry;
    }

    /**
     * @dev : returns Registrars
     */
    function getRegistrar() public view returns (address[4] memory) {
        return helix2Registrar;
    }

    /**
     * @dev : returns hashes of root labels
     */
    function getRoothash() public view returns (bytes32[4] memory) {
        return roothash;
    }

    /**
     * @dev : returns contract address
     */
    function getContract() public view returns (address) {
        return address(this);
    }

    /**
     * @dev : returns Dev address
     */
    function isDev() public view returns (address) {
        return Dev;
    }

    /// @dev : revert on fallback
    fallback() external payable {
        revert();
    }

    /// @dev : revert on receive
    receive() external payable {
        revert();
    }
}
