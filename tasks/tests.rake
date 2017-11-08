require 'rake/testtask'

Rake::TestTask.new do |t|
  t.name = :test
  t.pattern = 'test/*_test.rb'
  t.options = '"--no-show-detail-immediately"'
  t.warning = false
end
