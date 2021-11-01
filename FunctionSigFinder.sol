// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/*  For gas-optimization reasons, it is sometimes useful for Solidity devs to use function names that have a function signature with many laeding zeros.
    It can also be useful to control which functions have signatures that are larger or smaller than other functions in the same contract, because functions 
    with smaller function signatures are "found" more quickly (and thus with less gas) than functions with larger function signatures.
    
    For these reasons, having control over function signatures is nice. However, it requires a non-trivial amount of work to *find* function names that have
    the desired function signature. For a given ordered set of input types, one can always check www.4byte.directory to see if anyone has already found a function name
    that will work for them. Otherwise, they have to go through the effort to guess-and-check to find a function name with the desired function signature.

    This is a prototype contract that allows devs to offer a reward for someone to do that guess-and-check work for them. They simply post a function name prefix (optional),
    the inputs to their function, and a desired function signature. Then anyone else can do the work to find a function name (with the desired prefix) that has the desired
    function signature, and claim the reward.
    
    Current orders can be found by grabbing all the OrderUpdate events. For a given orderID, the most recent OrderUpdate with that orderID will have a offerInWei value
    that indicates how much the reward is for that order.
*/
contract FunctionSigFinder {
    
    struct Order {
        string prefix;
        string inputTypes; // comma seperated, no parenthesis on the ends, no spaces after the commas
        bytes4 targetSig;
        uint256 offerInWei;
    }
    
    mapping(uint256 => Order) orders; // orderID -> Order
    
    event OrderUpdate(uint256 indexed orderID, string prefix, string inputTypes, bytes4 targetSig, uint256 offerInWei, string solution);
    
    /*  @notice Creates an order for someone to find a function name with your desired function signature
        @param _prefix The prefix (if any) of the function name.
            E.g., if you want your function name to have the form "SwapTokens_XXXXX" then your _prefix would be "SwapTokens_".
        @param _inputTypes A comma-separated list of input types for your function (with no spaces and no parenthesis).
            E.g., if your function accepts two uints and an address, then your _inputTypes would be "uint256,uint256,address".
            E.g., if your function does not accept any inputs, then your _inputTypes would be the empty string "".
        @param _targetSig The function signature you want your function to have.
            E.g., If you want your function signature to be 0x00000000 then your _targetSig would be 0x00000000.
        @notice The amount of ETH you send with the function is what will be awarded to whoever finds your desired function name.
            WARNING: refunds are not possible.
        @returns The orderID for your order. This will be used by whoever ends up filling your order.
    */
    function placeOrder(string calldata _prefix, string calldata _inputTypes, bytes4 _targetSig) external payable returns (uint256) {
        uint256 orderID = uint256(keccak256(abi.encodePacked(_prefix, _inputTypes, _targetSig)));
        
        if (orders[orderID].offerInWei == 0) {
            // new order!
            Order memory newOrder = Order(_prefix, _inputTypes, _targetSig, msg.value);
            orders[orderID] = newOrder;
            emit OrderUpdate(orderID, _prefix, _inputTypes, _targetSig, msg.value, "");
        } else {
            // adding money to existing order
            orders[orderID].offerInWei += msg.value;
            Order memory order = orders[orderID]; // memoize
            emit OrderUpdate(orderID, order.prefix, order.inputTypes, order.targetSig, order.offerInWei, "");
        }
        
        return orderID;
    }
    
    /*  @notice Allows anyone to fill an order 
        @notice WARNING: It would be wise to submit your solution using Flashbots so you don't get frontrun. Even then, mind the occassional uncle.
        @param _orderID The orderID of the order you are trying to fill.
        @param _solution The solution you found.
            E.g., Suppose the order had the _prefix "randallAteMySandwich_", had _inputParams "bytes", and had a targetSig of 0x00000000.
            Then perhaps your _solution would be "atrxxnf" because randallAteMySandwich_atrxxnf(bytes) has a function signature of 0x00000000.
    */
    function fillOrder(uint256 _orderID, string calldata _solution) external {
        require(bytes(_solution).length < 20, "solution too long");
        Order memory order = orders[_orderID];
        string memory preimage = string(abi.encodePacked(order.prefix, _solution, "(", order.inputTypes, ")"));
        require(computeFunctionSig(preimage) == order.targetSig, "bad solution");
        delete orders[_orderID];
        emit OrderUpdate(_orderID, order.prefix, order.inputTypes, order.targetSig, 0, _solution);
        payable(msg.sender).call{value: order.offerInWei}("");
    }
    
    // e.g. input "account_info_rotate_tine(uint256)" would give output: 0x00000001
    function computeFunctionSig(string memory _preimage) public pure returns (bytes4) {
        return bytes4(keccak256(bytes(_preimage)));
    }
}
