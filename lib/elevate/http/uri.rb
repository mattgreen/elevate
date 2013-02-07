module Elevate
module HTTP
  module URI
    def self.encode_query(hash)
      return "" if hash.nil? || hash.empty?

      hash.map do |key, value|
        "#{URI.escape_query_component(key.to_s)}=#{URI.escape_query_component(value.to_s)}"
      end.join("&")
    end

    def self.escape_query_component(component)
      component.gsub(/([^ a-zA-Z0-9_.-]+)/) do
        '%' + $1.unpack('H2' * $1.bytesize).join('%').upcase
      end.tr(' ', '+')
    end
  end
end
end
