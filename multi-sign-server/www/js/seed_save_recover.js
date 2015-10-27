"use strict";
   
    // Initialize everything when the window finishes loading
    window.addEventListener("load", function(event) {
     
      var save = document.getElementById("save");
      var restore = document.getElementById("restore");
      var pass_phrase = document.getElementById("pass_phrase");
      var seed = document.getElementById("seed"); 
      var encrypted;  
        
      save.addEventListener("click", function(event) {         
        if (typeof(Storage) !== "undefined") {
          var encrypted = CryptoJS.AES.encrypt(seed.value, pass_phrase.value);       
          // Store
          localStorage.setItem("seed", encrypted);
          seed.value = "seed saved to local storage"        
        } else {
          document.getElementById("seed").value = "Sorry, your browser does not support Web Storage...";
        }

      });

      restore.addEventListener("click", function(event) {         
        if (typeof(Storage) !== "undefined") {
          // Retrieve
          var encrypted = localStorage.getItem("seed");
          seed.value = CryptoJS.AES.decrypt(encrypted, pass_phrase.value).toString(CryptoJS.enc.Utf8);
        } else {
          document.getElementById("seed").innerHTML = "Sorry, your browser does not support Web Storage...";
        }

      });

    });
