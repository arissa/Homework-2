pragma solidity ^0.4.15;

contract Betting {
	/* Standard state variables */
	address public owner;
	address public gamblerA;
	address public gamblerB;
	address public oracle;
	uint[] outcomes;	// Feel free to replace with a mapping

	/* Structs are custom data structures with self-defined parameters */
	struct Bet {
		uint outcome;
		uint amount;
		bool initialized;
	}

	/* Keep track of every gambler's bet */
	mapping (address => Bet) bets;
	/* Keep track of every player's winnings (if any) */
	mapping (address => uint) winnings;

	/* Add any events you think are necessary */
	event BetMade(address gambler);
	event BetClosed();

	/* Uh Oh, what are these? */
	modifier OwnerOnly() {
		if (msg.sender == owner) {
			_;
		}
	}
	modifier OracleOnly() {
		if (msg.sender == oracle){
			_;
		}
	}

	/* Constructor function, where owner and outcomes are set */
	function Betting(uint[] _outcomes) {
		owner = msg.sender;
		outcomes = _outcomes;
	}

	/* Owner chooses their trusted Oracle */
	function chooseOracle(address _oracle) OwnerOnly() returns (address) {
		oracle = _oracle;
		return oracle;
	}

/* Gamblers place their bets, preferably after calling checkOutcomes */
	function makeBet(uint _outcome) payable returns (bool) {
		// owner and oracle cannot bet
		if (msg.sender == oracle || msg.sender == owner) {
			return false;
		}
		//a gambler cannot bet twice
		if (bets[msg.sender].initialized) {
			return false;
		}
		var possibleOutcomes = checkOutcomes();
		bool isValidOutcome;
		for (uint i = 0; i < possibleOutcomes.length; i++) {
			if (possibleOutcomes[i] == _outcome) {
				isValidOutcome = true;
			}
		}
		if (!isValidOutcome) { return false; }

		if (!(bets[gamblerA].initialized)) {
			gamblerA = msg.sender;
		}
		else if (!(bets[gamblerB].initialized)) {
			gamblerB = msg.sender;
		}
		else {
			return false;
		}
		bets[msg.sender] = Bet(_outcome, msg.value, true);
		bets[msg.sender].initialized = true;
		BetMade(msg.sender);
		return true;

	}
	/* The oracle chooses which outcome wins */
	function makeDecision(uint _outcome) OracleOnly() {
		if (!(bets[gamblerA].initialized) || !(bets[gamblerB].initialized)){
			return;
		}
		uint total = bets[gamblerA].amount + bets[gamblerB].amount;
		// if all gamblers bet on the same outcome, reimburse all funds
		if (bets[gamblerA].outcome == bets[gamblerB].outcome) {
			winnings[gamblerA] += bets[gamblerA].amount;
			winnings[gamblerB] += bets[gamblerB].amount;
		}
		// if gamblerA wins
		else if (bets[gamblerA].outcome == _outcome) {
			winnings[gamblerA] += total;
		}

		// if gamblerB wins
		else if (bets[gamblerB].outcome == _outcome) {
			winnings[gamblerB] += total;
		}

		// if nobody wins, money goes to the oracle
		else {
			winnings[oracle] = total;
		}
		contractReset();

	}

	/* Allow anyone to withdraw their winnings safely (if they have enough) */
	function withdraw(uint withdrawAmount) returns (uint remainingBal) {
		if (withdrawAmount > winnings[msg.sender]) {
			return winnings[msg.sender];
		}
		winnings[msg.sender] -= withdrawAmount;
		msg.sender.transfer(withdrawAmount);
		return winnings[msg.sender];
	}
	
	/* Allow anyone to check the outcomes they can bet on */
	function checkOutcomes() constant returns (uint[]) {
		return outcomes;
	}
	
	/* Allow anyone to check if they won any bets */
	function checkWinnings() constant returns(uint) {
		return winnings[msg.sender];
	}

	/* Call delete() to reset certain state variables. Which ones? That's upto you to decide */
	function contractReset() private {
		delete(gamblerA);
		delete(gamblerB);
		delete(oracle);
		delete(bets[gamblerA]);
		delete(bets[gamblerB]);
	}

	/* Fallback function */
	function() payable {
		revert();
	}
}
