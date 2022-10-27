# Furo-Automated-Tasks

This repository containes a bunch of contracts taking advantage of gelato keepers to execute automatic withdraw/claim on Furo streams and vestings.

To use these contracts, users have to approve and deposit their Furo NFTs on these contracts using the createTask() function (<!> Direct transfer will result in a burn <!>).
Users must also pay for the fees by calling fund() or sending native tokens to the clone created by the factory.

### 1 - FuroAutomatedTime

This contract allows a Furo user to execute automatic withdrawal based on time.

Ex: Withdraw from stream every 7 days and send to a chosen address like a centralised exchange.

Users can select the time between each withdraw, the recipient, if should be in bentobox and a calldata to be executed on the recipient on each withdraw (useful if the recipient is a contract, ex: swap or bridge the tokens received).

##### Deployements: 
Goerli:
-  Implementation: [0x7BBDf0881D053bAeC144Cf79c3eB3ca9dCe86d17](https://goerli.etherscan.io/address/0x7BBDf0881D053bAeC144Cf79c3eB3ca9dCe86d17)
-  Factory: [0xEC18AdD9FBBA16E9eaC2f7577928537E7aAc7DfD](https://goerli.etherscan.io/address/0xEC18AdD9FBBA16E9eaC2f7577928537E7aAc7DfD)
  
Polygon:
-  Implementation: [](https://polygonscan.com/address/)
-  Factory: [](https://polygonscan.com/address/)  

### 1 - FuroAutomatedAmount

This contract allows a Furo user to execute automatic withdrawal based on amount available to withdraw.

Ex: Withdraw from stream when 100 usdc are claimable and send to a chosen address like a centralised exchange.

Users can select the amount to execute the withdraw, the recipient, if should be in bentobox and a calldata to be executed on the recipient on each withdraw (useful if the recipient is a contract, ex: swap or bridge the tokens received).

##### Deployements: 
Goerli:
-  Implementation: [0x1506788CC107Ff347CDb33956AC601c2303c1E7D](https://goerli.etherscan.io/address/0x1506788CC107Ff347CDb33956AC601c2303c1E7D)
-  Factory: [0x7ABC6f251ce41fc13F775E32D159FFF96A544E8A](https://goerli.etherscan.io/address/0x7ABC6f251ce41fc13F775E32D159FFF96A544E8A)
  
Polygon:
-  Implementation: [](https://polygonscan.com/address/)
-  Factory: [](https://polygonscan.com/address/)