#!/usr/bin/env ruby

# Testing
require './counter.rb'

if __FILE__ == $0

  usage = 'usage: RING_MEMBERS=10 OBSERBER_ADDRESS=http://localhost:4567 ./election_perftest.rb -v NUMBER_OF_VOTERS'

  options = {}
  OptionParser.new do |opt|
    opt.on('-o', '--observers NUMBER_OF_OBSERVERS') { |o| options[:observers] = o }
  end.parse!

  abort(usage) unless options[:observers]
  
  

  # TODO

  
end
