FROM ruby:3.0

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY /data ./data
COPY blockchain.rb observer.rb validator.rb crypto_helper.rb worker.rb ./

# default port
ENV PORT=7075

CMD ["./observer.rb"]