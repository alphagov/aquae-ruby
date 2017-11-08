WINDOWS = (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
PROTOC_PLUGIN_PATH = File.join Gem.bindir, "protoc-gen-ruby#{if WINDOWS then '.bat' else '' end}"
PROTO_DIR = './lib/aquae/protos'
PROTO_SRC_DIR = './build'
PROTOS = Rake::FileList['metadata.pb.rb', 'messaging.pb.rb', 'transport.pb.rb'].pathmap("#{PROTO_DIR}/%f")

directory PROTO_SRC_DIR
rule '.proto' => [PROTO_SRC_DIR, 'spec-version.yml'] do
  # Download/open the tgz and extract the contents
  # Adapted from https://gist.github.com/sinisterchipmunk/1335041 (MIT)
  require 'yaml'
  require 'open-uri'
  require 'zlib'
  require 'rubygems/package'

  path = YAML.load_file('spec-version.yml')['spec']
  rake_output_message "tar -xf #{path} #{PROTO_SRC_DIR}"
  Gem::Package::TarReader.new(Zlib::GzipReader.new(open(path, 'rb'))) do |tar|
    tar.each do |tarfile|
      File.binwrite File.join(PROTO_SRC_DIR, tarfile.full_name), tarfile.read
    end
  end
end

directory PROTO_DIR
task :protos => [PROTO_DIR, *PROTOS]

rule '.pb.rb' => lambda {|n| "#{PROTO_SRC_DIR}/#{n.pathmap('%{.pb,}n')}.proto" } do |p|
  sh 'protoc',
    p.source,
    '-I', PROTO_SRC_DIR,
    "--ruby2_out=#{p.name.pathmap('%d')}",
    "--plugin=protoc-gen-ruby2=#{PROTOC_PLUGIN_PATH}"
end