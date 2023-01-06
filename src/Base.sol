// SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

/// @dev : Helix2 Interfaces
import "src/Interface/iHelix2.sol";

/// @dev : Other Interfaces

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
    string[4] public illegalBlocks = [".", "-", "#", ""];

    /// @dev : Label sizes for each struct in order [<name>, <bond>, <molecule>, <polycule>]
    uint256[2][4] public sizes = [[3, 32], [3, 32], [3, 32], [3, 32]];

    /// @dev : Default lifespans in seconds for each struct in order [<name>, <bond>, <molecule>, <polycule>]
    uint256[4] public lifespans = [1, 1, 1, 1];

    /// @dev : Root Identifier
    bytes32[4] public roothash = [
        keccak256(abi.encodePacked(bytes32(0), keccak256("."))), /// Name Roothash
        keccak256(abi.encodePacked(bytes32(0), keccak256("-"))), /// Bond Roothash
        keccak256(abi.encodePacked(bytes32(0), keccak256("-"))), /// Molecule Roothash
        keccak256(abi.encodePacked(bytes32(0), keccak256("-"))) /// Polycule Roothash
    ];

    /// @dev : ENS Registry
    address public ensRegistry = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;

    /// @dev : Helix2 Registry array init
    /// @notice : Registeries must be set upon deployment
    address[4] public helix2Registry = [
        address(0), /// Name Registry
        address(0), /// Bond Registry
        address(0), /// Molecule Registry
        address(0) /// Polycule Registry
    ];

    /// @dev : Helix2 Registrar array init
    /// @notice : Registrars must be set upon deployment
    address[4] public helix2Registrar = [
        address(0), /// Name Registry
        address(0), /// Bond Registry
        address(0), /// Molecule Registry
        address(0) /// Polycule Registry
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
     * @dev pauses or resumes contract
     */
    function toggleActive() external onlyDev {
        active = !active;
    }

    /**
     * @dev transfer contract ownership to new Dev
     * @param newDev : new Dev
     */
    function changeDev(address newDev) external onlyDev {
        emit NewDev(Dev, newDev);
        Dev = newDev;
    }

    /**
     * @dev setInterface
     * @param sig : signature
     * @param value : boolean
     */
    function setInterface(bytes4 sig, bool value) external payable onlyDev {
        require(sig != 0xffffffff, "INVALID_INTERFACE_SELECTOR");
        supportsInterface[sig] = value;
    }

    /**
     * @dev withdraw ether to Dev, anyone can trigger
     */
    function withdrawEther() external payable {
        (bool ok, ) = Dev.call{value: address(this).balance}("");
        require(ok, "ETH_TRANSFER_FAILED");
    }

    /**
     * @dev returns illegal blocks list
     */
    function getIllegalBlocks() public view returns (string[4] memory) {
        return illegalBlocks;
    }

    /**
     * @dev returns illegal sizes list
     */
    function getSizes() public view returns (uint256[2][4] memory) {
        return sizes;
    }

    /**
     * @dev returns lifespans array
     */
    function getLifespans() public view returns (uint256[4] memory) {
        return lifespans;
    }

    /**
     * @dev returns Registeries
     */
    function getRegistry() public view returns (address[4] memory) {
        return helix2Registry;
    }

    /**
     * @dev returns Registrars
     */
    function getRegistrar() public view returns (address[4] memory) {
        return helix2Registrar;
    }

    /**
     * @dev returns hashes of root labels
     */
    function getRoothash() public view returns (bytes32[4] memory) {
        return roothash;
    }

    /**
     * @dev returns ENS Registry address
     */
    function getENSRegistry() public view returns (address) {
        return ensRegistry;
    }

    /**
     * @dev returns Dev address
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
