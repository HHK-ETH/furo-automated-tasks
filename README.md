# Furo-Automated-Tasks

This repository containes a bunch of contracts taking advantage of chainlink keepers to execute automatic withdraw/claim on Furo streams and vestings.

To use these contracts, users have to approve and deposit their Furo NFTs on these contracts using the createTask() function (<!> Direct transfer will result in a burn <!>).
Users must also pay for the fees by calling fund() or sending native tokens to the clone created by the factory.

### 1 - FuroAutomatedTime

This contract allows a Furo user to execute automatic withdrawal based on time.

Ex: Withdraw from stream every 7 days and send to a chosen address like a centralised exchange.

Users can select the time between each withdraw, the recipient, if should be in bentobox and a calldata to be executed on the recipient on each withdraw (useful if the recipient is a contract, ex: swap or bridge the tokens received).

##### Deployements: 
Goerli ==> [0x3D80B2f148F22Ec150A5dA78e86f479dc1E34b9F](https://goerli.etherscan.io/address/0x3d80b2f148f22ec150a5da78e86f479dc1e34b9f)