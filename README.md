# cryptovote

PoC implementation for the blockchain based election protocol – CryptoVote

* Install ruby and gems (Ubuntu)
```
sudo apt-get update
sudo apt-get install libssl-dev
sudo apt-get install ruby-full ruby-bundle rubygems
```

* Install required gems
```
bundle install
```

* Start an observer node

```
PORT=7075 ./observer.rb
```

* Access the blockchain

```
curl http://localhost:7075/chain
```

* Vote 

```
OBSERVER_ADDRESS=http://localhost:7075 ./voter.rb -p 000000000000000000000000000000004a0f1e1ec8b44d4bba77616574b177ce -c "Hulk"
```


* Count the votes 

```
./counter.rb -c http://localhost:7075/chain
```

* Testint 
Run atleast one observer before testing.

```
RING_MEMBERS=10 OBSERBER_ADDRESS=http://localhost:7075 ./election_perftest.rb -v 20
```
