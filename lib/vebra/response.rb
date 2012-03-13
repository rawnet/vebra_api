module Vebra
  class Response

    attr_accessor :response_object, :parsed_response

    # Parse the XML body from a Net::HTTP response object
    # using Nokogiri, also preserving the original response

    def initialize(response)
      @response_object = response
      @parsed_response = Nokogiri::XML(response.body)
    end

  end
end