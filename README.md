
# cryptovote
PoC implementation for the blockchain based election protocol – CryptoVote

## Install ruby and gems (Ubuntu)
```
sudo apt-get update
sudo apt-get install libssl-dev
sudo apt-get install ruby-full ruby-bundle rubygems
```
## Install required gems
```
bundle install
```

## Start an observer node 
### In the terminal:
```
PORT=7075 ./observer.rb
```
### Using Docker:
```
docker build -t cryptovote .
docker run -it -p 127.0.0.1:7075:7075 --net="host" --rm --name observer cryptovote
```

## Access the blockchain
```
curl http://localhost:7075/chain
```

## Vote
```
OBSERVER_ADDRESS=http://localhost:7075 ./voter.rb -p 000000000000000000000000000000004a0f1e1ec8b44d4bba77616574b177ce -c "Hulk"
```

## Count the votes
```
./counter.rb -c http://localhost:7075/chain
```

## Testing

#### Run atleast one observer before testing.
```
RING_MEMBERS=10 OBSERBER_ADDRESS=http://localhost:7075 ./election_perftest.rb -v 20
```