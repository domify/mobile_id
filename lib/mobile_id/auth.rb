# frozen_string_literal: true

module MobileId
  class Auth

    # API documentation https://github.com/SK-EID/MID
    LIVE_URL = 'https://mid.sk.ee/mid-api'
    TEST_URL = 'https://tsp.demo.sk.ee/mid-api'

    TEST_UUID  = '00000000-0000-0000-0000-000000000000'
    TEST_NAME  = 'DEMO'

    attr_accessor :url, :uuid, :name, :doc, :hash, :user_cert, :live

    def initialize(live:, uuid: nil, name: nil, doc: nil)
      self.url = live == true ? LIVE_URL : TEST_URL
      self.uuid = live == true ? uuid : TEST_UUID
      self.name = live == true ? name : TEST_NAME
      self.live = live
      init_doc(doc || SecureRandom.hex(40))
    end

    def init_doc(doc)
      self.doc = doc
      self.hash = Digest::SHA256.digest(doc)
    end

    def authenticate!(phone:, personal_code:, phone_calling_code: nil, language: nil, display_text: nil)
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
          'Content-Type': 'application/json'
        },
        query: {},
        body: {
          relyingPartyUUID: uuid,
          relyingPartyName: name,
          phoneNumber: full_phone.to_s.strip,
          nationalIdentityNumber: personal_code.to_s.strip,
          hash: Base64.strict_encode64(hash),
          hashType: 'SHA256',
          language:,
          displayText: display_text,
          displayTextFormat: 'GSM-7' # or "UCS-2”
        }.to_json
      }

      response = HTTParty.post("#{url}/authentication", options)
      raise Error, "#{I18n.t('mobile_id.some_error')} #{response}" unless response.code == 200

      ActiveSupport::HashWithIndifferentAccess.new(
        session_id: response['sessionID'],
        phone:,
        phone_calling_code:,
        doc:
      )
    end

    def verify!(auth)
      long_poll!(session_id: auth['session_id'], doc: auth['doc'])

      ActiveSupport::HashWithIndifferentAccess.new(
        personal_code:,
        first_name:,
        last_name:,
        phone: auth['phone'],
        phone_calling_code: auth['phone_calling_code'],
        auth_provider: 'mobileid' # User::MOBILEID
      )
    end

    def session_request(session_id)
      response = HTTParty.get(url + "/authentication/session/#{session_id}")
      raise Error, "#{I18n.t('mobile_id.some_error')} #{response.code} #{response}" if response.code != 200

      response
    end

    def long_poll!(session_id:, doc:)
      response = nil

      # Retries until RUNNING state turns to COMPLETE
      30.times do |_i|
        response = session_request(session_id)
        break if response['state'] == 'COMPLETE'

        sleep 1
      end
      raise Error, "#{I18n.t('mobile_id.some_error')} #{response.code} #{response}" if response['state'] != 'COMPLETE'

      if response['result'] != 'OK'
        message =
          case response['result']
          when 'TIMEOUT'
            I18n.t('mobile_id.timeout')
          when 'NOT_MID_CLIENT'
            I18n.t('mobile_id.user_is_not_mobile_id_client')
          when 'USER_CANCELLED'
            I18n.t('mobile_id.user_cancelled')
          when 'SIGNATURE_HASH_MISMATCH'
            I18n.t('mobile_id.signature_hash_mismatch')
          when 'PHONE_ABSENT'
            I18n.t('mobile_id.phone_absent')
          when 'DELIVERY_ERROR'
            I18n.t('mobile_id.delivery_error')
          when 'SIM_ERROR'
            I18n.t('mobile_id.sim_error')
          end
        raise Error, message
      end

      @user_cert = MobileId::Cert.new(response['cert'], live:)
      @user_cert.verify_signature!(response['signature']['value'], doc)
      self.user_cert = @user_cert
    end

    def verification_code
      binary = hash.to_s.unpack1('B*')
      '%04d' % (binary[0...6] + binary[-7..]).to_i(2)
    end

    def given_name
      user_cert.given_name
    end
    alias first_name given_name

    def surname
      user_cert.surname
    end
    alias last_name surname

    def country
      user_cert.country
    end

    def common_name
      user_cert.common_name
    end

    def organizational_unit
      user_cert.organizational_unit
    end

    def serial_number
      user_cert.serial_number
    end
    alias personal_code serial_number

  end
end
