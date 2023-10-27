#!/usr/bin/env ruby

require 'json'
require 'rest-client'
require 'optparse'
require './crypto_helper'

# The worker class used to act as a server client, checkig and triggering updates to a specific observer node
class Worker
  attr_reader :eligible_voters, :parent_observer, :observer, :election_public_key

  # Initializes the worker with the data needed to start the voting blockchain
  #
  # @param observer [String] the address of the observer node to be setup
  # @param eligible_voters [Array] the list of eligible voters.
  # @param eligible_voters_hash [String] the hash value of the list of eligible voters. @Note the list of eligible voters must not change or be reordered or the hash value wont match.
  # @param election_public_key [String] the public key used during the vote. @Note the corresponding private key is kept secret/safe until the end of the election
  def initialize(observer, eligible_voters, eligible_voters_hash, election_public_key)
    @observer = observer
    @eligible_voters = eligible_voters
    @eligible_voters_hash = eligible_voters_hash
    @election_public_key = election_public_key
  end

  # Posts a list of observer node addresses to a specified observer node address
  #
  # @param nodes [List] the observer node address to be linked to a specified (or default) observer node
  # @param observer_address [String] the address of the observer node the list of observer nodes will be added to
  def setNodes(nodes, observer_address: @observer)
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
  
  # Gets a list of observer node addresses from a specified observer node address
  #
  # @param observer_address [String] the address of the observer node the list of observer nodes will be requested from.
  # @return [Array] the list of observer nodes connected to a specific observer node on the network.
  def getNodes(observer_address: @observer)
    nodes = JSON.parse(RestClient.get("#{observer_address}/nodes/registered"))['nodes']
    return nodes
  end
  
  # Gets the latest blockchain from a specified observer node address
  #
  # @param observer_address [String] the address of the observer node the blockchain will be requested from.
  # @return [Array] the blockchain contained on a specific observer node on the network.
  def getChain(observer_address: @observer)
    chain = JSON.parse(RestClient.get("#{observer_address}/chain"))['chain']
    return chain
  end

  # Gets the voters list from a specified observer node address
  #
  # @param observer_address [String] the address of the observer node the voter list will be requested from.
  # @return [Array] the list of voters contained by a specific observer.
  def getVoters(observer_address: @observer)
    voters = JSON.parse(RestClient.get("#{observer_address}/voters"))['voters']
    return voters
  end

  # Sends a voters list to a specified observer node address
  #
  # @param voters [List] the list of voters to be sent to a specific oberserver node
  # @param voters_hash [String] the hash generated from the list of voters
  # @param observer_address [String] the address of the observer node the voter list will be sent to.
  def setVoters(voters, voters_hash, observer_address: @observer)    
    voters_payload = {
      voters: voters,
      voters_hash: voters_hash
    }

    RestClient::Request.new(
      method: :post,
      url: "#{observer_address}/voters_list",
      payload: voters_payload.to_json,
      headers: { accept: :json, content_type: :json }
    ).execute do |response, _request, _result|
      response.to_str
    end
  end

  # Triggers a given node to determine if its current chain is the latest on its known network connections
  #
  # @param observer_address [String] the address of the observer node.
  # @return [Array] the most up to date blockchain from a specific observer node after it has checked the blockchains on its connected network.
  def resolveChain(observer_address: @observer)
    response = JSON.parse(RestClient.get("#{observer_address}/nodes/resolve"))
    puts response['message']
    chain = response['chain']
    return chain
  end
  
  # Verifies the voter list stored on an observer node
  #
  # @param observer_address [String] the address of the observer node to be verified.
  # @return [Boolean] returns true if the voter list on a specific observer node has been verified, false if it fails verification.
  def verifyVotersList(observer_address: @observer)   
    # Verification of votors list
    voters_list = getVoters(observer_address: observer_address)
    if voters_list.empty?
      eligible_votors_from_file = @eligible_voters
      eligible_votors_hash_from_file = @eligible_voters_hash

      # Check voter list from file against the pregenerated hash value to verify validity before adding them to the observer node.
      if eligible_votors_hash_from_file != CryptoHelper.voters_hash(eligible_votors_from_file)
        pust 'Error: The hash generated from the voters list provided from file does not match the official voters list hash'
        return false
      end
  
      setVoters(eligible_votors_from_file, eligible_votors_hash_from_file)
    else
      # if voter list is not empty
      if @eligible_voters_hash != CryptoHelper.voters_hash(voters_list)
        puts 'Error: The hash generated from the voters list provided from file does not match the official voters list hash'
        return false
      end

      #puts "Voter List Check: Success. The hash of the voters list on the observer node matches the eligible voters hash loaded from file"
    end
    return true
  end

  # @TODO: Perform more thourough verification
  # Verifies the blockchain stored on an observer node
  #
  # @param observer_address [String] the address of the observer node to be verified.
  # @return [Boolean] returns true if the blockchain on a specific observer node has been verified, false if it fails verification.
  def verifyBlockchain(observer_address: @observer)
    local_chain = getChain(observer_address: observer_address)
    if local_chain.empty? # Check if the current chain is empty.
      # chain is empty, generate genisis block using election commission public key (TODO: or private?)
      return false
    else
      # Check the loaded chain is valid. Also check the genisis block hash against a genisis block hash generated by the election commision public key (TODO: or private?)
    end
    return true
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
