// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC20Permit, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

import {ISPVToken} from "../interfaces/tokens/ISPVToken.sol";

contract SPVToken is ISPVToken, ERC20Permit {
    address public immutable spvGatewayV2;

    modifier onlySPVGatewayV2() {
        _onlySPVGatewayV2();
        _;
    }

    constructor(address spvGatewayV2_) ERC20("SPV Token", "SPV") ERC20Permit("SPV Token") {
        spvGatewayV2 = spvGatewayV2_;
    }

    function mintTo(address to_, uint256 amount_) external onlySPVGatewayV2 {
        _mint(to_, amount_);
    }

    function _onlySPVGatewayV2() internal view {
        require(msg.sender == spvGatewayV2, NotASPVGatewayV2(msg.sender));
    }
}
