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
                        File.join(root_path, 'EE-GovCA2018.pem.crt'),
                        File.join(root_path, 'EID-SK_2011.pem.crt'),
                        File.join(root_path, 'EID-SK_2016.pem.crt'),
                        File.join(root_path, 'esteid2018.pem.crt'),
                        File.join(root_path, 'ESTEID-SK_2011.pem.crt'),
                        File.join(root_path, 'ESTEID-SK_2015.pem.crt'),
                        File.join(root_path, 'KLASS3-SK_2010_EECCRCA.pem.crt'),
                        File.join(root_path, 'KLASS3-SK_2010_EECCRCA_SHA384.pem.crt'),
                        File.join(root_path, 'KLASS3-SK_2016_EECCRCA_SHA384.pem.crt'),
                        File.join(root_path, 'KLASS3-SK.pem.crt'),
                        File.join(root_path, 'NQ-SK_2016.pem.crt')
                      ])
      end

      def test_store
        @test_store ||=
          build_store([
                        File.join(root_path, 'TEST_of_EE_Certification_Centre_Root_CA.pem.crt'),
                        File.join(root_path, 'TEST_of_ESTEID-SK_2015.pem.crt')
                      ])
      end

      def build_store(paths)
        store = OpenSSL::X509::Store.new
        paths.each do |path|
          cert = OpenSSL::X509::Certificate.new(File.read(path))
          store.add_cert(cert)
        end
        store
      end

    end

    attr_accessor :cert, :subject

    def initialize(base64_cert, live:)
      self.cert = OpenSSL::X509::Certificate.new(Base64.decode64(base64_cert))
      verify!(cert, live:)
      build_cert_subject
    end

    def verify!(cert, live:)
      if live == true
        raise Error, 'User certificate is not valid' unless self.class.live_store.verify(cert)
      else
        unless self.class.test_store.verify(cert) || self.class.live_store.verify(cert)
          raise Error,
                'User certificate is not valid'
        end
      end

      raise Error, 'User certificate is not valid [check_key]' unless cert.public_key.check_key
      raise Error, 'User certificate is expired' unless (cert.not_before...cert.not_after).include?(Time.now)

      true
    end

    def verify_signature!(signature_base64, doc)
      signature = Base64.decode64(signature_base64)
      digest = OpenSSL::Digest::SHA256.new(doc)

      valid =
        begin
          cert.public_key.verify(digest, signature, doc)
        rescue OpenSSL::PKey::PKeyError
          der_signature = cvc_to_der(signature) # Probably signature is CVC encoded
          cert.public_key.verify(digest, der_signature, doc)
        end

      raise Error, 'We could not verify user signature' unless valid
    end

    def cvc_to_der(cvc)
      sign_hex = cvc.unpack1('H*')
      half = sign_hex.size / 2
      i = [OpenSSL::ASN1::Integer.new(sign_hex[0...half].to_i(16)),
           OpenSSL::ASN1::Integer.new(sign_hex[half..sign_hex.size].to_i(16))]
      seq = OpenSSL::ASN1::Sequence.new(i)
      seq.to_der
    end

    def given_name
      subject['GN'].tr(',', ' ')
    end
    alias first_name given_name

    def surname
      subject['SN'].tr(',', ' ')
    end
    alias last_name surname

    def country
      subject['C'].tr(',', ' ')
    end

    def common_name
      subject['CN']
    end

    def organizational_unit
      subject['OU']
    end

    def serial_number
      subject['serialNumber']
    end
    alias personal_code serial_number

    private

    def build_cert_subject
      self.subject = cert.subject.to_utf8.split(/(?<!\\),+/).each_with_object({}) do |c, result|
        next unless c.include?('=')

        key, val = c.split('=')
        result[key] = val
      end
    end

  end
end
