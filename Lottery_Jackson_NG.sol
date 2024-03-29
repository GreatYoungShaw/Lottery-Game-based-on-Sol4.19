/*
   Lottery Contract
*/
pragma solidity ^0.4.19;
import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";

/*
betNumber will store the number that the punter bets on and result will store the number that was randomly generated. Both variables are declared public because of transparency - both the punter and the house needs to see them.
*/

contract Lottery is usingOraclize {
    string public betNumber;
    string public result;
    address public house;
    address public better;
    enum State { Created, Betted, Paidout, Inactive }
    State public state;
    
    event newOraclizeQuery(string description);
    event Aborted();
    event Betted();
    event Released();
	// it is a constructor
    function Lottery() public payable {
        house = msg.sender;
        state = State.Created;
    }

    modifier condition(bool _condition) {
        require(_condition);
        _;
    }

    modifier onlyBetter() {
        require(msg.sender == better);
        _;
    }

    modifier onlyHouse() {
        require(msg.sender == house);
        _;
    }

    modifier inState(State _state) {
        require(state == _state);
        _;
    }

	//source: https://ethereum.stackexchange.com/questions/30912/how-to-compare-strings-in-solidity
    // compare string for lottery rather than int
    function compareStrings (string a, string b) view returns (bool){
       return keccak256(a) == keccak256(b);
	}
	
    function bet(string _betNumber)
        public
        inState(State.Created)
        condition(msg.value == (1 ether))
        payable
    {
        Betted();
        better = msg.sender;
        betNumber = _betNumber;
        state = State.Betted;
    }
    
    function abort()
        public
        onlyHouse
        inState(State.Created)
    {
        Aborted();
        state = State.Inactive;
        house.transfer(address(this).balance);
    }
    
    function release() 
        payable 
        public
        onlyHouse
        inState(State.Betted)
    {
        if (oraclize_getPrice("URL") > this.balance) {
            newOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            newOraclizeQuery("Oraclize query was sent, standing by for the answer..");
            oraclize_query("URL", "json(https://jacksonng.org/codetest/random.php/).random");
        }
    }
	
	function __callback(bytes32 myid, string res) {
        if (msg.sender != oraclize_cbAddress()) throw;
        result = res; 
        // itf the punter get the right number
        if (compareStrings(result,betNumber)) {
            better.transfer(address(this).balance);            
        }
        //else, all money to the banker
        else {
            house.transfer(address(this).balance);               
        }
// gamble is over and reset state to Paidout.
        Released();
        state = State.Paidout;
    }
    
}