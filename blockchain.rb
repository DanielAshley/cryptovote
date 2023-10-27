#!/usr/bin/env ruby

require 'json'
require 'set'
require 'rest-client'
require './validator'
require './crypto_helper'

# Blockchain class which contains all of the major elements used during the voting process.
class Blockchain
  attr_reader :chain, :validator, :nodes, :eligible_voters, :eligible_voters_hash

  # Initializes the contents of blockchain and starts a genisis block on the blockchain.
  def initialize
    @chain = []
    @validator = Validator.new(chain)
    @nodes = Set.new
    @eligible_voters = []
    @eligible_voters_hash = nil

    # Create the genesis block
    new_block(previous_hash: 1, transaction: {})
  end

  # Create a new block in the blockchain
  #
  # @param transaction [Hash] the contents of the vote, ring_memebers, and ring_signature
  # @param previous_hash [String] the hash of the previous block in the blockchain. This is used only for the genisis block since the previous hash can be retrieved from the last block from the local blockchain.
  # @return [Hash] the contents of the new block pushed to the end of the local blockchain
  def new_block(transaction:, previous_hash: nil)
    block = {
      index: chain.length + 1,
      timestamp: Time.now.to_f,
      transaction: transaction,
      previous_hash: previous_hash || CryptoHelper.block_hash(last_block)
    }

    chain.push(block)
    block
  end

  # Create a new transaction to add a block to the blockchain
  #
  # @param vote_cipher [String, #read] the encrypted contents of the vote
  # @param ring_members [String, #read] the random set of voters (TODO: Add accurate description)
  # @param ring_sig_hex [String] the ring signature ... (TODO: Add accurate description)
  # @return [Hash] the contents of the new block pushed to the end of the local blockchain
  def new_transaction(vote_cipher:, ring_members:, ring_sig_hex:)
    if validator.valid_transaction?(vote_cipher, ring_members, ring_sig_hex)
      transaction = {
        vote: vote_cipher,
        ring_members: ring_members,
        ring_signature: ring_sig_hex
      }

      ring_sig = CryptoHelper.ringsig_from(ring_sig_hex)
      validator.add_voter(ring_sig.key_image)
      new_block(transaction: transaction)
    end
  end

  # Returns the last block of the blockchain.
  # @return [Hash] the last block in the blockchain
  def last_block
    chain[-1]
  end

  # This is our consensus algorithm, it resolves conflicts
  # by replacing our chain with the longest one in the network.
  # @return [Boolean] true if the local blockchain was replaced by anouther blockchain in the network, False if not
  def resolve_conflicts
    neighbors = nodes
    new_chain = nil
    new_validator = nil
    max_length = chain.length

    neighbors.each do |node|
      response = RestClient.get("http://#{node}/chain")
      next unless response.code != '200'
      response_body = JSON.parse(response.body)
      length = response_body['length']
      chain = response_body['chain']
      
      response = RestClient.get("http://#{node}/voters")
      next unless response.code != '200'
      response_body = JSON.parse(response.body)
      voters = response_body['voters']
      
      # @TODO: the voters list needs to be checked against the voters list hash, skips this observer if voters hash fails

      new_chain_validator = Validator.new(chain, voters)

      # Check if the length is longer and the chain is valid
      if length > max_length && new_chain_validator.valid_chain?
        max_length = length
        new_chain = chain
        new_validator = new_chain_validator
      end
    end

    # Replace our chain if we discovered a new, valid chain longer than ours
    if new_chain
      @chain = new_chain
      @validator = new_validator
      true
    else
      false
    end
  end

  # Add a new node to the list of nodes
  # address ex: http://192.168.0.5:5000
  # @param address [String] the address of the observer node to add to the network
  # @return [Hash] the contents of the new block pushed to the end of the local blockchain
  def register_node(address)
    parsed_url = URI.parse(address)
    nodes.add("#{parsed_url.host}:#{parsed_url.port}")
  end

  # Retrieves a list of eligable voters
  # @return [List] the eligable voters list
  def getEligableVoters()
    return @eligible_voters
  end

  # Retrieves the hash value for the list of eligable voters.
  # Used to verify that the voters list has not been modified.
  # @return [String] the eligable voters list hash value.
  def getEligableVotersHash()
    return @eligible_voters_hash
  end

  # Set the eligable voters list with hash
  # @param voters [List] the list of eligable voters
  # @param voters_hash [String] the hash value generated from the list of eligable voters
  def setEligableVoters(voters:, voters_hash:)
    @eligible_voters = voters
    @eligible_voters_hash = voters_hash
  end
end