#!/usr/bin/env ruby

# Testing
require './voter.rb'

if __FILE__ == $0

  usage = 'usage: ./election_perftest.rb -v NUMBER_OF_VOTERS -o OBSERBER_ADDRESS'

  options = {}
  OptionParser.new do |opt|
    opt.on('-v', '--voters NUMBER_OF_VOTERS') { |o| options[:voters] = o }
    opt.on('-o', '--observer OBSERBER_ADDRESS') { |o| options[:observer] = o }
  end.parse!

  abort(usage) unless options[:voters]
  abort(usage) unless options[:observer]
  
  voter_keys = JSON.parse(File.read('data/private_keys.json')).sample(options[:voters].to_i)
  candidates = JSON.parse(File.read('data/candidates.json'))

  election_start = Time.now
  voter_keys.each do |voter_key|
    voter = Voter.new(voter_key)
    puts "#{voter_key} is voting"
    vote_start = Time.now 
    voter.vote(candidates.sample, options[:observer])
    vote_finish = Time.now
    puts "Vote took #{vote_finish-vote_start} seconds"
  end
  election_finish = Time.now
  puts "Election finished #{election_finish-election_start} seconds"

  
end
