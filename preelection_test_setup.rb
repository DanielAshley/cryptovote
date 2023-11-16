#!/usr/bin/env ruby

# Testing
require './counter.rb'

if __FILE__ == $0

  usage = 'usage: ./preelection_test_setup.rb -o OBSERVER_ADDRESS -n NUMBER_OF_OBSERVERS'

  options = {}
  OptionParser.new do |opt|
    opt.on('-n', '--num_observers NUMBER_OF_OBSERVERS') { |o| options[:num_observers] = o }
    opt.on('-o', '--observer OBSERVER_ADDRESS') { |o| options[:observer] = o }
  end.parse!

  abort(usage) unless options[:num_observers]
  abort(usage) unless options[:observer]
  
  # Create a list of observer addresses
  observer_list = []
  for a in 10001..10001+options[:num_observers].to_i do
    observer_list.append(options[:observer] + ":" + a.to_s)
    puts a.to_s
  end
  puts observer_list
  


  # TODO

  
end
