#!/usr/bin/env ruby

require './blockchain'


describe Blockchain do 
    context "When testing the Blockchain class" do 

       it "should instantiate to a non null value create a new Blockchain object" do 
          # Instantiate the Blockchain
          blockchain = Blockchain.new

          expect(blockchain).to be_an_instance_of(Blockchain)
       end
       
    end
 end
