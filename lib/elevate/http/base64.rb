module Elevate
module HTTP
  module Base64
    def self.encode(s)
      [s].pack("m0")
    end
  end
end
end
