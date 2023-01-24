//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @author sshmatrix
 * @title Helix2 Covalence Setter
 */
contract MultiSigVault {
    /// @dev Events
    error InvalidSignature(string reason);

    struct SignatureInfo {
        string storage message;
        uint256 validity;
    }

    string private constant MSG_PREFIX = "\x19Ethereum Signed Message:\n32";
    mapping(address => bool) private _isValidSigner;
    uint private _threshold;

    /**
     * @dev Sets signers and their permissions
     */
    constructor(address[] memory _signers) {
        _threshold = _signers.length;
        for (uint i = 0; i < _threshold; i++) {
            _isValidSigner[_signers[i]] = true;
        }
    }

    /**
     * @dev Sets signers and their permissions
     */
    function verifyMultiSig(
        SignatureInfo calldata _sig,
        bytes[] calldata _multiSignature
    ) private returns (bool) {
        if (_sig.validity < block.timestamp) {
            return false;
        }
        if (_multiSignature.length != _threshold) {
            return false;
        }
        bytes32 digest = keccak256(
            abi.encodePacked(
                MSG_PREFIX,
                keccak256(abi.encodePacked(abi.encode(_sig.message)))
            )
        );
        for (uint256 i = 0; i < _multiSignature.length; i++) {
            address signerAddress = recoverSigner(digest, _multiSignature[i]);
            if (!_isValidSigner[signerAddress]) {
                return false;
            }
        }
        return true;
    }

    /**
     * @dev returns signer of a message
     * @param digest : hash of signed message
     * @param signature : compact signature to verify
     */
    function recoverSigner(
        bytes32 digest,
        bytes calldata signature
    ) external view returns (address) {
        bytes32 _low = bytes32(signature[:32]);
        bytes32 _mid;
        uint8 _end;
        if (signature.length > 64) {
            _mid = bytes32(signature[32:64]);
            _end = uint8(uint256(bytes32(signature[64:])));
        } else if (signature.length == 64) {
            bytes32 _cache = bytes32(signature[32:]);
            _mid =
                _cache &
                bytes32(
                    0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                );
            _end = uint8((uint256(_cache) >> 255) + 27);
        } else {
            revert InvalidSignature("SIG_LENGTH_UNDERFLOW");
        }
        if (
            uint256(_mid) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) revert InvalidSignature("SIG_MID_OVERFLOW");
        return ecrecover(digest, _end, _low, _mid);
    }
}
