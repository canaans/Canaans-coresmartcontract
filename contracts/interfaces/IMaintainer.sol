// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IMaintainer {
    function validatorsApprove(
        bytes32 msgHash,
        bytes memory signatures
    ) external view;
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}