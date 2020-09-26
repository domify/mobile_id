# frozen_string_literal: true

module MobileId
  class Cert
    class << self
      def root_path
        @root_path ||= File.expand_path('certs', __dir__)
      end

      def live_store
        @live_store ||= 
          build_store([
            File.join(root_path, 'EE_Certification_Centre_Root_CA.pem.crt'),
            File.join(root_path, 'ESTEID-SK_2015.pem.crt')
          ])
      end

      def test_store
        binding.pry
        @test_store ||= 
          build_store([
            File.join(root_path, 'TEST_of_EE_Certification_Centre_Root_CA.pem.crt'),
            File.join(root_path, 'TEST_of_ESTEID-SK_2015.pem.crt')
          ])
      end

      def build_store(paths)
        store = OpenSSL::X509::Store.new
        paths.each { |path| cert = OpenSSL::X509::Certificate.new(File.read(path)); store.add_cert(cert) }
        store
      end
    end

    attr_accessor :cert, :subject

    def initialize(base64_cert, live:)
      self.cert = OpenSSL::X509::Certificate.new(Base64.decode64(base64_cert))
      verify!(self.cert, live: live)
      build_cert_subject
    end

    def verify!(cert, live:)
      store = live == true ? self.class.live_store : self.class.test_store
      raise Error, 'User certificate is not valid' unless store.verify(cert)
      raise Error, 'User certificate is not valid' unless cert.public_key.check_key
      raise Error, 'User certificate is expired' unless (cert.not_before..cert.not_after) === Time.now

      true
    end

    def verify_signature!(signature, doc)
      # TODO OpenSSL does not parse signature
      # cert.public_key.verify(OpenSSL::Digest::SHA256.new, signature, doc)
    end

    def given_name
      subject["GN"].tr(",", " ")
    end
    alias first_name given_name

    def surname
      subject["SN"].tr(",", " ")
    end
    alias last_name surname
    
    def country
      subject["C"].tr(",", " ")
    end

    def common_name
      subject["CN"]
    end

    def organizational_unit
      subject["OU"]
    end

    def serial_number
      subject["serialNumber"]
    end
    alias personal_code serial_number

    private

    def build_cert_subject
      self.subject = cert.subject.to_utf8.split(/(?<!\\)\,+/).each_with_object({}) do |c, result|
        next unless c.include?("=")

        key, val = c.split("=")
        result[key] = val
      end
    end
  end
end
