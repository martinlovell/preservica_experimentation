# frozen_string_literal: true

require 'net/http'
require 'openssl'
require 'json'

class PreservicaClient

  def initialize(host, username, password)
    @host = host
    @username = username
    @password = password
  end

  def login
    uri = URI(@host)
    Net::HTTP.start(uri.host, uri.port,
                    :use_ssl => uri.scheme == 'https',
                    :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
      request = Net::HTTP::Post.new "/api/accesstoken/login"
      request.set_form_data({"username" => @username, "password" => @password})
      response = http.request request # Net::HTTPResponse object
      if response.kind_of? Net::HTTPSuccess
        @login_info = JSON.parse(response.body)
        puts @login_info
      else
        raise StandardError.new "Unable to login"
      end
    end
  end

  def refresh
    authenticated_post URI("#{@host}/api/accesstoken/refresh") do |http, request|
      request.set_form_data({"refreshToken" => @login_info["refresh-token"]})
      response = http.request request
      puts response.body
    end
  end

  def get uri
    authenticated_get URI("#{@host}#{uri}") do |http, request|
      response = http.request request
      return response.body
    end
  end

  def authenticated_post uri
    Net::HTTP.start(uri.host, uri.port,
                    :use_ssl => uri.scheme == 'https',
                    :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|

      request = Net::HTTP::Post.new uri.request_uri
      request["Preservica-Access-Token"] = @login_info['token']
      yield http, request
    end
  end

  def authenticated_get uri
    Net::HTTP.start(uri.host, uri.port,
                    :use_ssl => uri.scheme == 'https',
                    :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
      request = Net::HTTP::Get.new uri.request_uri
      request["Preservica-Access-Token"] = @login_info['token']
      yield http, request
    end
  end

end

username = ENV['PRESERVICA_USERNAME']
password = ENV['PRESERVICA_PASSWORD']

preservica_client = PreservicaClient.new(ENV['PRESERVICA_HOST'], username, password)
preservica_client.login
#preservica_client.refresh
data = preservica_client.get '/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a5e3d/representations/Preservation/1'
puts data