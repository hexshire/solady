// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./utils/SoladyTest.sol";
import {ReentrancyGuardTransient} from "../src/utils/ReentrancyGuardTransient.sol";
import {
    MockReentrancyGuardTransient,
    ReentrancyAttack
} from "./utils/mocks/MockReentrancyGuardTransient.sol";

contract ReentrancyGuardTransientTest is SoladyTest {
    MockReentrancyGuardTransient immutable target = new MockReentrancyGuardTransient();
    ReentrancyAttack immutable reentrancyAttack = new ReentrancyAttack();

    // Before and after each test, the reentrancy guard should be unlocked.
    modifier expectBeforeAfterReentrancyGuardTransientUnlocked() {
        assertEq(target.isReentrancyGuardLocked(), false);
        _;
        assertEq(target.isReentrancyGuardLocked(), false);
    }

    function testRevertGuardLocked()
        external
        expectBeforeAfterReentrancyGuardTransientUnlocked
    {
        // Attempt to call a `nonReentrant` method with an unprotected method.
        // Expect a success.
        target.callUnguardedToGuarded();
        assertEq(target.enterTimes(), 1);

        // Attempt to call a `nonReentrant` method within a `nonReentrant` method.
        // Expect a revert with the `Reentrancy` error.
        vm.expectRevert(ReentrancyGuardTransient.Reentrancy.selector);
        target.callGuardedToGuarded();
    }

    function testRevertReadGuardLocked()
        external
        expectBeforeAfterReentrancyGuardTransientUnlocked
    {
        // Attempt to call a `nonReadReentrant` method with an unprotected method.
        // Expect a success.
        target.callUnguardedToReadGuarded();
        assertEq(target.enterTimes(), 1);

        // Attempt to call a `nonReadReentrant` method within a `nonReentrant` method.
        // Expect a revert with the `Reentrancy` error.
        vm.expectRevert(ReentrancyGuardTransient.Reentrancy.selector);
        target.callGuardedToReadGuarded();
    }

    function testRevertRemoteCallback()
        external
        expectBeforeAfterReentrancyGuardTransientUnlocked
    {
        // Attempt to reenter a `nonReentrant` method from a remote contract.
        vm.expectRevert(ReentrancyAttack.ReentrancyAttackFailed.selector);
        target.countAndCall(reentrancyAttack);
    }

    function testRecursiveDirectUnguardedCall()
        external
        expectBeforeAfterReentrancyGuardTransientUnlocked
    {
        // Expect to be able to call unguarded methods recursively.
        // Expect a success.
        target.countUnguardedDirectRecursive(10);
        assertEq(target.enterTimes(), 10);
    }

    function testRevertRecursiveDirectGuardedCall()
        external
        expectBeforeAfterReentrancyGuardTransientUnlocked
    {
        // Attempt to reenter a `nonReentrant` method from a direct call.
        // Expect a revert with the `Reentrancy` error.
        vm.expectRevert(ReentrancyGuardTransient.Reentrancy.selector);
        target.countGuardedDirectRecursive(10);
        assertEq(target.enterTimes(), 0);
    }

    function testRecursiveIndirectUnguardedCall()
        external
        expectBeforeAfterReentrancyGuardTransientUnlocked
    {
        // Expect to be able to call unguarded methods recursively.
        // Expect a success.
        target.countUnguardedIndirectRecursive(10);
        assertEq(target.enterTimes(), 10);
    }

    function testRevertRecursiveIndirectGuardedCall()
        external
        expectBeforeAfterReentrancyGuardTransientUnlocked
    {
        // Attempt to reenter a `nonReentrant` method from an indirect call.
        vm.expectRevert(ReentrancyGuardTransient.Reentrancy.selector);
        target.countGuardedIndirectRecursive(10);
        assertEq(target.enterTimes(), 0);
    }
}
