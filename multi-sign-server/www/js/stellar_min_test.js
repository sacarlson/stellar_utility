"use strict";
   
    // Initialize everything when the window finishes loading
    window.addEventListener("load", function(event) {
     
      var text = document.getElementById("text");
      var message = document.getElementById("message");
      var account = document.getElementById("account");
      var destination = document.getElementById("destination");
      var seed = document.getElementById("seed");
      var amount = document.getElementById("amount");
      amount.value = "1";      
     
      seed.value = 'SDHOAMBNLGCE2MV5ZKIVZAQD3VCLGP53P3OBSBI6UN5L5XZI5TKHFQL4'; 
      destination.value = 'GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO';
      //var server = new stellar.Server({
      var server = new StellarSdk.Server({     
        hostname: 'horizon-testnet.stellar.org',
        port: 443,
        secure: true
      });

      StellarSdk.Network.useTestNet();

      var key = StellarSdk.Keypair.fromSeed(seed.value);
      account.value = key.address();
      //var destination = document.getElementById("destination");

      // master account seed always has funds in testnet
      //var seed = 'SDHOAMBNLGCE2MV5ZKIVZAQD3VCLGP53P3OBSBI6UN5L5XZI5TKHFQL4';
      //var key = StellarSdk.Keypair.fromSeed(seed);
      //var destination = 'GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO';
      //var amount = "1";
      
        
      send_tx.addEventListener("click", function(event) {         
        message.textContent = "started";
        key = StellarSdk.Keypair.fromSeed(seed.value);
        //account.value = key.address();
        function createContractAccount(key) {
          server.loadAccount(key.address())
          .then(function (account) {
            var transaction = new StellarSdk.TransactionBuilder(account,{fee:100})
            .addOperation(StellarSdk.Operation.payment({
              destination: destination.value,
              amount: amount.value,
              asset: StellarSdk.Asset.native(),
            }))          
           .addSigner(key)
           .build();
          
           console.log(transaction.toEnvelope().toXDR().toString("base64"));
           message.textContent = transaction.toEnvelope().toXDR().toString("base64");
           //return server.submitTransaction(transaction);           
          })
          .then(console.log)
          .catch(console.log);
        }
        createContractAccount(key);
      });

    });
