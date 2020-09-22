# frozen_string_literal: true

module MobileId
  class Auth
    # API documentation https://github.com/SK-EID/MID
    LIVE_URL = "https://mid.sk.ee/mid-api"
    TEST_URL = "https://tsp.demo.sk.ee/mid-api"

    TEST_UUID  = "00000000-0000-0000-0000-000000000000"
    TEST_NAME  = "DEMO"

    attr_accessor :url, :uuid, :name, :hash, :cert, :cert_subject

    def initialize(live:, uuid: nil, name: nil)
      self.url = live == true ? LIVE_URL : TEST_URL
      self.uuid = live == true ? uuid : TEST_UUID
      self.name = live == true ? name : TEST_NAME
      self.hash = Digest::SHA256.base64digest(SecureRandom.uuid)
    end

    def authenticate!(phone_calling_code: nil, phone:, personal_code:, language: nil, display_text: nil)
      phone_calling_code ||= '+372'
      full_phone = "#{phone_calling_code}#{phone}"
      language ||= 
        case I18n.locale
        when :et
          display_text ||= 'Autentimine' 
          'EST'
        when :ru
          display_text ||= 'Аутентификация' 
          'RUS'
        else
          display_text ||= 'Authentication' 
          'ENG'
        end
      
      options = {
        headers: {
          "Content-Type": "application/json"
        },
        query: {},
        body: {
          relyingPartyUUID: uuid,
          relyingPartyName: name,
          phoneNumber: full_phone.to_s.strip,
          nationalIdentityNumber: personal_code.to_s.strip,
          hash: hash,
          hashType: 'SHA256',
          language: language,
          displayText: display_text,
          displayTextFormat: 'GSM-7' # or "UCS-2”
        }.to_json
      }

      response = HTTParty.post(url + '/authentication', options)
      raise Error, "#{I18n.t('mobile_id.some_error')} #{response}" unless response.code == 200

      ActiveSupport::HashWithIndifferentAccess.new(
        session_id: response['sessionID'],
        phone: phone,
        phone_calling_code: phone_calling_code
      )
    end

    def verify!(auth)
      long_poll!(session_id: auth['session_id'])

      ActiveSupport::HashWithIndifferentAccess.new(
        personal_code: personal_code,
        first_name: first_name,
        last_name: last_name,
        phone: auth['phone'],
        phone_calling_code: auth['phone_calling_code'],
        auth_provider: 'mobileid' # User::MOBILEID
      )
    end

    def long_poll!(session_id:)
      response = HTTParty.get(url + "/authentication/session/#{session_id}")
      raise Error, "#{I18n.t('mobile_id.some_error')} #{response.code} #{response}" if response.code != 200

      if response['state'] == 'COMPLETE' && response['result'] != 'OK'
        message = 
          case response['result']
          when "TIMEOUT"
            I18n.t('mobile_id.timeout')
          when "NOT_MID_CLIENT"
            I18n.t('mobile_id.user_is_not_mobile_id_client')
          when "USER_CANCELLED"
            I18n.t('mobile_id.user_cancelled')
          when "SIGNATURE_HASH_MISMATCH"
            I18n.t('mobile_id.signature_hash_mismatch')
          when "PHONE_ABSENT"
            I18n.t('mobile_id.phone_absent')
          when "DELIVERY_ERROR"
            I18n.t('mobile_id.delivery_error')
          when "SIM_ERROR"
            I18n.t('mobile_id.sim_error')
          end
        raise Error, message
      end

      self.cert = OpenSSL::X509::Certificate.new(Base64.decode64(response['cert']))
      self.cert_subject = build_cert_subject
      cert
    end

    def verification_code
      format("%04d", (Digest::SHA2.new(256).digest(Base64.decode64(hash))[-2..-1].unpack1('n') % 10000))
    end

    def given_name
      cert_subject["GN"].tr(",", " ")
    end
    alias first_name given_name

    def surname
      cert_subject["SN"].tr(",", " ")
    end
    alias last_name surname
    
    def country
      cert_subject["C"].tr(",", " ")
    end

    def common_name
      cert_subject["CN"]
    end

    def organizational_unit
      cert_subject["OU"]
    end

    def serial_number
      cert_subject["serialNumber"]
    end
    alias personal_code serial_number

    private

    def build_cert_subject
      self.cert_subject = cert.subject.to_utf8.split(/(?<!\\)\,+/).each_with_object({}) do |c, result|
        next unless c.include?("=")

        key, val = c.split("=")
        result[key] = val
      end
    end
  end
end
