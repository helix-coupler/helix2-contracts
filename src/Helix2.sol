//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/ERC721.sol";

interface iResolver {
    function contenthash(bytes32 link) external view returns(bytes memory);
    function addr(bytes32 link) external view returns(address payable);
    function addr2(bytes32 link, uint256 coinType) external view returns(bytes memory);
    function pubkey(bytes32 link) external view returns(bytes32 x, bytes32 y);
    function text(bytes32 link, string calldata key) external view returns(string memory);
}

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Registrar
 */
contract HELIX2 is ERC721 {
    /// @dev : Helix2 Link struct
    struct LINKS {
        mapping(bytes32 => address) _hooks;
        address _from;
        address _to;
        bytes32 _alias;
        address _resolver;
        address _controller;
    }
    mapping(uint => LINKS) public LINK;
    
    /**
     * @dev : register a new Link
     */
    function register() external {
        unchecked {
            ++balanceOf[msg.sender];
        }
    }

    modifier onlyDev() {
        require(msg.sender == Dev, "ONLY_DEV");
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
}
