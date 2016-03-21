begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end
require 'watir-webdriver'
require 'page-object'
require 'require_all'

begin
  require_all "#{File.join(File.expand_path(File.dirname(__FILE__)), '..', 'page_objects')}"
rescue
  puts "no page objects found"
end

@browser = nil

Before do | scenario |
  @version = ENV['version']
  @browserName = ENV['browserName']
  @platform = ENV['platform']
  @build = ENV['BUILD_NUMBER']

  capabilities_config = {
    :version => @version,
    :browserName => @browserName,
    :platform => @platform,
    :build => @build,
    :name => "#{scenario.feature.name} - #{scenario.name}"
  }

  url = "http://#{ENV['SAUCE_USERNAME']}:#{ENV['SAUCE_ACCESS_KEY']}@ondemand.saucelabs.com:80/wd/hub".strip
  client = Selenium::WebDriver::Remote::Http::Default.new
  client.timeout = 180
  @browser = Watir::Browser.new(:remote, :url => url, :desired_capabilities => capabilities_config, :http_client => client)
end

After do | scenario |
  sleep 1
  sessionid = @browser.driver.send(:bridge).session_id
  jobname = "#{scenario.feature.name} - #{scenario.name}"

  puts "SauceOnDemandSessionID=#{sessionid} job-name=#{jobname}"

  @browser.close

  if scenario.passed?
    `curl -s -u #{ENV['SAUCE_USERNAME']}:#{ENV['SAUCE_ACCESS_KEY']} \ -X PUT \ -H "Content-Type: application/json" \ -d '{"tags": ["testing-rest-api"],  "name": "REST API Test", "passed": true,  "custom-data": {"source": "Testing REST API"}}' \ https://saucelabs.com/rest/v1/#{ENV['SAUCE_USERNAME']}/jobs/#{sessionid}`
  else
    `curl -s -u #{ENV['SAUCE_USERNAME']}:#{ENV['SAUCE_ACCESS_KEY']} \ -X PUT \ -H "Content-Type: application/json" \ -d '{"tags": ["testing-rest-api"],  "name": "REST API Test", "passed": false,  "custom-data": {"source": "Testing REST API"}}' \ https://saucelabs.com/rest/v1/#{ENV['SAUCE_USERNAME']}/jobs/#{sessionid}`
  end
end