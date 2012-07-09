require 'valvat'
require 'net/http'
require 'yaml'

class Valvat
  module Lookup

    def self.validate(vat)
      vat = Valvat(vat)
      return false unless vat.european?

      begin
        client.request("n1", "checkVat") do
          soap.body = {"n1:countryCode" => vat.vat_country_code, "n1:vatNumber" => vat.to_s_wo_country}
          soap.namespaces["xmlns:n1"] = "urn:ec.europa.eu:taxud:vies:services:checkVat:types"
        end.to_hash[:check_vat_response][:valid]
      rescue => err
        if err.respond_to?(:to_hash) && err.to_hash[:fault] && err.to_hash[:fault][:faultstring] == "{ 'INVALID_INPUT' }"
          return false
        end
        raise err
      end
    end

    def self.client
      @client ||= begin
        # Require Savon only if really needed!
        require 'savon' unless defined?(Savon)
                
        # Quiet down HTTPI
        HTTPI.log = false  
        
        # Quiet down Savon
        Savon.configure do |config|
          config.log = false            # disable logging
          config.log_level = :info      # changing the log level
        end

        Savon::Client.new do
          wsdl.document = 'http://ec.europa.eu/taxation_customs/vies/checkVatService.wsdl'
        end
        

      end
    end
  end
end
