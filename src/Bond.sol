//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Bond Base
 */
abstract contract Bond is HELIX2 {
    /// Helix2 Bond struct
    struct BOND {
        mapping(bytes32 => address) _hooks;
        address _from;
        address _to;
        bytes32 _alias;
        address _resolver;
        address _controller;
        bool _secure
    }
    mapping(uint => BOND) public BONDS;
}