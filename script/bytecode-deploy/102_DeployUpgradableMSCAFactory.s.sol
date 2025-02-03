/*
 * Copyright 2025 Circle Internet Group, Inc. All rights reserved.

 * SPDX-License-Identifier: GPL-3.0-or-later

 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
pragma solidity 0.8.24;

import {ENTRY_POINT, PLUGIN_MANAGER_ADDRESS, UPGRADABLE_MSCA_FACTORY_ADDRESS} from "./100_ContractAddress.sol";
import {Script, console} from "forge-std/src/Script.sol";

contract DeployUpgradableMSCAFactoryScript is Script {
    error DeployFailed();

    address internal constant DETERMINISTIC_DEPLOYMENT_FACTORY = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
    address internal constant PLUGIN_MANAGER = PLUGIN_MANAGER_ADDRESS;
    address payable internal constant EXPECTED_FACTORY_ADDRESS = payable(UPGRADABLE_MSCA_FACTORY_ADDRESS);
    address internal owner = vm.envAddress("MSCA_FACTORY_OWNER_ADDRESS");

    function run() public {
        address entryPoint = ENTRY_POINT;
        uint256 key = vm.envUint("DEPLOYER_PRIVATE_KEY");

        vm.startBroadcast(key);
        if (EXPECTED_FACTORY_ADDRESS.code.length != 0) {
            console.log("Found existing factory at expected address: %s", EXPECTED_FACTORY_ADDRESS);
            return;
        }

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/script/bytecode-deploy/build-output/UpgradableMSCAFactory.json");
        string memory json = vm.readFile(path);

        bytes32 salt = bytes32("0x20250130");
        bytes memory creationCode = abi.decode(vm.parseJson(json, ".bytecode.object"), (bytes));
        bytes memory args = abi.encode(owner, entryPoint, PLUGIN_MANAGER);


        bytes memory callData = abi.encodePacked(salt, creationCode, args);
        (bool success, bytes memory result) = DETERMINISTIC_DEPLOYMENT_FACTORY.call(callData);

        if (!success) {
            revert DeployFailed();
        }

        console.log("Deployed new factory at address: %s", address(bytes20(result)));
        vm.stopBroadcast();
    }
}
