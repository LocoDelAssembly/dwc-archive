require 'simplecov'
SimpleCov.start

if ENV['CI'] == 'true' && false
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../../lib')
require 'dwc_archive'

require 'rspec/expectations'
