"use strict";
   
    // Initialize everything when the window finishes loading
    window.addEventListener("load", function(event) {
     
      var network_testnet = document.getElementById("network_testnet");
      var message = document.getElementById("message");
      var account = document.getElementById("account");
      var destination = document.getElementById("destination");
      var dest_seed = document.getElementById("dest_seed");
      var issuer = document.getElementById("issuer");
      var seed = document.getElementById("seed");
      var tissuer = document.getElementById("tissuer");
      var tasset = document.getElementById("tasset");
      var amount = document.getElementById("amount");
      var balance = document.getElementById("balance");
      var CHP_balance = document.getElementById("CHP_balance");
      var asset_type = document.getElementById("asset_type");
      var memo = document.getElementById("memo");
      var dest_balance = document.getElementById("dest_balance");
      var dest_CHP_balance = document.getElementById("dest_CHP_balance");
      var asset_obj = new StellarSdk.Asset.native();
      var url = document.getElementById("url");
      var open = document.getElementById("open");
      var close = document.getElementById("close");
      var status = document.getElementById("status");
      var socket;
      var socket_open_flag = false;
      var operation_globle;

      status.textContent = "Not Connected";
      url.value = "ws://zipperhead.ddns.net:9494";
      create_socket();
      close.disabled = false;
      open.disabled = true;
      memo.value = "scotty_is_cool"
      amount.value = "1";      
      asset_type.value = "AAA";
      seed.value = 'SA3CKS64WFRWU7FX2AV6J6TR4D7IRWT7BLADYFWOSJGQ4E5NX7RLDAEQ'; 
      tissuer.value = 'GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF'
      issuer.value = tissuer.value
      tasset.value = 'AAA'
      destination.value = 'GDVYGXTUJUNVSJGNEX75KUDTANHW35VQZEZDDIFTIQT6DNPHSX3I56RY';
      dest_seed.value = "SBV5OHE3LGOHC6CBRMSV3ZQNTT4CM7I7L37KAAU357YDDPER2GNP2WWL";      

      StellarSdk.Network.useTestNet();
      //StellarSdk.Memo.text("sacarlson");
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
        if (network.value === "mss_server") {
          socket_open_flag = true;
        }else {
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
        if (network.value === "mss_server"){
          get_balance_updates_mss();
          return
        }
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
          console.log("start createAccount");
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
          message.textContent = "started payment: ";
          createPaymentTransaction(key,asset_obj);
        }        
      }    
  

      function createPaymentTransaction(key,asset_obj) {
          var operation = createPaymentOperation(asset_obj);
          createTransaction(key,operation);
        }

     function submitTransaction_mss(transaction) {
       console.log("start submitTransaction_mss");
       var b64 = transaction.toEnvelope().toXDR().toString("base64");
       var action = '{"action":"send_b64", "envelope_b64":"' + b64 + '"}';
       socket.send(action);
     }

     function get_seq(address) {
       var action = '{"action":"get_sequence", "account":"' + address + '"}'
       socket.send(action);
     }

     function createTransaction_mss_submit(key,operation,seq_num) {
       var account = new StellarSdk.Account(key.address(), seq_num);
       var transaction = new StellarSdk.TransactionBuilder(account,{fee:100, memo: StellarSdk.Memo.text(memo.value)})            
           .addOperation(operation)          
           .addSigner(key)
           .build();
       submitTransaction_mss(transaction); 
     }

     function createTransaction_mss(key,operation) {
       operation_globle = operation;
       get_seq(key.address());
     }

    function get_balance_updates_mss() {
      // this querys balance updates from the mss-server
      // see socket.addEventListener to see how the responces from this are feed 
      // to browser display boxes
      console.log("start get_balance_updates_mss");
      if (socket.readyState === 1) {
        var action = '{"action":"get_account_info","account":"';
        var tail = '"}';
        socket.send(action + account.value + tail);
        socket.send(action + destination.value + tail);
        var action = '{"action":"get_lines_balance","account":"';
        var tail = '"}';
        socket.send(action + account.value + '", "issuer":"' + tissuer.value + '", "asset":"' + asset_type.value + tail);
        socket.send(action + destination.value + '", "issuer":"' + tissuer.value + '", "asset":"' +tasset.value + tail);
      }
    }
     

      function createTransaction_horizon(key,operation) {
        server.loadAccount(key.address())
          .then(function (account) {
            var transaction = new StellarSdk.TransactionBuilder(account,{fee:100, memo: StellarSdk.Memo.text(memo.value)})            
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
     
      function createTransaction(key,operation) {
        if (network.value === "mss_server") {
          console.log("start mss trans");
          createTransaction_mss(key,operation);
        } else {
          createTransaction_horizon(key,operation);
        }
       
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

    
      function create_socket() {
        console.log("started create_socket");
        open.disabled = true;
        close.disabled = false;
        socket = new WebSocket(url.value, "echo-protocol");

        socket.addEventListener("open", function(event) {         
          open.disabled = true;
          close.disabled = false;
          status.textContent = "Connected";
        });

        // Display messages received from the mss-server
        // and feed desired responce to browser input boxes
        socket.addEventListener("message", function(event) {
          message.textContent = "Server Says: " + event.data;
          var event_obj = JSON.parse(event.data);
          console.log("event_obj.action");
          console.log(event_obj.action);
          if (event_obj.accountid == account.value) {
            balance.value = event_obj.balance;
          }
          if (event_obj.accountid == destination.value) {
            dest_balance.value = event_obj.balance;
          }
          if (event_obj.account == destination.value) {
            dest_CHP_balance.value = event_obj.balance;
          }
          if (event_obj.account == account.value) {
            CHP_balance.value = event_obj.balance;
          }
          if (event_obj.action == "get_sequence") {
            var seq_num = (event_obj.sequence).toString();
            console.log("got sequence");
            console.log(seq_num);
            createTransaction_mss_submit(key, operation_globle, seq_num)
          }
          if (event_obj.action == "send_b64") {
            get_balance_updates_mss();
          }
        });

        // Display any errors that occur
        socket.addEventListener("error", function(event) {
          message.textContent = "Error: " + event;
        });

        socket.addEventListener("close", function(event) {
          open.disabled = false;
          close.disabled = true;
          status.textContent = "Not Connected";
        });

        socket.onopen = function (event) {
          console.log("got onopen event");
          get_balance_updates_mss();
        };

      }

      // Create a new connection when the Connect button is clicked
      open.addEventListener("click", function(event) {
        create_socket();
      });

      // Close the connection when the Disconnect button is clicked
      close.addEventListener("click", function(event) {
        console.log("closed socket");
        close.disabled = true;
        open.disabled = false;
        message.textContent = "";
        socket.close();
      });
     
      change_network.addEventListener("click", function(event) { 
        console.log("mode: " + network.value);        
        if(network.value === "testnet" ) {
          close.disabled = true;
          open.disabled = true;
          StellarSdk.Network.useTestNet();
          hostname = "horizon-testnet.stellar.org";
          current_mode.value = "Stellar TestNet";
        }else if (network.value === "live" ){
          console.log("mode Live!!");  
          close.disabled = true;
          open.disabled = true;
          StellarSdk.Network.usePublicNetwork();
          hostname = "horizon-live.stellar.org";
          current_mode.value = "Stellar Live!!";
        }else {
          //mss-server mode
          close.disabled = false;
          StellarSdk.Network.useTestNet();
          hostname = "horizon-testnet.stellar.org";
          create_socket();
          current_mode.value = "TestNet MSS-server";
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

