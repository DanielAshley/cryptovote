#!/usr/bin/env ruby

require 'rest-client'
require 'json'
require 'optparse'
require './validator'

class Counter
  attr_reader :chain, :election_private_key, :validator

  def initialize(chain, election_private_key_path)
    @chain = chain
    @election_private_key = CryptoHelper.rsa_key(election_private_key_path)
    @validator = Validator.new(chain)
  end

  def election_results
    'This is not a valid chain' unless validator.valid_chain?
    count_votes
  end

  private

  def count_votes
    results = Hash.new(0)
    current_index = 1

    while current_index < chain.length
      block = chain[current_index]

      vote_ciphertext = block['transaction']['vote']
      vote_plaintext = CryptoHelper.rsa_private_decrypt(vote_ciphertext, election_private_key)
      ring_sig = CryptoHelper.ringsig_from(block['transaction']['ring_signature'])

      if validator.valid_vote?(vote_plaintext, ring_sig.key_image)
        candidate = vote_plaintext.split('|')[1]
        results[candidate] += 1
      end

      current_index += 1
    end
    results
  end

end

if $PROGRAM_NAME == __FILE__
  usage = 'usage: ./counter.rb -c CHAIN_URL -p ELECTION_PRIVATE_KEY_PATH'

  options = {}
  OptionParser.new do |opt|
    opt.on('-c', '--chain CHAIN_URL') { |o| options[:chain_url] = o }
    opt.on('-p', '--election_private_key_path ELECTION_PRIVATE_KEY_PATH') { |o| options[:election_private_key_path] = o }
  end.parse!

  abort(usage) unless options[:chain_url]

  chain = JSON.parse(RestClient.get(options[:chain_url]))['chain']

  counter = Counter.new(chain, options[:election_private_key_path])
  start = Time.now
  
  # The Election Tally
  final_election_results = counter.election_results
  puts final_election_results

  # Determine the winner
  winner = final_election_results.max_by{ |k,v| v }[0]
  winner_total = final_election_results[winner]

  puts "#{winner} wins with #{winner_total} votes."

  finish = Time.now
  puts "Counted in #{finish-start} seconds"
end
