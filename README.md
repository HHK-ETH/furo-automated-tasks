# Furo-Automated-Tasks

This repository containes a bunch of contracts taking advantage of chainlink keepers to execute automatic withdraw/claim on Furo streams and vestings.

To use these contracts, users have to approve and deposit their Furo NFTs on these contracts using the createTask() function (<!> Direct transfer will result in a burn <!>).
Users must also pay for the fees by calling fund() or sending native tokens to the clone created by the factory.

### 1 - FuroAutomatedTime

This contract allows a Furo user to execute automatic withdrawal based on time.

Ex: Withdraw from stream every 7 days and send to a chosen address like a centralised exchange.

Users can select the time between each withdraw, the recipient, if should be in bentobox and a calldata to be executed on the recipient on each withdraw (useful if the recipient is a contract, ex: swap or bridge the tokens received).

##### Deployements: 
Goerli:
-  Implementation: [0x6059AE4BAE2cB70e3733217145967C58f28727EA](https://goerli.etherscan.io/address/0x6059AE4BAE2cB70e3733217145967C58f28727EA)
-  Factory: [0xC18bd9397d3af5dF1e916f64783CA9D90Dc8352D](https://goerli.etherscan.io/address/0xC18bd9397d3af5dF1e916f64783CA9D90Dc8352D)