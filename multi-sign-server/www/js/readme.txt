some of files here are imported from third party sites.
These should be replaced with the later versions available at these point:

http://crypto-js.googlecode.com/svn/tags/3.1.2/build/rollups/aes.js

https://github.com/stellar/bower-js-stellar-sdk v0.2.12 commit 8063a215e1b30a0a437cd516af33bc2541ff4d81
this version now installed is V.0.2.12  commit 8063a215e1b30a0a437cd516af33bc2541ff4d81
md5sum 
6da1c71fd185ac94631cc0c99009b1b5  stellar-sdk.min.js
993357d0cf332aa6d13b8a9c60531fc9  stellar-sdk.js 
this version of sdk has a bug were amount is 10X if you have 8 dec places in ammount
example 1.12345678 = 11.23456.  we added fix7dec to prevent this from hapening in this version of mini client that uses it
now upgraded to v 0.2.21 commit 2165be724949e5fa09b4407ca45f4646632cca09
md5sum
cc0b157ae686c0540c6d8482172e098d  stellar-sdk.min.js
687ab3c785e04822e879e54416e388d4  stellar-sdk.js

The other *.js files here are mostly just examples of using these libs.
