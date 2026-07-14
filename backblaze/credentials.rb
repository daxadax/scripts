module Backblaze
  module Credentials
    def self.fetch(public_key: nil, private_key: nil)
      {
        public_key: public_key || ENV.fetch('B2_PUBLIC_KEY'),
        private_key: private_key || ENV.fetch('B2_PRIVATE_KEY')
      }
    end
  end
end
