REPO_DIR = './repo'
GEM_DIR  = File.join REPO_DIR, './gems'
directory REPO_DIR
directory GEM_DIR => REPO_DIR

desc 'Downloads existing artifacts from S3'
task :gems => GEM_DIR do
  require 'aws-sdk-s3'
  creds = Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
  bucket = Aws::S3::Resource.new(region: 'eu-west-2', credentials: creds).bucket('aquae-ruby')
  bucket.objects(delimiter: '/', prefix: 'gems/').reject {|f| f.key == 'gems/' }.each do |gem|
    outfile = File.join REPO_DIR, gem.key
    rake_output_message "cp s3://aquaw-ruby/#{gem.key} #{outfile}"
    File.open(outfile, 'wb') do |out|
      gem.get &out.method(:write)
    end
  end
end

desc 'Generates Gem indexes for a static Gemserver'
task :repo => REPO_DIR do
  sh "cd #{REPO_DIR} && gem generate_index ."
end