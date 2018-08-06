require 'net/http'

API_URL = 'https://rcrainfopreprod.epa.gov/rcrainfo/rest/api/v1/'.freeze
API_ID = 'ID'.freeze
API_KEY = 'KEY'.freeze

# options of services for the user to choose
LOOKUP_CHOICES = ['lookup/form-codes',
                  'lookup/source-codes',
                  'lookup/density-uom',
                  'lookup/state-waste-codes',
                  'lookup/federal-waste-codes',
                  'lookup/management-method-codes'].freeze

# Blank if no args required
LOOKUP_ARG_REQ = ['', '', '', 'stateCode', '', ''] .freeze

# Wrapper for the EPA eManifest API
class Wrapper
  attr_reader :session_token

  # Logging the session token for future use
  def initialize
    uri = URI(API_URL + "auth/#{API_ID}/#{API_KEY}")
    response = Net::HTTP.get(uri)

    # Removing invalid characters from token
    token = response.split(' ')[3]
    token = token.delete('\"')
    token = token.delete('\"')
    token = token.delete(',')
    @session_token = token
  end

  # Establish authentication with the session session_token
  # Params
  # - uri: Uniform Resource Identifier, in our case, the url
  # return
  # - request: HTTP request being handled
  def authenticate(uri)
    request = Net::HTTP::Get.new(uri)
    request['Accept'] = 'application/json'
    request['Authorization'] = "Bearer #{@session_token}"
    request
  end

  # Opens HTTP Connection to the URI
  # Params
  # - uri Uniform Resource Identifier, in our case, the url
  # return
  # - response : Net:HTTP Response Object
  def connect(uri)
    request = authenticate(uri)

    req_options = { use_ssl: uri.scheme == 'https' }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    response
  end

  # Takes the URL extension and adds it
  # the api's url including any arguements
  # if they are included
  # Params
  # - extension: the string expression being added
  # - arg: the argument being sent, if any
  def lookup_services(extension, arg)
    extension += "/#{arg}"
    uri = URI.parse(API_URL + extension)
    response = connect(uri)
    puts response.body
  end

  # Displays the options for the user to
  # select and ensures they are within the
  # proper range
  # return
  # - input: the index of the API operation the
  #        user would like to interact with
  def menu
    input = nil

    while input.to_i != -1 && (input.to_i < 1 || input.to_i > 6)
      index = 1 # reset the counter each time a option is being chosen
      puts 'Enter the number for which API
       lookup service you would like to test:'

      for i in LOOKUP_CHOICES
        puts "#{index} ... #{i}"
        index += 1
      end

      puts '-1 .. to exit'
      print '>>'
      input = gets.chomp
    end
    input.to_i
  end
end

wrapper = Wrapper.new

# Takes the user input and checks
# if they'd like to exit
input = wrapper.menu
while input != -1

  # handle any arguments
  arg = nil
  if LOOKUP_ARG_REQ[input - 1] != ''
    puts "Please enter the #{LOOKUP_ARG_REQ[input - 1]}"
    print '>>'
    arg = gets.chomp
  end

  # perform API lookup service
  wrapper.lookup_services(LOOKUP_CHOICES[input - 1], arg)
  input = wrapper.menu
end
