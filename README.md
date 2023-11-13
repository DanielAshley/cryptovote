
# cryptovote
PoC implementation for the blockchain based election protocol – CryptoVote

## Install ruby and gems (Ubuntu)
```
sudo apt-get update
sudo apt-get install libssl-dev gcc g++ make ruby-full ruby-bundler ruby rdoc
```
## Install required gems
```
bundle install
```

## Start an observer node (2 Methods)
### Using the command line interface (terminal):
```
PORT=7075 ./observer.rb
```
### Using Docker:
```
docker build -t cryptovote .
docker run -it -p 127.0.0.1:7075:7075 --net="host" --rm --name observer cryptovote
```

## View the blockchain
```
curl http://localhost:7075/chain
```

## Vote
A command line method of casting a vote. The voter key in the example is part of the sample voter list provided with the repo. If new voter keys are generated then the example below will need to use a different voter key.
./voter.rb -p PRIVATE_KEY -c CANDIDATE_NAME -o OBSERVER_ADDRESS -v VOTERS_LIST_HASH -e ELECTION_PUBLIC_KEY

Example:
```
./voter.rb -p 000000000000000000000000000000004a0f1e1ec8b44d4bba77616574b177ce -c "Hulk" -o "http://localhost:7075" -v "data/public_keys.json" -e "data/election_public.pem"
```

## Count the votes
```
./counter.rb -c "http://localhost:7075/chain" -p "data/election_private.pem"
```

## Testing

#### Run atleast one observer before testing.
```
./election_perftest.rb -v 5 -o "http://localhost:7075" -e "data/election_public.pem"
```
