module Vebra
  class Branch

    attr_reader :id, :name, :url, :client

    def initialize(xml_doc, client)
      @name   = xml_doc.at_css('name').text
      @url    = xml_doc.at_css('url').text
      @id     = @url.match(/\/(\d+)$/)[1]
      @client = client
    end

    def get_branch
      doc = client.call(:branch, { :branch_id => id }).parsed_response
    end

  end
end