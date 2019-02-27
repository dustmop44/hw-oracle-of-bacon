require 'byebug'                # optional, may be helpful
require 'open-uri'              # allows open('http://...') to return body
require 'cgi'                   # for escaping URIs
require 'nokogiri'              # XML parser
require 'active_model'          # for validations

class OracleOfBacon

  class InvalidError < RuntimeError ; end
  class NetworkError < RuntimeError ; end
  class InvalidKeyError < RuntimeError ; end

  attr_accessor :from, :to
  attr_reader :api_key, :response, :uri
  
  include ActiveModel::Validations
  validates_presence_of :from
  validates_presence_of :to
  validates_presence_of :api_key
  validate :from_does_not_equal_to

  def from_does_not_equal_to
    if @from == @to
      errors.add(:from_equals_to, "From cannot be the same as To")
    end
  end

  def initialize(api_key='38b99ce9ec87')
    @api_key = api_key
    @from = "Kevin Bacon"
    @to = "Kevin Bacon"
  end

  def find_connections
    make_uri_from_arguments
    begin
      xml = URI.parse(uri).read
    rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
      Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError,
      Net::ProtocolError => e
      # convert all of these into a generic OracleOfBacon::NetworkError,
      #  but keep the original error message
      # your code here
      raise OracleOfBacon::NetworkError, e
    end
    # your code here: create the OracleOfBacon::Response object
    @response = Response.new(xml)
  end

  def make_uri_from_arguments
    # your code here: set the @uri attribute to properly-escaped URI
    #   constructed from the @from, @to, @api_key arguments
    @uri = "http://oracleofbacon.org/cgi-bin/xml?p=#{@api_key}&a=#{CGI.escape(@from)}&b=#{CGI.escape(@to)}"
  end
      
  class Response
    attr_reader :type, :data
    # create a Response object from a string of XML markup.
    def initialize(xml)
      @doc = Nokogiri::XML(xml)
      parse_response
    end

    private

    def parse_response
      if ! @doc.xpath('/error').empty?
        parse_error_response
      # your code here: 'elsif' clauses to handle other responses
      # for responses not matching the 3 basic types, the Response
      # object should have type 'unknown' and data 'unknown response' 
      elsif ! @doc.xpath('/link').empty?
        @type = :graph
        parse_link_response
      elsif ! @doc.xpath('/spellcheck').empty?
        @type = :spellcheck
        @data = @doc.xpath('//match').map {|node| node.text}
      else
        @type = :unknown
        @data = 'unknown response type'
      end
    end
    
    def parse_link_response
      actors = @doc.xpath('//actor').map {|node| node.text}
      movies = @doc.xpath('//movie').map {|node| node.text}
      @data = actors.zip(movies).flatten.compact
    end
      
    
    def parse_error_response
      @type = :error
      @data = 'Unauthorized access'
    end
  end
end

