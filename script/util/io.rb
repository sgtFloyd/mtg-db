require 'multi_json'
require 'nokogiri'
require 'open-uri'
require 'net/http'
require 'net/https'

MAX_RETRIES = 4

def get(url, headers={}, silent: false, request_id: String.random(4))
  retry_count = 0
  begin
    puts "[#{request_id}] getting #{url}" unless silent
    Nokogiri::HTML(open(URI.escape(url), headers))
  rescue => error
    if (retry_count += 1) <= MAX_RETRIES
      delay_length = 3.pow(retry_count) * 100 # 300ms, 900ms, 2700ms, 8400ms
      puts "[#{request_id}] #{error} — Retrying in #{delay_length}ms" unless silent
      sleep(delay_length / 1000.0)
      retry
    else
      puts "[#{request_id}] #{error} — Not retrying" unless silent
    end
  end
end

def post_form(url, params={}, headers={}, silent: false)
  puts "posting #{url}" unless silent
  uri = URI.parse(url)
  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true
  req = Net::HTTP::Post.new(uri.path, initheader=headers)
  req.set_form_data(params)
  res = https.request(req)
  MultiJson.load(res.body)
end

def read(path, parser: MultiJson, silent: false)
  puts "reading #{path}" unless silent
  File.open(path, 'r') do |file|
    return parser.load(file.read)
  end
rescue => e
  puts "#{e}. Failed to read #{path}"
  []
end

def write(path, data, silent: false)
  puts "writing #{path}" unless silent
  File.open(path, 'w') do |file|
    file.puts MultiJson.dump(data, pretty: true).gsub(/\[\s+\]/, '[]')
  end
end
