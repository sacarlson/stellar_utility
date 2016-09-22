for these errors:

./send_native.rb
/usr/lib/ruby/1.9.1/rubygems/custom_require.rb:36:in `require': cannot load such file -- stellar-base (LoadError)
	from /usr/lib/ruby/1.9.1/rubygems/custom_require.rb:36:in `require'
	from /mnt/new1tera/github/stellar/stellar_utility/lib/stellar_utility/stellar_utility.rb:12:in `<top (required)>'
	from /usr/lib/ruby/1.9.1/rubygems/custom_require.rb:36:in `require'
	from /usr/lib/ruby/1.9.1/rubygems/custom_require.rb:36:in `require'
	from ./send_native.rb:6:in `<main>'


you will need to setup rbenv and bundle install or at least just bundle install

sacarlson@b ~/github/stellar/stellar_utility $ rbenv local 2.2.3
sacarlson@b ~/github/stellar/stellar_utility $ rbenv versions
  system
  1.9.3-p484
  2.1.2
  2.1.4
  2.2.0
  2.2.1
* 2.2.3 (set by /home/sacarlson/github/stellar/stellar_utility/.ruby-version)
sacarlson@b ~/github/stellar/stellar_utility $ bundle install
Resolving dependencies...
Using rake 10.4.2
Using i18n 0.7.0
...

if the above fails to fix this problem then it may involves config coruption normally caused when you have changed ruby versions in rbenv
  or you started from an older version of ruby than what the programer of this package last used when he released his work

or you may see something like:
 sacarlson@b ~/github/stellar/stellar_utility/multi-sign-server $ bundle exec multi-sign-server.rb
bundler: command not found: multi-sign-server.rb
Install missing gem executables with `bundle install`
 with bungle install also failing to fix it

or:
sacarlson@b ~/github/stellar/stellar_utility/multi-sign-server $ bundle exec multi-sign-server.rb
bundler: command not found: multi-sign-server.rb
Install missing gem executables with `bundle install`
sacarlson@b ~/github/stellar/stellar_utility/multi-sign-server $ bundle exec ./multi-sign-server.rb
./multi-sign-server.rb: 1: ./multi-sign-server.rb: require: not found
./multi-sign-server.rb: 2: ./multi-sign-server.rb: require: not found
./multi-sign-server.rb: 3: ./multi-sign-server.rb: require: not found
./multi-sign-server.rb: 7: ./multi-sign-server.rb: require: not found
./multi-sign-server.rb: 9: ./multi-sign-server.rb: Syntax error: word unexpected (expecting ")")


then try this (bellow) that will basicly reload and recompile all the dependancies for this package

bundle install --path vendor/cache
#?bundle --path=vendor/bundle

also when we start changing rbenv versions we sometimes need to delete Gemfile.lock and again bundle install to upgrade to what works in new ruby version
but I think the above command already takes care of that, but if all else fails try it.



example to run example app:

bundler exec ruby ./send_native.rb


 bundler exec ruby ./send_native.rb
auto network mode active
url_stellar_core:  http://localhost:8080
error in core status
e: Connection refused - connect(2) for "localhost" port 8080
e.class: Errno::ECONNREFUSED
e.to_s: Connection refused - connect(2) for "localhost" port 8080
/mnt/new1tera/github/stellar/stellar_utility/lib/stellar_utility/stellar_utility.rb:943:in `get_set_stellar_core_network': undefined method `[]' for nil:NilClass (NoMethodError)
	from /mnt/new1tera/github/stellar/stellar_utility/lib/stellar_utility/stellar_utility.rb:33:in `initialize'
	from ./send_native.rb:8:in `new'
	from ./send_native.rb:8:in `<main>'


this error indicates you have no stellar core running.  you can change mode to horizon with no steller core or run a core as an option

Utils = Stellar_utility::Utils.new("horizon")
