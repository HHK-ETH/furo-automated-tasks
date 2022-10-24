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
-  Implementation: [0xf385923a02f30669c62914DA5B547E5eE509385A](https://goerli.etherscan.io/address/0xf385923a02f30669c62914DA5B547E5eE509385A)
-  Factory: [0xfDb37D0B81Dd83c2a842E498913Ae968E3629360](https://goerli.etherscan.io/address/0xfDb37D0B81Dd83c2a842E498913Ae968E3629360)
  
Polygon:
-  Implementation: [](https://polygonscan.com/address/)
-  Factory: [](https://polygonscan.com/address/)  

### 1 - FuroAutomatedTime

This contract allows a Furo user to execute automatic withdrawal based on amount available to withdraw.

Ex: Withdraw from stream when 100 usdc are claimable and send to a chosen address like a centralised exchange.

Users can select the amount to execute the withdraw, the recipient, if should be in bentobox and a calldata to be executed on the recipient on each withdraw (useful if the recipient is a contract, ex: swap or bridge the tokens received).

##### Deployements: 
Goerli:
-  Implementation: [0x0a2bA55A98e1C7d3DA853D1f00DD1Be27c27A074](https://goerli.etherscan.io/address/0x0a2bA55A98e1C7d3DA853D1f00DD1Be27c27A074)
-  Factory: [0xF51c779f635B5412e2A129a7fdD76409acEB3b18](https://goerli.etherscan.io/address/0xF51c779f635B5412e2A129a7fdD76409acEB3b18)
  
Polygon:
-  Implementation: [](https://polygonscan.com/address/)
-  Factory: [](https://polygonscan.com/address/)