require "spec_helper"

describe Stellar_utility::Utils do
  subject{ Stellar_utility::Utils.new }
  let(:hash32){ "YT736HYGE3" }
  let(:string){ "GS4NHAGUQG" }  
  let(:master){Stellar::KeyPair.master}
  let(:to_pair){Stellar::KeyPair.from_seed("SAHH463NC3LFNJQEECD5FDPDRL72LCKZP6DWQANWZFYR3GTM2KOVUMOL")}
  let(:issuer_pair){Stellar::KeyPair.from_seed("SBZ2UODRGMRVRQ52F3U3VDFI5W4IVBXTTZPQIYUQ3K7PWVWFGHIYWHEE")}
  let(:from_pair){Stellar::KeyPair.from_seed("SBZ2UODRGMRVRQ52F3U3VDFI5W4IVBXTTZPQIYUQ3K7PWVWFGHIYWHEE")}

  it "hash32 encoding short 10 leter base32 SHA256" do
    expect(subject.hash32(string)).to eq(hash32)
  end

  let(:mode){"horizon"}
  it "default configs mode horizon" do
    expect(subject.configs["mode"]).to eq("horizon")
  end

  it "get native balance" do
    expect(subject.get_native_balance(master).to_f > 1000).to eq(TRUE)
  end
      
  it "get non native balance" do
    expect(subject.get_lines_balance(to_pair ,issuer_pair ,"USD")).to eq(0)
  end

  it "to_pair account is correct length" do
    expect(to_pair.address.length).to eq(56)
  end

  it "master account address should be" do
    expect(master.address).to eq("GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H")
  end
  
  it "to_pair account address should be" do
    expect(to_pair.address).to eq("GC27AGUSZAGSZMLBFGPHOOXVPQHLLYMN3SK3AUOF2M7KIVXKF75JYA6A")
  end

  it "master account address should be" do
    expect(from_pair.address).to eq("GD35ORY4BECTUOMT6Z2FRQMT2VUPKSB6AP7NWSGOOBJXWLZ4BNFTE54A")
  end
  
  it "create new account for to_pair" do
    expect(subject.create_account(to_pair, master, 102).class == String).to eq(TRUE)
  end 

  it "check new account start balance in to_pair" do
    expect(subject.get_native_balance(to_pair).to_i).to eq(102)
  end

  it "create new account for issuer_pair" do
    expect(subject.create_account(issuer_pair, master, 103).class == String).to eq(TRUE)
  end

  it "set trust on to_pair for issuer_pair" do
   expect(subject.add_trust(issuer_pair,to_pair,"CHP").class == String).to eq(TRUE)
  end

  it "send CHP assets to to_pair from issuer_pair" do
    expect(subject.send_currency(issuer_pair, to_pair, issuer_pair, "10.123", "CHP").class == String).to eq(TRUE)
  end

  it "get non native balance CHP in to_pair" do
    expect(subject.get_lines_balance(to_pair ,issuer_pair ,"CHP").to_f).to eq(10.123)
  end

end


