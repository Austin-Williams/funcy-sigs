# funcy-sigs
Grinding Solidity function names for fun and profit

## Status
I'm NOT working on this. It's just a prototype I built for fun.

I really want someone to use it for their hackathon project.

I've wanted this service to exist for a few years now, but it still doesn't.

Hopefully this helps a little. :)

## About
For gas-optimization reasons, it is sometimes useful for Solidity devs to use function names that have a function signature with many laeding zeros. It can also be useful to control which functions have signatures that are larger or smaller than other functions in the same contract, because functions with smaller function signatures are "found" more quickly (and thus with less gas) than functions with larger function signatures.

For these reasons, having control over function signatures is nice. However, it requires a non-trivial amount of work to *find* function names that have the desired function signature. For a given ordered set of input types, one can always check www.4byte.directory to see if anyone has already found a function name that will work for them. Otherwise, they have to go through the effort to guess-and-check to find a function name with the desired function signature.

This is a prototype contract that allows devs to offer a reward for someone to do that guess-and-check work for them. They simply post a function name prefix (optional), the inputs to their function, and a desired function signature. Then anyone else can do the work to find a function name (with the desired prefix) that has the desired function signature, and claim the reward.

Current orders can be found by grabbing all the OrderUpdate events. For a given orderID, the most recent OrderUpdate with that orderID will have a offerInWei value that indicates how much the reward is for that order.

## Please take this idea and run with it
I would be very happy if someone "completed" this project during a hackathon. :)
It needs a UI, maybe an open-source function-name-searcher script that anyone can run, etc.
Bonus points if the UI uses flashbots RPC to protect the solvers from getting frontrun.
Double bonus points if you have some always-on service somewhere that monitors the chain for orders and fills them if they are profitable enough.
