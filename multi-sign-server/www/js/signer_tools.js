"use strict";
   
    // Initialize everything when the window finishes loading
    window.addEventListener("load", function(event) {
     
      var network_testnet = document.getElementById("network_testnet");
      var message = document.getElementById("message");
      var account = document.getElementById("account");
      
      var seed = document.getElementById("seed");          
      var balance = document.getElementById("balance");
      var thresh_set = document.getElementById("thresh_set"); 
      var master_weight = document.getElementById("master_weight");      
      var url = document.getElementById("url");
      var open = document.getElementById("open");
      var close = document.getElementById("close");
      var merge_accounts = document.getElementById("merge_accounts");
      var status = document.getElementById("status");
      var network = document.getElementById("network");
 
      var socket;
      var socket_open_flag = false;
      var operation_globle;
      var paymentsEventSource;
      var server;

      //merge_accounts.disabled = true;
      network.value ="testnet";
      console.log("just after var");
      status.textContent = "Not Connected";
      url.value = "ws://zipperhead.ddns.net:9494";
      //create_socket();
      close.disabled = true;
      open.disabled = true;
           
      seed.value = 'SA3CKS64WFRWU7FX2AV6J6TR4D7IRWT7BLADYFWOSJGQ4E5NX7RLDAEQ'; 
        
      StellarSdk.Network.useTestNet();
      //StellarSdk.Memo.text("sacarlson");
      var hostname = "horizon-testnet.stellar.org";
            
      reset_horizon_server();

      current_mode.value = "Stellar TestNet";

      var key = StellarSdk.Keypair.fromSeed(seed.value);
      update_key();
    
      update_balances();
      //start_effects_stream();

          function attachToPaymentsStream(opt_startFrom) {
            console.log("start attacheToPaymentsStream");
            var futurePayments = server.effects().forAccount(account.value);
            if (opt_startFrom) {
                console.log("opt_startFrom detected");
                futurePayments = futurePayments.cursor(opt_startFrom);
            }
            if (paymentsEventSource) {
                console.log('close open effects stream');
                paymentsEventSource.close();
            }
            console.log('open effects stream with cursor: ' + opt_startFrom);
            paymentsEventSource = futurePayments.stream({
                onmessage: function (effect) { effectHandler(effect, true); }
            });
          };

          function start_effects_stream() {
	    server.effects()
            .forAccount(account.value)
            .limit(30)
            .order('desc')
            .call()
            .then(function (effectResults) {
                console.log("then effectResults");
                var length = effectResults.records ? effectResults.records.length : 0;
                for (index = length-1; index >= 0; index--) {
                    console.log("index" + index);
                    var currentEffect = effectResults.records[index];
                    effectHandler(currentEffect, false);
                }
                var startListeningFrom;
                if (length > 0) {
                    latestPayment = effectResults.records[0];
                    startListeningFrom = latestPayment.paging_token;
                }
                attachToPaymentsStream(startListeningFrom);
            })
            .catch(function (err) {
                console.log("error detected in attachToPaymentsStream");
                attachToPaymentsStream('now');
                console.log(err)
            });
          }

          function effectHandler(effect,tf) {
            console.log("got effectHandler event");
            console.log(tf);
            console.log(effect);
            if (effect.type === 'account_debited') {
               if (effect.asset_type === "native") {
                  balance.value = balance.value - effect.amount;
               }else {
                  CHP_balance.value = CHP_balance.value - effect.amount;
               }
            }
            if (effect.type === 'account_credited') {
               if (effect.asset_type === "native") {
                  balance.value = balance.value + effect.amount;
               }else {
                  CHP_balance.value = CHP_balance.value + effect.amount;
               }
            }
            if (effect.type === 'account_created') {
               balance.value = effect.starting_balance;
            }
          };

      function reset_horizon_server() {
        console.log("reset_horizon_server");        
        server = new StellarSdk.Server({     
          hostname: hostname,
          port: 443,
          secure: true
        });
      }
       
      function get_account_info(account,params,callback) {
        if (network.value === "mss_server") {
          socket_open_flag = true;
        }else {
          console.log("get_account_info horizon mode");
          server.accounts()
          .address(account)
          .call()
          .then(function (accountResult) {
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
          console.log("display_balance account_obj");
          console.log(account_obj);
          console.log(account_obj.name);          
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
          console.log("update_balances mss mode");
          get_balance_updates_mss();
          return
        }
        // disable horizon balance here to try streaming instead
        get_account_info(account.value,{
          to_id1:"balance",
          asset_code1:null,
          detail:true},update_balances_set);
      
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

     function accountMergeTransaction() {
          // this will send all native of key from seed.value account to destination.value account
          console.log("accountMerge");        
          key = StellarSdk.Keypair.fromSeed(seed.value);
          console.log(key.address());
          var operation = accountMergeOperation();
          console.log("operation created ok");
          createTransaction(key,operation);
        }

     function addSignerTransaction() {
          console.log("addSignerTransaction");        
          key = StellarSdk.Keypair.fromSeed(seed.value);
          console.log(key.address());
          var operation = addSignerOperation();
          console.log("operation created ok");
          createTransaction(key,operation);
        }

     function setOptionsTransaction() {
          console.log("addSignerTransaction");        
          key = StellarSdk.Keypair.fromSeed(seed.value);
          console.log(key.address());
          var operation = setOptionsOperation();
          console.log("operation created ok");
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
       var transaction = new StellarSdk.TransactionBuilder(account,{fee:100})            
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
        var action = '{"action":"get_thresholds_info","account":"';
        var tail = '"}';
        socket.send(action + account.value + tail);
        var action = '{"action":"get_signer_info","account":"';
        var tail = '"}';
        socket.send(action + account.value + tail);

      }
    }
     

      function createTransaction_horizon(key,operation) {
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

      function accountMergeOperation() {
                 console.log(destination.value);
                 return StellarSdk.Operation.accountMerge({
                   destination: destination.value
                 });                                     
               }

      function addSignerOperation() {
                 console.log(signer.value);
                 console.log(Number(weight.value));
                 return StellarSdk.Operation.setOptions({
                   signer: {
                     address: signer.value,
                     weight: Number(weight.value)
                   }
                 });
               }

      function addTrustlineOperation(asset_type, address) {
                 //asset_type examples "USD", "CHP"
                 asset = new StellarSdk.Asset(asset_type, address);
                 return StellarSdk.Operation.changeTrust({asset: asset}); 
               }

      function setOptionsOperation() {
                 console.log(Number(master_weight.value));
                 console.log(Number(threshold.value));
                 var opts = {};
                 //opts.inflationDest = "GDGU5OAPHNPU5UCLE5RDJHG7PXZFQYWKCFOEXSXNMR6KRQRI5T6XXCD7";
                 //opts.clearFlags = 1;
                 //opts.setFlags = 1;
                 opts.masterWeight = Number(master_weight.value);
                 opts.lowThreshold = Number(threshold.value);
                 opts.medThreshold = Number(threshold.value);
                 opts.highThreshold = Number(threshold.value);

                 //opts.signer = {
                 // address: signer.value,
                 // weight: weight.value
                // };
                 //opts.homeDomain = "www.example.com";
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
          console.log(event.data);
          console.log("event_obj.action");
          console.log(event_obj.action);
          if (event_obj.action == "get_account_info") {          
              balance.value = event_obj.balance;                       
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
          if (event_obj.action == "get_thresholds_info") {
            thresh_set.value = event.data;
          }
          if (event_obj.action == "get_signer_info") {

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
          console.log(socket);
          if (typeof(socket) !== "undefined") {
            socket.close();
          }
          reset_horizon_server();
          //update_balances();
         // start_effects_stream();
        }else if (network.value === "live" ){
          console.log("mode Live!!");  
          close.disabled = true;
          open.disabled = true;
          StellarSdk.Network.usePublicNetwork();
          hostname = "horizon-live.stellar.org";
          current_mode.value = "Stellar Live!!";
          console.log(socket);
          if (typeof(socket) !== "undefined") {
            socket.close();
          }
          reset_horizon_server();
          //update_balances();
          //start_effects_stream();
        }else {
          //mss-server mode
          console.log("start mss-server mode");
          //paymentsEventSource.close();
          server = false;
          close.disabled = false;
          StellarSdk.Network.useTestNet();
          create_socket();
          current_mode.value = "TestNet MSS-server";
        }     
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

      add_signer.addEventListener("click", function(event) {
        console.log("click add_signer");
        addSignerTransaction();
        update_balances();
      });

      change_threshold.addEventListener("click", function(event) {
        console.log("click change_threshold");
        setOptionsTransaction();
        update_balances();
      });

setOptionsTransaction()
    
  });

