#!/usr/bin/env ruby

require './blockchain'


describe Blockchain do 
    context "When testing the Blockchain class" do 

      it "should instantiate to an instance of the Blockchain object" do 
         # Instantiate the Blockchain
         blockchain = Blockchain.new
         expect(blockchain).to be_an_instance_of(Blockchain)
      end

      it "should instantiate to an instance of the Blockchain object and contain a genisis node" do 
         # Instantiate the Blockchain
         blockchain = Blockchain.new

         puts blockchain.chain[0]

         expect(blockchain.chain.length).to eq 1
         expect(blockchain.chain[0][:index]).to eq 1
         expect(blockchain.chain[0][:transaction].length).to eq 0
         expect(blockchain.chain[0][:previous_hash]).to eq 1
      end
       
    end
 end
