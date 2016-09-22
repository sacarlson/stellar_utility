# This is the development of function to total debt assets of each issuer
require '../lib/stellar_utility/stellar_utility.rb'

#Utils = Stellar_utility::Utils.new("horizon")
Utils = Stellar_utility::Utils.new()
puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"
puts ""

#planed input {"action":"total_issuer_debts", "issuer": GXTYDH..." , "offset":10}
# function input {"issuer":"GXSTT...", "asset":"USD", "offset":0}
#output: {"debits":[{"issuer":"GXTY...","asset":"USD", "debit":10000},{"asset":"YEN", "debit":200}]}
#or output {"GXTY...":{"USD":100},"GXTY...":{"YEN":200}}

#issuer["GXTY..."]["USD"] = total + value




params = {}
params["offset"] = 0
params["issuer"] = 'GAMB56CPYXJZUM2QSWXTUFSFIWMNHB6GZBUFJ2YJQJRGW6WH223NRLND'
result = Utils.issuer_debt_total(params)
puts "result: #{result}"


