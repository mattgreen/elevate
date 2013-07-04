module Elevate
module HTTP
  module URI
    def self.encode_www_form(enum)
      enum.map do |k,v|
        if v.nil?
          encode_www_form_component(k)
        elsif v.respond_to?(:to_ary)
          v.to_ary.map do |w|
            str = encode_www_form_component(k)

            if w.nil?
              str
            else
              str + "=" + encode_www_form_component(w)
            end
          end.join('&')
        else
          encode_www_form_component(k) + "=" + encode_www_form_component(v)
        end
      end.join('&')
    end

    def self.encode_www_form_component(str)
      # From AFNetworking :)
      CFURLCreateStringByAddingPercentEscapes(nil,
                                              str,
                                              "[].",
                                              ":/?&=;+!@\#$()~',*",
                                              CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding))
    end

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
