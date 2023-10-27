#!/usr/bin/env ruby

require 'json'
require 'rest-client'
require 'optparse'
require './crypto_helper'
require './worker'

if $PROGRAM_NAME == __FILE__
  usage = 'usage: ./election_commission_worker.rb -o OBSERVER_ADDRESS -p PUBLIC_VOTERS_KEYS_PATH -h ELIGIBLE_VOTERS_HASH_PATH -e ELECTION_PUBLIC_KEY_PATH\n
  Example: ./election_commission_worker.rb -o http://localhost:7075 -p "data/public_keys.json" -h "data/public_keys_hash.json" -e "data/election_public.pem"'

  options = {}
  OptionParser.new do |opt|
    opt.on('-o', '--observer OBSERVER_ADDRESS') { |o| options[:observer] = o }
    opt.on('-p', '--public_voter_keys PUBLIC_VOTERS_KEYS_PATH') { |o| options[:public_voter_keys] = o }
    opt.on('-h', '--public_voter_keys_hash PUBLIC_VOTERS_KEYS_HASH') { |o| options[:public_voter_keys_hash] = o }
    opt.on('-e', '--election_public_key ELECTION_PUBLIC_KEY_PATH') { |o| options[:election_public_key] = o }
  end.parse!

  abort(usage) unless options[:observer]
  abort(usage) unless options[:public_voter_keys]
  abort(usage) unless options[:public_voter_keys_hash]
  abort(usage) unless options[:election_public_key]

  eligible_voters = JSON.parse(File.read(options[:public_voter_keys]))
  eligible_voters_hash = File.read(options[:public_voter_keys_hash])
  election_public_key = CryptoHelper.rsa_key(options[:election_public_key])

  worker = Worker.new(options[:observer], eligible_voters, eligible_voters_hash, election_public_key)

  # Verification of votors list
  voters_list_success_flag = worker.verifyVotersList()

  # Verification of the blockchain
  blockchain_success_flag = worker.verifyBlockchain()

  puts "Voters list failed verification" unless voters_list_success_flag == true
  puts "Blockchain failed verification" unless blockchain_success_flag == true
  
end
