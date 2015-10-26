 "use strict";
    // Initialize everything when the window finishes loading
    window.addEventListener("load", function(event) {
      var status = document.getElementById("status");
      var url = document.getElementById("url");
      var open = document.getElementById("open");
      var close = document.getElementById("close");
      var send = document.getElementById("send");
      var get = document.getElementById("get");
      var text = document.getElementById("text");
      var json = document.getElementById("json");
      var send_json = document.getElementById("send_json");
      var message = document.getElementById("message");
      var socket;
      var message_obj;

      var server = new StellarSdk.Server({     
        hostname: 'horizon-testnet.stellar.org',
        port: 443,
        secure: true
      });

      StellarSdk.Network.useTestNet();

      status.textContent = "Not Connected";
      url.value = "ws://zipperhead.ddns.net:9494";
      close.disabled = true;
      send.disabled = true;
      submit_tx.disabled = true;
      get_status_tx.disabled = true;
      search_signable_tx.disabled = true;
      sign_tx.disabled = true;
      //make_witness_unlock.disabled = true;
      send_json.disabled = true;

      // Create a new connection when the Connect button is clicked
      open.addEventListener("click", function(event) {
        open.disabled = true;
        socket = new WebSocket(url.value, "echo-protocol");

        socket.addEventListener("open", function(event) {
          close.disabled = false;
          send.disabled = false;
          send_json.disabled = false;
          submit_tx.disabled = false;
          get_status_tx.disabled = false;
          search_signable_tx.disabled = false;
          sign_tx.disabled = false;
          //make_witness_unlock.disabled = false;
          status.textContent = "Connected";
        });

        // Display messages received from the server
        socket.addEventListener("message", function(event) {
          message.textContent = "Server Says: " + event.data;
          var message_obj = JSON.parse(event.data);
          //message.textContext = message_obj.status;
          tx_code.value = message_obj.signables[0].tx_code
          b64_s.value = message_obj.signables[0].tx_envelope_b64
          sign_tx_title.value = message_obj.signables[0].tx_title
          master_address.value = message_obj.signables[0].master_address
          sign_address.value = message_obj.address
          //b64_s.value = new Transaction.constructor(message_obj.signables[0].tx_envelope_b64).addSigner(Keypair.fromSeed())
          console.log ( 'tx_code ' + message_obj.signables[0].tx_code );
          console.log ( 'tx_envelope_b64 ' + message_obj.signables[0].tx_envelope_b64 );
        });

        // Display any errors that occur
        socket.addEventListener("error", function(event) {
          message.textContent = "Error: " + event;
        });

        socket.addEventListener("close", function(event) {
          open.disabled = false;
          status.textContent = "Not Connected";
        });
      });

      // Close the connection when the Disconnect button is clicked
      close.addEventListener("click", function(event) {
        close.disabled = true;
        send.disabled = true;
        message.textContent = "";
        socket.close();
      });

      // Send text to the server when the Send button is clicked
      send.addEventListener("click", function(event) {
        socket.send(text.value);
        text.value = "";
      });

       // Send json box to the server when the Send button is clicked
      send_json.addEventListener("click", function(event) {
        socket.send(json.value);
        text.value = "";
      });
      

     //#hash = {"action"=>"submit_tx", "tx_title"=>"test tx", "tx_envelope_b64"=>"AAAA..."}
     submit_tx.addEventListener("click", function(event) {
        var action = '{"action":"submit_tx","tx_title":"';
        var tail = '"}';
        socket.send(action + tx_title.value + '","tx_envelope_b64":"' + b64.value + tail);
        tx_title.value = "enter tx title here";
      });

     get_status_tx.addEventListener("click", function(event) {
        var action = '{"action":"status_tx","tx_code":"';
        var tail = '"}';
        socket.send(action + txid.value + tail);
        txid.value = "enter txid here";
      });

     search_signable_tx.addEventListener("click", function(event) {
        var action = '{"action":"search_signable_tx","account":"';
        var tail = '"}';
        socket.send(action + address.value + tail);
        address.value = "enter stellar account here";
      });

     sign_tx.addEventListener("click", function(event) {
        var action = '{"action":"sign_tx","tx_envelope_b64":"';
        var tail = '"}';
        var key = StellarSdk.Keypair.fromSeed(sign_seed.value);
        sign_address.value =  key.address();
        var transaction = new StellarSdk.Transaction(b64_s.value);
        transaction.sign(key);
        var b64 = transaction.toEnvelope().toXDR().toString("base64");
        console.log ( 'b64_after: ' + b64 );       
        socket.send(action + b64 + '","tx_code":"' + tx_code.value + tail);        
      });

    });
