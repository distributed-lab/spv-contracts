// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface ISPVToken is IERC20Metadata {
    error NotASPVGatewayV2(address sender);

    function mintTo(address to_, uint256 amount_) external;

    function spvGatewayV2() external view returns (address);
}
