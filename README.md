# Furo-Automated-Tasks

This repository containes a bunch of contracts taking advantage of chainlink keepers to execute automatic withdraw/claim on Furo streams and vestings.

To use these contracts, users have to approve and deposit their Furo NFTs on these contracts using the createTask() function (<!> Direct transfer will result in a burn <!>).

### 1 - FuroAutomatedTimeWithdraw

This contract allows a Furo user to execute automatic withdrawal based on time.

Ex: Withdraw from stream every 7 days and send to a chosen address like a centralised exchange.

Users can select the time between each withdraw, the recipient, if should be in bentobox and a calldata to be executed on the recipient on each withdraw (useful if the recipient is a contract, ex: swap or bridge the tokens received).