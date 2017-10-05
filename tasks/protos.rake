WINDOWS = (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
PROTOC_PLUGIN_PATH = File.join Gem.bindir, "protoc-gen-ruby#{if WINDOWS then '.bat' else '' end}"
PROTO_DIR = './lib/aquae/protos'
PROTO_SRC_DIR = '../pde-specification'
PROTOS = Rake::FileList['metadata.pb.rb', 'messaging.pb.rb', 'transport.pb.rb'].pathmap("#{PROTO_DIR}/%f")

directory PROTO_DIR
task :protos => [PROTO_DIR, *PROTOS]

rule '.pb.rb' => lambda {|n| "#{PROTO_SRC_DIR}/#{n.pathmap('%{.pb,}n')}.proto" } do |p|
  sh 'protoc',
    p.source,
    '-I', PROTO_SRC_DIR,
    "--ruby2_out=#{p.name.pathmap('%d')}",
    "--plugin=protoc-gen-ruby2=#{PROTOC_PLUGIN_PATH}"
end