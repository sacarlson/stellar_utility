"use strict";
   
    // Initialize everything when the window finishes loading
    window.addEventListener("load", function(event) {
     
      var save = document.getElementById("save");
      var restore = document.getElementById("restore");
      var pass_phrase = document.getElementById("pass_phrase");
      var seed = document.getElementById("seed"); 
      var key_id = document.getElementById("key_id");
      var message = document.getElementById("message"); 
      var encrypted;  
      key_id.value = "seed"

function display_localstorage_keylist() {
  var result = "";
  for ( var i = 0, len = localStorage.length; i < len; ++i ) {
     result = result + localStorage.key( i ) + ", ";
  }
  message.textContent = result;
}

function json_to_LocalStorage(jobj) {
  var key_list = "";
  for (var key in jobj){
    key_list = key_list + ", " + decodeURI(key) + " : " + decodeURI(jobj[key]);
    //console.log(decodeURI(key),decodeURI(jobj[key]));
    localStorage.setItem(decodeURI(key), decodeURI(jobj[key]));
  }
  return key_list;
}


function readSingleFile(e) {
  var file = e.target.files[0];
  if (!file) {
    return;
  }
  var reader = new FileReader();
  reader.onload = function(e) {
    var contents = e.target.result;
    //contents = '{"test" : "one", "test2" : "two"}'
    var json_obj = JSON.parse(contents);        
    displayContents(json_to_LocalStorage(json_obj));
  };
  reader.readAsText(file);
}

function displayContents(contents) {
  message.textContent = contents;
}

  //save string to file
  function download(strData, strFileName, strMimeType) {
    var D = document,
        A = arguments,
        a = D.createElement("a"),
        d = A[0],
        n = A[1],
        t = A[2] || "text/plain";

    //build download link:
    a.href = "data:" + strMimeType + "charset=utf-8," + escape(strData);


    if (window.MSBlobBuilder) { // IE10
        var bb = new MSBlobBuilder();
        bb.append(strData);
        return navigator.msSaveBlob(bb, strFileName);
    } /* end if(window.MSBlobBuilder) */



    if ('download' in a) { //FF20, CH19
        a.setAttribute("download", n);
        a.innerHTML = "downloading...";
        D.body.appendChild(a);
        setTimeout(function() {
            var e = D.createEvent("MouseEvents");
            e.initMouseEvent("click", true, false, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null);
            a.dispatchEvent(e);
            D.body.removeChild(a);
        }, 66);
        return true;
    }; /* end if('download' in a) */



    //do iframe dataURL download: (older W3)
    var f = D.createElement("iframe");
    D.body.appendChild(f);
    f.src = "data:" + (A[2] ? A[2] : "application/octet-stream") + (window.btoa ? ";base64" : "") + "," + (window.btoa ? window.btoa : escape)(strData);
    setTimeout(function() {
        D.body.removeChild(f);
    }, 333);
    return true;
}
      
 
      save.addEventListener("click", function(event) {
        // save an encrypted copy of seed value box to LocalStorage at key_id location         
        if (typeof(Storage) !== "undefined") {
          var encrypted = CryptoJS.AES.encrypt(seed.value, pass_phrase.value);       
          // Store
          localStorage.setItem(key_id.value, encrypted);
          message.textContent = "raw encryped data saved: " + encrypted;
          seed.value = "seed saved to local storage"        
        } else {
          seed.value = "Sorry, your browser does not support Web Storage...";
        }

      });

      save_raw.addEventListener("click", function(event) {
        //save an unencrypted copy of seed value box to LocalStorage at key_id location         
        if (typeof(Storage) !== "undefined") {        
          // Store
          localStorage.setItem(key_id.value, seed.value);
          message.textContent = "raw data saved: " + seed.value;
          seed.value = "raw data in seed saved to local storage"        
        } else {
          seed.value = "Sorry, your browser does not support Web Storage...";
        }

      });

      restore.addEventListener("click", function(event) {
        // restore the encryped contents of LocalStorage key_id to the seed value box
        message.textContent = "key ID value: " + key_id.value + " Not found in LocalStorage, check list_keys";      
        if (typeof(Storage) !== "undefined") {
          // Retrieve
          var encrypted = localStorage.getItem(key_id.value);
          seed.value = CryptoJS.AES.decrypt(encrypted, pass_phrase.value).toString(CryptoJS.enc.Utf8);
          message.textContent = "raw data before decryption: " + encrypted;
        } else {
          seed.value = "Sorry, your browser does not support Web Storage...";
        }

      });

      delete_key.addEventListener("click", function(event) {
        // delete key_id from LocalStorage 
        console.log("deleting key "+ key_id.value);
        seed.value = "seed key deleted from LocalStorage";         
        localStorage.removeItem(key_id.value);
        display_localstorage_keylist()        
      });

      list_keys.addEventListener("click", function(event) {
        //list all the keys presently seen in LocalStorage, these may be from other programs or websites that put them here.
        display_localstorage_keylist()
      });      

     save_to_file.addEventListener("click", function(event) {
       //save all the keys presently seen in LocalStorage on this browser to a local disk file on the system
       // this does not effect the encryption of the keys just moves the data to a file
       var result = "{";
       var first = true;
       for ( var i = 0, len = localStorage.length; i < len; ++i ) {
         if (first){
           first = false;
         }else {
           result = result + ", ";
         }
         //console.log(  localStorage.key( i ) );
         result = result + '"' + encodeURI(localStorage.key( i )) + '"' + " : " + '"' + encodeURI(localStorage.getItem(localStorage.key( i ))) +'"' ;
       }
       result = result + "}";
       message.textContent = result;
       download(result, 'backup_keys.txt', 'text/plain');
     });

     //triger the event of readSingleFile when file-input browse button is clicked and a file selected
     //this event reads the data from a local disk file and restores it's contents to the LocalStorage
     // the file selected is assumed to be in seed_save_recover backup format.
     document.getElementById('file-input').addEventListener('change', readSingleFile, false);
      

    });
