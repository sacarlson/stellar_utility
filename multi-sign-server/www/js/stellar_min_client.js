"use strict";
   
    // Initialize everything when the window finishes loading
    window.addEventListener("load", function(event) {
     
      var network_testnet = document.getElementById("network_testnet");
      var message = document.getElementById("message");
      var account = document.getElementById("account");
      var destination = document.getElementById("destination");
      var dest_seed = document.getElementById("dest_seed");
      var seed = document.getElementById("seed");
      var tissuer = document.getElementById("tissuer");
      var tasset = document.getElementById("tasset");
      var amount = document.getElementById("amount");
      var balance = document.getElementById("balance");
      var CHP_balance = document.getElementById("CHP_balance");
      var asset_type = document.getElementById("asset_type");
      var dest_balance = document.getElementById("dest_balance");
      var dest_CHP_balance = document.getElementById("dest_CHP_balance");
      var asset_obj = new StellarSdk.Asset.native();
      amount.value = "1";      
      asset_type.value = "CHP";
      seed.value = 'SDHOAMBNLGCE2MV5ZKIVZAQD3VCLGP53P3OBSBI6UN5L5XZI5TKHFQL4'; 
      tissuer.value = 'GAMB56CPYXJZUM2QSWXTUFSFIWMNHB6GZBUFJ2YJQJRGW6WH223NRLND'
      tasset.value = 'CHP'
      destination.value = 'GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO';
      dest_seed.value = "";

      StellarSdk.Network.useTestNet();
      var hostname = "horizon-testnet.stellar.org"
            
      var server = new StellarSdk.Server({     
        hostname: hostname,
        port: 443,
        secure: true
      });
      current_mode.value = "Stellar TestNet";

      var key = StellarSdk.Keypair.fromSeed(seed.value);
      update_key();  
      update_balances();

      function get_account_info(account,params,callback) {
        console.log("start get_account_info");
        server.accounts()
        .address(account)
        .call()
        .then(function (accountResult) {
          //console.log(accountResult);
          callback(accountResult,params);                    
        })
        .catch(function (err) {
          console.log("got error in get_account_info");
          console.error(err);
          callback(err,params);          
        })
      }

      function display_message(param) {
        message.textContent = JSON.stringify(param);
      }


      function display_balance(account_obj,params) {          
          var balance = 0;
          account_obj.balances.forEach(function(entry) {
            if (entry.asset_code == params.asset_code) {
              balance = entry.balance;
            }                          
          });
          window[params.to_id].value = balance;
          if (params.detail == true) {
            display_message(account_obj);
          }
          return account_obj;          
        }

      
       function get_balance(account,to_id,asset) {         
         get_account_info(account,{to_id:to_id,asset:asset},display_balance)
       } 
     
      function update_key() {
        key = StellarSdk.Keypair.fromSeed(seed.value);
        account.value = key.address();
      }
      
      function update_balances_set(account_obj,params) {
        display_balance(account_obj,{to_id:params.to_id1,
          asset_code:params.asset_code1,
          detail:false}
        );

        display_balance(account_obj,{
          to_id:params.to_id2,
          asset_code:params.asset_code2,
          detail:params.detail}
        );
      }

      function update_balances() {
        get_account_info(account.value,{
          to_id1:"balance",
          asset_code1:null,
          to_id2:"CHP_balance",
          asset_code2:asset_type.value,
          detail:true},update_balances_set);

        get_account_info(destination.value,{
          to_id1:"dest_balance",
          asset_code1:null,
          to_id2:"dest_CHP_balance",
          asset_code2:asset_type.value,
          detail:false
        },update_balances_set);        
      }

      
      function createAccount(key) {
          var operation = createAccountOperation();
          createTransaction(key,operation);
        }

      function sendPaymentTransaction() {
        var key = StellarSdk.Keypair.fromSeed(seed.value);
        if (asset.value== "native") {
          var asset_obj = new StellarSdk.Asset.native();
          if (dest_balance.value == 0){
            if (amount.value < 20) {
              message.textContent = "destination account not active must send min 20 native";
              return;
            }
            createAccount(key);
          }else {
            createPaymentTransaction(key,asset_obj);
          }
        }else {
          if (dest_balance.value == 0){
            message.textContent = "destination account not active, can only send native";
            return;
          }
          var asset_obj = new StellarSdk.Asset(asset.value, issuer.value);
        }
        message.textContent = "started payment: ";
        createPaymentTransaction(key,asset_obj);
      }    
  

      function createPaymentTransaction(key,asset_obj) {
          var operation = createPaymentOperation(asset_obj);
          createTransaction(key,operation);
        }

      function createTransaction(key,operation) {
        server.loadAccount(key.address())
          .then(function (account) {
            var transaction = new StellarSdk.TransactionBuilder(account,{fee:100})
            .addOperation(operation)          
            .addSigner(key)
            .build();                     
           server.submitTransaction(transaction);           
          })
          .then(function (transactionResult) {
            console.log(transactionResult);
            //console.log(transaction.toEnvelope().toXDR().toString("base64"));
            //message.textContent = transaction.toEnvelope().toXDR().toString("base64");
          })
          .catch(function (err) {
            console.log(err);
          });
        }

      function createPaymentOperation(asset_obj) {
                 return StellarSdk.Operation.payment({
                   destination: destination.value,
                   amount: amount.value,
                   asset: asset_obj
                 });
               }

      function createAccountOperation() {
                 return StellarSdk.Operation.createAccount({
                   destination: destination.value,
                   startingBalance: amount.value
                 });
               }

      function addSignerOperation(secondAccountAddress,weight) {
                 return StellarSdk.Operation.setOptions({
                   signer: {
                     address: secondAccountAddress,
                     weight: weight
                   }
                 });
               }

      function addTrustlineOperation(asset_type, address) {
                 //asset_type examples "USD", "CHP"
                 asset = new StellarSdk.Asset(asset_type, address);
                 return StellarSdk.Operation.changeTrust({asset: asset}); 
               }

      function setOptionsOperation() {
                 var opts = {};
                 opts.inflationDest = "GDGU5OAPHNPU5UCLE5RDJHG7PXZFQYWKCFOEXSXNMR6KRQRI5T6XXCD7";
                 opts.clearFlags = 1;
                 opts.setFlags = 1;
                 opts.masterWeight = 0;
                 opts.lowThreshold = 1;
                 opts.medThreshold = 2;
                 opts.highThreshold = 3;

                 opts.signer = {
                  address: "GDGU5OAPHNPU5UCLE5RDJHG7PXZFQYWKCFOEXSXNMR6KRQRI5T6XXCD7",
                  weight: 1
                 };
                 opts.homeDomain = "www.example.com";
                 return StellarSdk.Operation.setOptions(opts);
               }

    
     
      change_network.addEventListener("click", function(event) { 
        console.log("mode: " + network.value);        
        if(network.value === "testnet" ) {
          StellarSdk.Network.useTestNet();
          hostname = "horizon-testnet.stellar.org";
          current_mode.value = "Stellar TestNet";
        }else {
          console.log("mode Live!!");  
          StellarSdk.Network.usePublicNetwork();
          hostname = "horizon-live.stellar.org";
          current_mode.value = "Stellar Live!!";
        }     
        server = new StellarSdk.Server({     
          hostname: hostname,
          port: 443,
          secure: true
        })
        //update_key();
        update_balances();          
      });
      
      save.addEventListener("click", function(event) {         
        if (typeof(Storage) !== "undefined") {
          var encrypted = CryptoJS.AES.encrypt(seed.value, pass_phrase.value);       
          // Store
          localStorage.setItem(seed_nick.value, encrypted);
          seed.value = "seed saved to local storage"        
        }else {
          seed.value = "Sorry, your browser does not support Web Storage...";
        }
      });

      restore.addEventListener("click", function(event) {         
        if (typeof(Storage) !== "undefined") {
          // Retrieve
          var encrypted = localStorage.getItem(seed_nick.value);
          seed.value = CryptoJS.AES.decrypt(encrypted, pass_phrase.value).toString(CryptoJS.enc.Utf8);
          update_key();
          update_balances();
          tissuer.value = 'GAMB56CPYXJZUM2QSWXTUFSFIWMNHB6GZBUFJ2YJQJRGW6WH223NRLND'
          tasset.value = 'CHP'
        }else {
          seed.value = "Sorry, your browser does not support Web Storage...";
        }        
      });

      list_seed_keys.addEventListener("click", function(event) {
        var result = "";
        for ( var i = 0, len = localStorage.length; i < len; ++i ) {
          //console.log(  localStorage.key( i ) );
          result = result + localStorage.key( i ) + ", ";
        }
        message.textContent = result;
      });

      gen_random_dest.addEventListener("click", function(event) {
        console.log("gen_random");         
        var new_keypair = StellarSdk.Keypair.random();
        destination.value = new_keypair.address();
        dest_seed.value = new_keypair.seed();
        update_balances();
        amount.value = 20.1;
        issuer.value = "";
        asset.value = "native";
      });
            
      send_payment.addEventListener("click", function(event) {                 
        sendPaymentTransaction();       
      });

      add_trustline.addEventListener("click", function(event) { 
        asset_type.value = tasset.value;         
        var operation = addTrustlineOperation(tasset.value, tissuer.value);
        createTransaction(key,operation);
      });


  });

