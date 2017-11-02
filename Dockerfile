FROM ubuntu:zesty
RUN apt-get -y update
RUN apt-get -y install protobuf-compiler ruby2.3 git
RUN gem install bundler
