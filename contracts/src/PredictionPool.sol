// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function transfer(
    address to,
    uint256 value
    ) external returns (bool);

}

contract PredictionPool {

    IERC20 public usdc;
    address public resolver;

    constructor(address _usdc, address _resolver) {
    usdc = IERC20(_usdc);
    resolver = _resolver;
    }

    uint256 public roundId;
    uint256 public startTime;
    uint256 public endTime;

enum Direction {
    None,
    Up,
    Down,
    Draw
}

struct Position {
    uint256 amount;
    Direction direction;
    bool claimed;
}

struct Round {
    uint256 id;
    uint256 startTime;
    uint256 endTime;
    uint256 referencePrice;
    uint256 settlementPrice;
    uint256 upPool;
    uint256 downPool;
    Direction winner;
    bool resolved;
    bool locked;
}

    mapping(uint256 => Round) public rounds;
    mapping(uint256 => mapping(address => Position)) public positions;

function createRound() public {
    _onlyResolver();
    roundId++;

    rounds[roundId] = Round({
    id: roundId,
    startTime: 0,
    endTime: 0,
    referencePrice: 0,
    settlementPrice: 0,
    upPool: 0,
    downPool: 0,
    winner: Direction.None,
    resolved: false,
    locked: false
});

}

function startRound(
    uint256 _roundId,
    uint256 _referencePrice
) public {
    _onlyResolver();

    Round storage round = rounds[_roundId];

    require(round.id != 0, "Round does not exist");
    require(round.startTime == 0, "Round already started");
    require(_referencePrice > 0, "Reference price must be greater than zero");

    round.startTime = block.timestamp;
    round.endTime = block.timestamp + 60;
    round.referencePrice = _referencePrice;
}

function lockRound(uint256 _roundId) public {
    _onlyResolver();

    Round storage round = rounds[_roundId];

    require(round.id != 0, "Round does not exist");
    require(round.startTime != 0, "Round not started");
    require(block.timestamp >= round.endTime, "Round is still open");
    require(!round.locked, "Round already locked");

    round.locked = true;
}

function _onlyResolver() internal view {
    require(msg.sender == resolver, "Not resolver");
}

function resolveRound(
    uint256 _roundId,
    uint256 _settlementPrice
) public {
    _onlyResolver();

    Round storage round = rounds[_roundId];

    require(round.id != 0, "Round does not exist");
    require(round.locked, "Round not locked");
    require(!round.resolved, "Round already resolved");
    require(_settlementPrice > 0, "Settlement price must be greater than zero");

    round.settlementPrice = _settlementPrice;

    if (_settlementPrice > round.referencePrice) {
        round.winner = Direction.Up;
    } else if (_settlementPrice < round.referencePrice) {
        round.winner = Direction.Down;
    } else {
        round.winner = Direction.Draw;
    }

    round.resolved = true;
}

function claim(uint256 _roundId) public {
    Round storage round = rounds[_roundId];
    Position storage position = positions[_roundId][msg.sender];

    require(round.resolved, "Round not resolved");
    require(position.amount > 0, "No position");
    require(!position.claimed, "Already claimed");

uint256 payout;

if (round.winner == Direction.Draw) {
    payout = position.amount;
} else {
    require(
        position.direction == round.winner,
        "Not a winning position"
    );

    uint256 totalPool = round.upPool + round.downPool;
    uint256 winningPool;

    if (round.winner == Direction.Up) {
        winningPool = round.upPool;
    } else {
        winningPool = round.downPool;
    }

    payout = position.amount * totalPool / winningPool;
}

    position.claimed = true;

    require(
        usdc.transfer(msg.sender, payout),
        "USDC transfer failed"
    );
}

function bet(
    uint256 _roundId,
    Direction _direction,
    uint256 _amount
) public {
    Round storage round = rounds[_roundId];

    require(round.id != 0, "Round does not exist");
    require(round.startTime != 0, "Round not started");
    require(!round.locked, "Round is locked");
    require(block.timestamp < round.endTime, "Round is closed");

    require(
    _direction == Direction.Up || _direction == Direction.Down,
    "Invalid direction"
);
    require(_amount > 0, "Amount must be greater than zero");
    require(
    usdc.transferFrom(msg.sender, address(this), _amount),
    "USDC transfer failed"
    );
    
    require(
    positions[_roundId][msg.sender].amount == 0,
    "Position already exists"
);

positions[_roundId][msg.sender] = Position({
    amount: _amount,
    direction: _direction,
    claimed: false
});

if (_direction == Direction.Up) {
    round.upPool += _amount;
} else {
    round.downPool += _amount;
}

}

}
