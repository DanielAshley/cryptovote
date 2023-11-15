FROM ruby

WORKDIR /usr/src/app

COPY Gemfile ./
RUN bundle install

COPY /data ./data
COPY blockchain.rb observer.rb validator.rb crypto_helper.rb ./

# default port
EXPOSE 7075

CMD ruby observer.rb