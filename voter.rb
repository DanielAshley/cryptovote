#!/usr/bin/env ruby

require 'securerandom'
require 'json'
require 'rest-client'
require 'optparse'
require './crypto_helper'

class Voter
  ELIGIBLE_VOTERS_PATH = 'data/public_keys.json'.freeze
  ELECTION_PUBLIC_KEY_PATH = 'data/election_public.pem'.freeze
  RANDOM_RING_MEMBERS = ENV['RING_MEMBERS'].to_i || 10

  attr_reader :eligible_voters, :voter_private_key, :election_public_key

  # Initializes the voter object
  #
  # @param voter_private_key_hex [String] the private voter key.
  def initialize(voter_private_key_hex)
    @eligible_voters = JSON.parse(File.read(ELIGIBLE_VOTERS_PATH))
    @voter_private_key = CryptoHelper.private_key_from(voter_private_key_hex)
    @election_public_key = CryptoHelper.rsa_key(ELECTION_PUBLIC_KEY_PATH)
  end
  
  # Posting the new vote to the observer node
  #
  # @param candidate [String] the candidate the voter would like to vote for.
  # @param observer_address [String] the address of the observer node.
  # @return [Array] the result of the vote. @TODO not sure of the return type atm.
  def vote(candidate, observer_address)
    vote_plaintext = vote_str(candidate)
    vote_ciphertext = CryptoHelper.rsa_public_encrypt(vote_plaintext, election_public_key)

    ring_sig, public_keys = voter_private_key.sign(vote_ciphertext, random_ring_members)

    transaction = {
      vote: vote_ciphertext,
      ring_members: public_keys.map(&:to_hex),
      ring_signature: ring_sig.to_hex
    }

    RestClient::Request.new(
      method: :post,
      url: "#{observer_address}/transactions/new",
      payload: transaction.to_json,
      headers: { accept: :json, content_type: :json }
    ).execute do |response, _request, _result|
      response.to_str
    end
  end

  private

  # Creates the plaintext version of the vote
  #
  # @param candidate [String] the candidate the voter would like to vote for.
  # @return [String] the plaintext version of the vote.
  def vote_str(candidate)
    r = SecureRandom.random_number(10**9)
    "#{voter_private_key.key_image.x + voter_private_key.key_image.y}|#{candidate}|#{r}"
  end

  # @TODO: Figure this function out :P
  # Creates a signature for the vote
  # @return [Array] the list of random ring members
  def random_ring_members
    ring_members_hex = eligible_voters.sample(RANDOM_RING_MEMBERS)
    unique_ring_members_hex = (ring_members_hex - [voter_private_key.public_key.to_hex])
    unique_ring_members_hex.map { |hex| CryptoHelper.public_key_from(hex) }
  end
end

if $PROGRAM_NAME == __FILE__
  usage = 'usage: ./voter.rb -p PRIVATE_KEY -c CANDIDATE_NAME'

  options = {}
  OptionParser.new do |opt|
    opt.on('-p', '--private_key PRIVATE_KEY') { |o| options[:private_key] = o }
    opt.on('-c', '--candidate CANDIDATE') { |o| options[:candidate] = o }
  end.parse!

  abort(usage) unless options[:private_key]
  abort(usage) unless options[:candidate]

  voter = Voter.new(options[:private_key])
  result = voter.vote(options[:candidate], ENV['OBSERVER_ADDRESS'])
  puts result
end
