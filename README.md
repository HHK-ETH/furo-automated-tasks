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
-  Implementation: [0x8dAE118A00138cD081Ed8e4cc4a9e51520D452F8](https://goerli.etherscan.io/address/0x8dAE118A00138cD081Ed8e4cc4a9e51520D452F8)
-  Factory: [0xb5A0699004Bd885C1adF1540A21DC31Addb674DC](https://goerli.etherscan.io/address/0xb5A0699004Bd885C1adF1540A21DC31Addb674DC)
-  
Polygon:
-  Implementation: [0xfd15bcE6f24070CbE06E2cBC2C61f24E878018ab](https://polygonscan.com/address/0xfd15bcE6f24070CbE06E2cBC2C61f24E878018ab)
-  Factory: [0x959704324b257b4603B0931550212e1522E70c4A](https://polygonscan.com/address/0x959704324b257b4603B0931550212e1522E70c4A)