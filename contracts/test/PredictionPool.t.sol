// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {PredictionPool} from "../src/PredictionPool.sol";
import {MockUSDC} from "./MockUSDC.sol";

contract PredictionPoolTest is Test {
    PredictionPool pool;
    MockUSDC usdc;
    address user = address(0x123);

    address user2 = address(0x789);

    function setUp() public {
    usdc = new MockUSDC();

    pool = new PredictionPool(address(usdc), address(0x456));

    assertEq(address(pool.usdc()), address(usdc));
    assertEq(pool.resolver(), address(0x456));
}

    function testCreateRound() public {
       vm.prank(address(0x456));
       pool.createRound();


        assertEq(pool.roundId(), 1);

    (
    uint256 id,
    uint256 startTime,
    uint256 endTime,
    uint256 referencePrice,
    uint256 settlementPrice,
    uint256 upPool,
    uint256 downPool,
    PredictionPool.Direction winner,
    bool resolved,
    /* bool locked */
    ) = pool.rounds(1);  

        assertEq(id, 1);
        assertEq(startTime, 0);
        assertEq(endTime, 0);
        assertEq(upPool, 0);
        assertEq(downPool, 0);
        assertEq(referencePrice, 0);
        assertEq(settlementPrice, 0);
        assertEq(uint256(winner), uint256(PredictionPool.Direction.None));
        assertEq(resolved, false);

   }

    function testBetUpUpdatesPool() public {
        usdc.mint(user, 1_000_000);
    
        vm.prank(user);
        usdc.approve(address(pool), 500);
    
        vm.startPrank(address(0x456));

        pool.createRound();
        pool.startRound(1, 8143982);

        vm.stopPrank();

        vm.prank(user);
        pool.bet(1, PredictionPool.Direction.Up, 500);

        (, , , , , uint256 upPool, uint256 downPool, , , ) = pool.rounds(1);

        assertEq(upPool, 500);
        assertEq(downPool, 0);

        assertEq(usdc.balanceOf(user), 1_000_000 - 500);
        assertEq(usdc.balanceOf(address(pool)), 500);

    }

     function testBetDownUpdatesPool() public {
        usdc.mint(user, 1_000_000);

        vm.prank(user);
        usdc.approve(address(pool), 700);

        vm.startPrank(address(0x456));

        pool.createRound();
        pool.startRound(1, 8143982);

        vm.stopPrank();

        vm.prank(user);
        pool.bet(1, PredictionPool.Direction.Down, 700);

        (, , , , , uint256 upPool, uint256 downPool, , , ) = pool.rounds(1);

        assertEq(upPool, 0);
        assertEq(downPool, 700);

        assertEq(usdc.balanceOf(user), 1_000_000 - 700);
        assertEq(usdc.balanceOf(address(pool)), 700);

    }

     function testCannotBetTwice() public {
     usdc.mint(user, 1_000_000);

     vm.startPrank(address(0x456));

     pool.createRound();
     pool.startRound(1, 8143982);

     vm.stopPrank();

     vm.prank(user);
     usdc.approve(address(pool), 1_000_000);

     vm.prank(user);
     pool.bet(1, PredictionPool.Direction.Up, 500);

     vm.prank(user);
     vm.expectRevert("Position already exists");
     pool.bet(1, PredictionPool.Direction.Down, 500);
   }

     function testCannotBetZero() public {

     vm.startPrank(address(0x456));

     pool.createRound();
     pool.startRound(1, 8143982);

     vm.stopPrank();

     vm.expectRevert("Amount must be greater than zero");
     pool.bet(1, PredictionPool.Direction.Up, 0);
   }

     function testCannotBetInvalidDirection() public {
    
     vm.startPrank(address(0x456));

     pool.createRound();
     pool.startRound(1, 8143982);

     vm.stopPrank();

     vm.expectRevert("Invalid direction");
     pool.bet(1, PredictionPool.Direction.None, 500);
   }


     function testCannotBetAfterRoundEnds() public {
        vm.startPrank(address(0x456));

        pool.createRound();
        pool.startRound(1, 8143982);

        vm.stopPrank();

        vm.warp(block.timestamp + 61);

        vm.expectRevert("Round is closed");
        pool.bet(1, PredictionPool.Direction.Up, 500);
    }     

     function testStartRound() public {

       vm.startPrank(address(0x456));

       pool.createRound();

       pool.startRound(1, 8143982);

       vm.stopPrank();

     (
     ,
     uint256 startTime,
     uint256 endTime,
     ,
     ,
     ,
     ,
     ,
     bool resolved,
     /* bool locked */
     ) = pool.rounds(1);

    assertGt(startTime, 0);
    assertEq(endTime, startTime + 60);
    assertEq(resolved, false);
}

function testCannotStartRoundWithZeroReferencePrice() public {
    vm.startPrank(address(0x456));

    pool.createRound();

    vm.expectRevert("Reference price must be greater than zero");
    pool.startRound(1, 0);

    vm.stopPrank();
}

function testCannotResolveRoundWithZeroSettlementPrice() public {
    vm.startPrank(address(0x456));

    pool.createRound();
    pool.startRound(1, 1000);

    vm.warp(block.timestamp + 61);
    pool.lockRound(1);

    vm.expectRevert("Settlement price must be greater than zero");
    pool.resolveRound(1, 0);

    vm.stopPrank();
}

function testCannotLockRoundTwice() public {
    vm.startPrank(address(0x456));

    pool.createRound();
    pool.startRound(1, 1000);

    vm.warp(block.timestamp + 61);

    pool.lockRound(1);

    vm.expectRevert("Round already locked");
    pool.lockRound(1);

    vm.stopPrank();
}

function testCannotStartRoundTwice() public {
    vm.startPrank(address(0x456));

    pool.createRound();
    pool.startRound(1, 1000);

    vm.expectRevert("Round already started");
    pool.startRound(1, 2000);

    vm.stopPrank();
}

function testCannotResolveRoundTwice() public {
    vm.startPrank(address(0x456));

    pool.createRound();
    pool.startRound(1, 1000);

    vm.warp(block.timestamp + 61);
    pool.lockRound(1);

    pool.resolveRound(1, 1100);

    vm.expectRevert("Round already resolved");
    pool.resolveRound(1, 1200);

    vm.stopPrank();
}

function testCannotBetBeforeRoundStarts() public {
    vm.startPrank(address(0x456));
    pool.createRound();
    vm.stopPrank();

    vm.startPrank(user);

    vm.expectRevert("Round not started");
    pool.bet(1, PredictionPool.Direction.Up, 500);

    vm.stopPrank();
}

function testCannotClaimBeforeRoundResolved() public {
    vm.startPrank(address(0x456));
    pool.createRound();
    pool.startRound(1, 1000);
    vm.stopPrank();

    usdc.mint(user, 500);

    vm.startPrank(user);

    usdc.approve(address(pool), 500);
    pool.bet(1, PredictionPool.Direction.Up, 500);

    vm.expectRevert("Round not resolved");
    pool.claim(1);

    vm.stopPrank();
}

function testCannotClaimWithoutPosition() public {
    vm.startPrank(address(0x456));

    pool.createRound();
    pool.startRound(1, 1000);

    vm.warp(block.timestamp + 61);
    pool.lockRound(1);
    pool.resolveRound(1, 1100);

    vm.stopPrank();

    vm.prank(user);
    vm.expectRevert("No position");
    pool.claim(1);
}

function testMultipleUpWinnersRoundingLeavesDust() public {
    usdc.mint(user, 100);
    usdc.mint(user2, 101);
    usdc.mint(address(0x999), 333);

    vm.startPrank(address(0x456));
    pool.createRound();
    pool.startRound(1, 1000);
    vm.stopPrank();

    vm.startPrank(user);
    usdc.approve(address(pool), 100);
    pool.bet(1, PredictionPool.Direction.Up, 100);
    vm.stopPrank();

    vm.startPrank(user2);
    usdc.approve(address(pool), 101);
    pool.bet(1, PredictionPool.Direction.Up, 101);
    vm.stopPrank();

    vm.startPrank(address(0x999));
    usdc.approve(address(pool), 333);
    pool.bet(1, PredictionPool.Direction.Down, 333);
    vm.stopPrank();

    vm.startPrank(address(0x456));
    vm.warp(block.timestamp + 61);
    pool.lockRound(1);
    pool.resolveRound(1, 1100);
    vm.stopPrank();

    uint256 userBalanceBefore = usdc.balanceOf(user);
    uint256 user2BalanceBefore = usdc.balanceOf(user2);

    vm.prank(user);
    pool.claim(1);

    vm.prank(user2);
    pool.claim(1);

    assertEq(usdc.balanceOf(user) - userBalanceBefore, 265);
    assertEq(usdc.balanceOf(user2) - user2BalanceBefore, 268);

    assertEq(usdc.balanceOf(address(pool)), 1);
}

function testNonResolverCannotCreateRound() public {
    vm.prank(user);

    vm.expectRevert("Not resolver");
    pool.createRound();
}

function testNonResolverCannotStartRound() public {
    vm.prank(user);

    vm.expectRevert("Not resolver");
    pool.startRound(1, 1000);
}

function testNonResolverCannotLockRound() public {
    vm.prank(user);

    vm.expectRevert("Not resolver");
    pool.lockRound(1);
}

function testCannotBetOnNonexistentRound() public {
    vm.prank(user);

    vm.expectRevert("Round does not exist");
    pool.bet(999, PredictionPool.Direction.Up, 100);
}

function testCannotClaimOnNonexistentRound() public {
    vm.prank(user);

    vm.expectRevert("Round not resolved");
    pool.claim(999);
}

function testCannotStartNonexistentRound() public {
    vm.prank(address(0x456));

    vm.expectRevert("Round does not exist");
    pool.startRound(999, 1000);
}

function testCannotLockNonexistentRound() public {
    vm.prank(address(0x456));

    vm.expectRevert("Round does not exist");
    pool.lockRound(999);
}

function testCannotResolveNonexistentRound() public {
    vm.prank(address(0x456));

    vm.expectRevert("Round does not exist");
    pool.resolveRound(999, 1000);
}

function testAllWinnerPayoutsDrainPool() public {
    usdc.mint(user, 100);
    usdc.mint(user2, 100);
    usdc.mint(address(0x999), 100);

    vm.startPrank(address(0x456));
    pool.createRound();
    pool.startRound(1, 1000);
    vm.stopPrank();

    vm.startPrank(user);
    usdc.approve(address(pool), 100);
    pool.bet(1, PredictionPool.Direction.Up, 100);
    vm.stopPrank();

    vm.startPrank(user2);
    usdc.approve(address(pool), 100);
    pool.bet(1, PredictionPool.Direction.Up, 100);
    vm.stopPrank();

    vm.startPrank(address(0x999));
    usdc.approve(address(pool), 100);
    pool.bet(1, PredictionPool.Direction.Down, 100);
    vm.stopPrank();

    vm.startPrank(address(0x456));
    vm.warp(block.timestamp + 61);
    pool.lockRound(1);
    pool.resolveRound(1, 1100);
    vm.stopPrank();

    vm.prank(user);
    pool.claim(1);

    vm.prank(user2);
    pool.claim(1);

    assertEq(usdc.balanceOf(address(pool)), 0);
}

function testCreateMultipleRoundsKeepsPreviousRound() public {
    vm.startPrank(address(0x456));

    pool.createRound();
    pool.startRound(1, 1000);

    pool.createRound();

    vm.stopPrank();

    assertEq(pool.roundId(), 2);

    (
        uint256 id1,
        uint256 startTime1,
        ,
        uint256 referencePrice1,
        ,
        ,
        ,
        ,
        ,
        bool locked1
    ) = pool.rounds(1);

    (
        uint256 id2,
        uint256 startTime2,
        ,
        uint256 referencePrice2,
        ,
        ,
        ,
        ,
        ,
        bool locked2
    ) = pool.rounds(2);

    assertEq(id1, 1);
    assertGt(startTime1, 0);
    assertEq(referencePrice1, 1000);
    assertFalse(locked1);

    assertEq(id2, 2);
    assertEq(startTime2, 0);
    assertEq(referencePrice2, 0);
    assertFalse(locked2);
}

function testUserCanHavePositionsAcrossMultipleRounds() public {
    usdc.mint(user, 200);

    vm.startPrank(address(0x456));

    pool.createRound();
    pool.startRound(1, 1000);

    pool.createRound();
    pool.startRound(2, 2000);

    vm.stopPrank();

    vm.startPrank(user);

    usdc.approve(address(pool), 200);

    pool.bet(1, PredictionPool.Direction.Up, 100);
    pool.bet(2, PredictionPool.Direction.Down, 100);

    vm.stopPrank();

    (uint256 amount1, PredictionPool.Direction direction1, bool claimed1) =
        pool.positions(1, user);

    (uint256 amount2, PredictionPool.Direction direction2, bool claimed2) =
        pool.positions(2, user);

    assertEq(amount1, 100);
    assertEq(uint256(direction1), uint256(PredictionPool.Direction.Up));
    assertFalse(claimed1);

    assertEq(amount2, 100);
    assertEq(uint256(direction2), uint256(PredictionPool.Direction.Down));
    assertFalse(claimed2);
}

function testUserCanClaimAcrossMultipleRounds() public {
    usdc.mint(user, 200);
    usdc.mint(user2, 100);

    vm.startPrank(address(0x456));

    pool.createRound();
    pool.startRound(1, 1000);

    pool.createRound();
    pool.startRound(2, 2000);

    vm.stopPrank();

    vm.startPrank(user);
    usdc.approve(address(pool), 200);
    pool.bet(1, PredictionPool.Direction.Up, 100);
    pool.bet(2, PredictionPool.Direction.Down, 100);
    vm.stopPrank();

    vm.startPrank(user2);
    usdc.approve(address(pool), 100);
    pool.bet(1, PredictionPool.Direction.Down, 100);
    vm.stopPrank();

    vm.startPrank(address(0x456));

    vm.warp(block.timestamp + 61);
    pool.lockRound(1);
    pool.resolveRound(1, 1100);

    vm.warp(block.timestamp + 61);
    pool.lockRound(2);
    pool.resolveRound(2, 1900);

    vm.stopPrank();

    uint256 balanceBefore = usdc.balanceOf(user);

    vm.prank(user);
    pool.claim(1);

    assertEq(usdc.balanceOf(user) - balanceBefore, 200);

    balanceBefore = usdc.balanceOf(user);

    vm.prank(user);
    pool.claim(2);

    assertEq(usdc.balanceOf(user) - balanceBefore, 100);

    assertEq(usdc.balanceOf(address(pool)), 0);

}

function testCannotLockRoundBeforeEnd() public {
    vm.startPrank(address(0x456));

    pool.createRound();
    pool.startRound(1, 8143982);

    vm.expectRevert("Round is still open");
    pool.lockRound(1);

    vm.stopPrank();
}

function testLockRoundAfterEnd() public {
    vm.startPrank(address(0x456));

    pool.createRound();
    pool.startRound(1, 8143982);

    vm.warp(block.timestamp + 61);

    pool.lockRound(1);

    vm.stopPrank();
    (
        ,
        ,
        ,
        ,
        ,
        ,
        ,
        ,
        ,
        bool locked
    ) = pool.rounds(1);

    assertEq(locked, true);
}

function testResolverCanResolveRound() public {
    vm.startPrank(address(0x456));

    pool.createRound();
    pool.startRound(1, 8143982);

    vm.warp(block.timestamp + 61);
    pool.lockRound(1);

    pool.resolveRound(1, 8150000);

    vm.stopPrank();

    (
        ,
        ,
        ,
        ,
        uint256 settlementPrice,
        ,
        ,
        PredictionPool.Direction winner,
        bool resolved,
        
    ) = pool.rounds(1);

    assertEq(settlementPrice, 8150000);
    assertEq(uint256(winner), uint256(PredictionPool.Direction.Up));
    assertEq(resolved, true);
}

function testNonResolverCannotResolveRound() public {
    vm.startPrank(address(0x456));    

    pool.createRound();
    pool.startRound(1, 8143982);

    vm.warp(block.timestamp + 61);
    pool.lockRound(1);

    vm.stopPrank();

    vm.prank(user);

    vm.expectRevert("Not resolver");
    pool.resolveRound(1, 8150000);
}

function testResolverCanResolveDown() public {
    vm.startPrank(address(0x456));

    pool.createRound();
    pool.startRound(1, 8143982);

    vm.warp(block.timestamp + 61);
    pool.lockRound(1);

    pool.resolveRound(1, 8130000);

    vm.stopPrank();

    (
        ,
        ,
        ,
        ,
        uint256 settlementPrice,
        ,
        ,
        PredictionPool.Direction winner,
        bool resolved,
        
    ) = pool.rounds(1);

    assertEq(settlementPrice, 8130000);
    assertEq(uint256(winner), uint256(PredictionPool.Direction.Down));
    assertEq(resolved, true);
}

function testResolverCanResolveDraw() public {
    vm.startPrank(address(0x456));

    pool.createRound();
    pool.startRound(1, 8143982);

    vm.warp(block.timestamp + 61);
    pool.lockRound(1);

    pool.resolveRound(1, 8143982);

    vm.stopPrank();

    (
        ,
        ,
        ,
        ,
        uint256 settlementPrice,
        ,
        ,
        PredictionPool.Direction winner,
        bool resolved,
        
    ) = pool.rounds(1);

    assertEq(settlementPrice, 8143982);
    assertEq(uint256(winner), uint256(PredictionPool.Direction.Draw));
    assertEq(resolved, true);
}

function testClaimDrawRefundsStake() public {
    usdc.mint(user, 1_000_000);

    vm.startPrank(address(0x456));

    pool.createRound();
    pool.startRound(1, 8143982);

    vm.stopPrank();

    vm.prank(user);
    usdc.approve(address(pool), 500);

    vm.prank(user);
    pool.bet(1, PredictionPool.Direction.Up, 500);

    vm.startPrank(address(0x456));

    vm.warp(block.timestamp + 61);
    pool.lockRound(1);
    pool.resolveRound(1, 8143982);

    vm.stopPrank();

    vm.prank(user);
    pool.claim(1);

    assertEq(usdc.balanceOf(user), 1_000_000);
    assertEq(usdc.balanceOf(address(pool)), 0);
}

function testCannotClaimTwice() public {
    usdc.mint(user, 1_000_000);

    vm.startPrank(address(0x456));

    pool.createRound();
    pool.startRound(1, 8143982);

    vm.stopPrank();

    vm.prank(user);
    usdc.approve(address(pool), 500);

    vm.prank(user);
    pool.bet(1, PredictionPool.Direction.Up, 500);

    vm.startPrank(address(0x456));

    vm.warp(block.timestamp + 61);
    pool.lockRound(1);
    pool.resolveRound(1, 8143982);

    vm.stopPrank();

    vm.prank(user);
    pool.claim(1);

    vm.prank(user);
    vm.expectRevert("Already claimed");
    pool.claim(1);
}

function testClaimUpWinnerGetsTotalPool() public {
    usdc.mint(user, 1_000_000);
    usdc.mint(user2, 1_000_000);

    vm.startPrank(address(0x456));

    pool.createRound();
    pool.startRound(1, 8143982);

    vm.stopPrank();

    vm.prank(user);
    usdc.approve(address(pool), 500);

    vm.prank(user2);
    usdc.approve(address(pool), 500);

    vm.prank(user);
    pool.bet(1, PredictionPool.Direction.Up, 500);

    vm.prank(user2);
    pool.bet(1, PredictionPool.Direction.Down, 500);

    vm.startPrank(address(0x456));

    vm.warp(block.timestamp + 61);
    pool.lockRound(1);
    pool.resolveRound(1, 8150000);

    vm.stopPrank();

    vm.prank(user);
    pool.claim(1);

    assertEq(usdc.balanceOf(user), 1_000_000 + 500);
    assertEq(usdc.balanceOf(address(pool)), 0);
}

function testMultipleUpWinnersSplitTotalPool() public {
    usdc.mint(user, 1_000_000);
    usdc.mint(user2, 1_000_000);

    vm.startPrank(address(0x456));

    pool.createRound();
    pool.startRound(1, 8143982);

    vm.stopPrank();

    vm.prank(user);
    usdc.approve(address(pool), 300);

    vm.prank(user2);
    usdc.approve(address(pool), 200);

    vm.prank(user);
    pool.bet(1, PredictionPool.Direction.Up, 300);

    vm.prank(user2);
    pool.bet(1, PredictionPool.Direction.Up, 200);

    vm.startPrank(address(0x456));

    vm.warp(block.timestamp + 61);
    pool.lockRound(1);
    pool.resolveRound(1, 8150000);

    vm.stopPrank();

    vm.prank(user);
    pool.claim(1);

    vm.prank(user2);
    pool.claim(1);

    assertEq(usdc.balanceOf(user), 1_000_000);
    assertEq(usdc.balanceOf(user2), 1_000_000);
    assertEq(usdc.balanceOf(address(pool)), 0);
}

function testLoserCannotClaim() public {
    usdc.mint(user, 1_000_000);
    usdc.mint(user2, 1_000_000);

    vm.startPrank(address(0x456));

    pool.createRound();
    pool.startRound(1, 8143982);

    vm.stopPrank();

    vm.prank(user);
    usdc.approve(address(pool), 500);

    vm.prank(user2);
    usdc.approve(address(pool), 500);

    vm.prank(user);
    pool.bet(1, PredictionPool.Direction.Up, 500);

    vm.prank(user2);
    pool.bet(1, PredictionPool.Direction.Down, 500);

    vm.startPrank(address(0x456));

    vm.warp(block.timestamp + 61);
    pool.lockRound(1);
    pool.resolveRound(1, 8150000);

    vm.stopPrank();

    vm.prank(user2);
    vm.expectRevert("Not a winning position");
    pool.claim(1);
}

function testSingleSidedUpPoolCanClaim() public {
    usdc.mint(user, 1_000_000);

    vm.startPrank(address(0x456));

    pool.createRound();
    pool.startRound(1, 8143982);

    vm.stopPrank();

    vm.prank(user);
    usdc.approve(address(pool), 500);

    vm.prank(user);
    pool.bet(1, PredictionPool.Direction.Up, 500);

    vm.startPrank(address(0x456));

    vm.warp(block.timestamp + 61);
    pool.lockRound(1);
    pool.resolveRound(1, 8150000);

    vm.stopPrank();

    vm.prank(user);
    pool.claim(1);

    assertEq(usdc.balanceOf(user), 1_000_000);
    assertEq(usdc.balanceOf(address(pool)), 0);
}

function testSingleSidedDownPoolCanClaim() public {
    usdc.mint(user, 1_000_000);

    vm.startPrank(address(0x456));

    pool.createRound();
    pool.startRound(1, 8143982);

    vm.stopPrank();

    vm.prank(user);
    usdc.approve(address(pool), 500);

    vm.prank(user);
    pool.bet(1, PredictionPool.Direction.Down, 500);

    vm.startPrank(address(0x456));

    vm.warp(block.timestamp + 61);
    pool.lockRound(1);
    pool.resolveRound(1, 8135000);

    vm.stopPrank();

    vm.prank(user);
    pool.claim(1);

    assertEq(usdc.balanceOf(user), 1_000_000);
    assertEq(usdc.balanceOf(address(pool)), 0);
}

function testSingleSidedUpPoolCannotClaimIfDownWins() public {
    usdc.mint(user, 1_000_000);

    vm.startPrank(address(0x456));

    pool.createRound();
    pool.startRound(1, 8_143_982);

    vm.stopPrank();

    vm.startPrank(user);
    usdc.approve(address(pool), 500);
    pool.bet(1, PredictionPool.Direction.Up, 500);
    vm.stopPrank();

    vm.startPrank(address(0x456));

    vm.warp(block.timestamp + 61);
    pool.lockRound(1);
    pool.resolveRound(1, 8_143_981);

    vm.stopPrank();

    vm.prank(user);
    vm.expectRevert("Not a winning position");
    pool.claim(1);
}

function testSingleSidedDownPoolCannotClaimIfUpWins() public {
    usdc.mint(user, 1_000_000);

    vm.startPrank(address(0x456));

    pool.createRound();
    pool.startRound(1, 8_143_982);

    vm.stopPrank();

    vm.startPrank(user);
    usdc.approve(address(pool), 500);
    pool.bet(1, PredictionPool.Direction.Down, 500);
    vm.stopPrank();

    vm.startPrank(address(0x456));

    vm.warp(block.timestamp + 61);
    pool.lockRound(1);
    pool.resolveRound(1, 8_143_983);

    vm.stopPrank();

    vm.prank(user);
    vm.expectRevert("Not a winning position");
    pool.claim(1);
}

function testMultipleDrawWinnersRefundStake() public {
    usdc.mint(user, 1_000_000);
    usdc.mint(user2, 1_000_000);

    vm.startPrank(address(0x456));

    pool.createRound();
    pool.startRound(1, 8143982);

    vm.stopPrank();

    vm.prank(user);
    usdc.approve(address(pool), 300);

    vm.prank(user2);
    usdc.approve(address(pool), 700);

    vm.prank(user);
    pool.bet(1, PredictionPool.Direction.Up, 300);

    vm.prank(user2);
    pool.bet(1, PredictionPool.Direction.Down, 700);

    vm.startPrank(address(0x456));

    vm.warp(block.timestamp + 61);
    pool.lockRound(1);
    pool.resolveRound(1, 8143982);

    vm.stopPrank();

    vm.prank(user);
    pool.claim(1);

    vm.prank(user2);
    pool.claim(1);

    assertEq(usdc.balanceOf(user), 1_000_000);
    assertEq(usdc.balanceOf(user2), 1_000_000);
    assertEq(usdc.balanceOf(address(pool)), 0);
}

function testCannotBetAfterRoundLocked() public {
    usdc.mint(user, 1_000_000);

    vm.startPrank(address(0x456));

    pool.createRound();
    pool.startRound(1, 8143982);

    vm.warp(block.timestamp + 61);
    pool.lockRound(1);

vm.stopPrank();

    vm.prank(user);
    usdc.approve(address(pool), 500);

    vm.prank(user);
    vm.expectRevert("Round is locked");
    pool.bet(1, PredictionPool.Direction.Up, 500);
}

}
