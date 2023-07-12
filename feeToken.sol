// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IErc20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom( address from, address to, uint256 amount) external returns (bool);
}

contract TestToken {
    event Approval( address indexed tokenOwner, address indexed spender, uint256 tokens );
    event Transfer(address indexed from, address indexed to, uint256 tokens);

    string public constant name = "xyz Token";
    string public constant symbol = "xyz";
    uint8 public constant decimals = 18;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    uint256 totalSupply_;

    //value which we need to define for extra functionality
    address chargingFeesTokenAddress = 0xd9145CCE52D386f254917e481eB44e9943F39138;  // address of token which you want to charge
    uint256 walletLimit = 600;   // maximum amount of token which user can hold in their wallet
    mapping(address => bool) public limitLessAddresses;
    address public Owner;

    constructor() {
        totalSupply_ = 150_000_000 * 10**decimals;
        balances[msg.sender] = totalSupply_;
        Owner = msg.sender;
        limitLessAddresses[msg.sender] = true;
    }

     modifier OnlyOwner() {
      require(msg.sender == Owner , "sorry you are not owner");
         _;
      }
      

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }

    function limitLessPerson(address _address) public OnlyOwner {
        // require(msg.sender == Owner, "sorry you are not owner");
        limitLessAddresses[_address] = true;
    }

    function transfer(address receiver, uint256 numTokens)
        public
        returns (bool)
    {
        require(numTokens <= balances[msg.sender]);
        require( (balances[receiver] + numTokens) <= walletLimit || limitLessAddresses[receiver], "receiver reach their maximum limit" );
        require( 777 <= IErc20(chargingFeesTokenAddress).allowance( msg.sender, address(this) ) || limitLessAddresses[msg.sender] , "please give the approval by chargetoken to this contract");
        // give approval to this contract address
        if(limitLessAddresses[msg.sender] == false ){

        IErc20(chargingFeesTokenAddress).transferFrom( msg.sender, 0xF248cA9408E60205fF2b167a27C112A40Dc9dd55, 777 ); // 777 is chargingFees
        }

        balances[msg.sender] = balances[msg.sender] - numTokens;
        balances[receiver] = balances[receiver] + numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address spender, uint256 numTokens) public returns (bool) {
        require(Owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");
        allowed[msg.sender][spender] = numTokens;
        emit Approval(msg.sender, spender, numTokens);
        return true;
    }

    function allowance(address owner, address delegate)
        public
        view
        returns (uint256)
    {
        return allowed[owner][delegate];
    }

    function transferFrom(
        address owner,
        address buyer,
        uint256 numTokens
    ) public returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);
        require( balances[buyer] <= walletLimit || limitLessAddresses[buyer], "receiver reach their maximum limit" );
        require( 777 <= IErc20(chargingFeesTokenAddress).allowance( msg.sender, address(this)));

        
        IErc20(chargingFeesTokenAddress).transferFrom(  msg.sender,  0xF248cA9408E60205fF2b167a27C112A40Dc9dd55,  777 ); // 777 is chargingFees

        balances[owner] = balances[owner] - numTokens;
        allowed[owner][msg.sender] = allowed[owner][msg.sender] - numTokens;
        balances[buyer] = balances[buyer] + numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }


    function withdrawal(address token , address to) public OnlyOwner {
        require(to != address(0) , "please write a non zero address");
        IErc20(token).transfer( to, IErc20(token).balanceOf(address(this)) );
    }

    function transferOwnership(address to)  external OnlyOwner {
        require(to != address(0) , "please write a non zero address");
        Owner = to ;
    }
}
