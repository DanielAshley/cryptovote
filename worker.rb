#!/usr/bin/env ruby

require 'json'
require 'rest-client'
require 'optparse'
require './crypto_helper'

class Worker
  attr_reader :eligible_voters, :candidates, :parent_observer, :observer, :election_public_key

  def initialize(parent_observer, observer)
    @parent_observer = parent_observer
    @observer = observer
  end

  def postNodes(observer_address, nodes)
    nodes_payload = {
      nodes: nodes
    }

    RestClient::Request.new(
      method: :post,
      url: "#{observer_address}/nodes/register",
      payload: nodes_payload.to_json,
      headers: { accept: :json, content_type: :json }
    ).execute do |response, _request, _result|
      response.to_str
    end
  end
  
  def getNodes(observer_address)
    nodes = JSON.parse(RestClient.get("#{observer_address}/nodes/registered"))['nodes']
    return nodes
  end

  def getChain(observer_address)
    chain = JSON.parse(RestClient.get("#{observer_address}/chain"))['chain']
    return chain
  end

  def getVoters(observer_address)
    voters = JSON.parse(RestClient.get("#{observer_address}/voters"))['voters']
    return voters
  end

  def resolveChain(observer_address)
    response = JSON.parse(RestClient.get("#{observer_address}/nodes/resolve"))
    puts response['message']
    voters = response['chain']
    return voters
  end


end

if $PROGRAM_NAME == __FILE__
  usage = 'usage: ./worker.rb -p PARENT_OBSERVER -o LOCAL_OBSERVER_ADDRESS'

  options = {}
  OptionParser.new do |opt|
    opt.on('-p', '--parent_observer PARENT_OBSERVER') { |o| options[:parent_observer] = o }
    opt.on('-o', '--observer LOCAL_OBSERVER_ADDRESS') { |o| options[:observer] = o }
  end.parse!

  abort(usage) unless options[:parent_observer]
  abort(usage) unless options[:observer]

  worker = Worker.new(options[:parent_observer], options[:observer])

  # ITEM 1 - Local observer needs to be verified.
  # This includes checking if there is currently a chain and if its valid. 
  # It also includes checking for a voters list and observer node list
  # If the local observer node list is populated, the local observer needs to check the other nodes for the longest verified chain.

  worker.postNodes(options[:observer], [options[:parent_observer]])

  # Getting observer nodes set
  local_observer_nodes_list = worker.getNodes(options[:observer])
  #puts local_observer_nodes_list
  if local_observer_nodes_list.empty?()
    # If no local observer list is present, get node list from parent observer.
    puts "If no local observer list is present, get node list from parent observer."
    parent_nodes = worker.getNodes(options[:parent_observer])

    # copy parent observer node list and parent observer node address to local observer list.
    worker.postNodes(options[:observer], options[:parent_observer])
    worker.postNodes(options[:observer], parent_nodes)

    # update local observer chain based on updated local observer node list
    worker.resolveChain(options[:observer])
  else
    # If observer node list is present then get best chain from local observer list.
    puts "If observer node list is present then get best chain from local observer list."
    
    # update local observer chain based on local observer node list
    worker.resolveChain(options[:observer])
  end    



  # Getting current chain
  local_chain = worker.getChain(options[:observer])

  # Check if the current chain is empty.
  if local_chain.empty?
    # Check the local observer node list for nodes.
    puts "Check the local observer node list for nodes."
    
  else
    # If the current chain is not empty, verify chain is best chain in the network.
    puts "If the current chain is not empty, verify chain is best chain in the network."
    
    # update local observer chain based on local observer node list
    worker.resolveChain(options[:observer])

    # get chain from local observer.
    local_chain = worker.getChain(options[:observer])
  end

  puts local_chain

=begin
  while true    
    # update local observer chain based on local observer node list
    worker.resolveChain(options[:observer])

    # get chain from local observer.
    local_chain = worker.getChain(options[:observer])

    puts local_chain

    sleep(0.5)   
  end
=end

  # ITEM 2 - Local observer needs to be updated to either fill in any missing fields or add the parent observers observer list to the local observer list.
  






  #puts worker.getNodes(options[:parent_observer])
  #puts worker.getNodes(options[:observer])

  #parent_chain = worker.getChain(options[:parent_observer])
  #puts parent_chain
  
end
