module Colppy
  module UserActions
    extend self

    def session_key
      @user.key
    end

    def username
      @user.username
    end

    def user=(new_user)
      @user = new_user
    end

    def sign_in(user = nil)
      user ||= @user
      ensure_user_valid!(user)

      user.sign_in(self)
    end

    def sign_out(user = nil)
      user ||= @user
      ensure_user_valid!(user)

      user.sign_out(self)
    end

    def session_params
      {
        sesion: {
          usuario: username,
          claveSesion: session_key
        }
      }
    end

    private

    def ensure_user_valid!(user)
      unless user.is_a?(Colppy::User)
        raise ClientError.new("The user should be a Colppy::User instance")
      end
    end
  end

  class User < Resource
    include Digest
    attr_reader :username, :key

    def initialize(username, password, key = nil)
      @username = username
      @password = md5(password)
      @key = key
    end

    def sign_in(client)
      response = client.call(
        :user,
        :sign_in,
        {
          usuario: @username,
          password: @password
        }
      )
      save_session(response[:data]) if response[:success]
    end

    def sign_out(client)
      response = client.call(
        :user,
        :sign_out,
        sesion: {
          usuario: @username,
          claveSesion: key
        }
      )
      destroy_session if response[:success]
    end

    private

    def attr_inspect
      [:username, :key]
    end

    def save_session(sign_in_data)
      @key = sign_in_data[:claveSesion]
    end

    def destroy_session
      @key = nil
    end
  end
end
