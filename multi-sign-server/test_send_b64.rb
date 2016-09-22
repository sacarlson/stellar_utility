#!/usr/bin/ruby
require '../lib/stellar_utility/stellar_utility.rb'

#Utils = Stellar_utility::Utils.new("horizon")
Utils = Stellar_utility::Utils.new("./test.cfg")
puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"


b64="AAAAANnoheGY8bwTfUfWundrfxGT689BSdQV6JmER2Q395BcAAAACgABh04AAAADAAAAAAAAAAAAAAABAAAAAAAAAAUAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAACHRlc3Q1NjkyAAAAAAAAAAAAAAABN/eQXAAAAEBaa64v1Pvh3g0eM1w5g9tlli/O6J0T4FPu9ifle3xGDyOLvGo7W2bpZ+uS9q31se2UMbd5gr0HFPivvuZyanYL"

result = Utils.send_tx(b64)
puts "result send_tx #{result}"
