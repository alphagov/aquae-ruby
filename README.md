# Aquae

This gem is a low-level library for interacting with an AQuAE (Attributes, Questions, Answers and Eligibility) system. It provides the APIs for opening connections and sending messages between nodes, on top of which applications can be written.

To be explicit, this library provides the following:

* Endpoint for sending and receiving messages
* Encryption and identity checking
* Metadata parsing

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'aquae'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install aquae

## Usage

TODO: Write usage instructions here.

## Development

The gem requires compiled Protocol Buffers from the `pde-specification` repo to be present. You can compile the Ruby files by running:

    $ rake protos

For this, you need `protoc` to be installed and have a copy of the specification in a directory at `../pde-specification`. The build script for your system should also have been run to generate the relevant `*.proto` files. TODO: make this more straightforward.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

TODO: Write contributing instructions here.
