require 'rails_helper'

RSpec.describe AuthorizeApiRequest do
  # Create test user
  let(:user) { FactoryBot.create(:user) }
  # Mock `Authorization` header
  let(:header) { { 'Authorization' => token_generator(user.id) } }
  # Invalid request subject
  subject(:invalid_request_obj) { described_class.new({}) }
  # Valid request subject
  subject(:request_obj) { described_class.new(header) }

  # Test Suite for AuthorizeApiRequest#call
  # This is our entry point into the service class
  describe '#call' do
    # returns user object when request is valid
    context 'when valid request' do
      it 'returns user object' do
        result = request_obj.call
       # byebug
        expect(result.result).to eq(user)
      end
    end

    # returns error message when invalid request
    context 'when invalid request' do
      context 'when missing token' do
        it 'a MissingToken error' do
          res = invalid_request_obj.call
          expect(res.errors[:token][0]).to eq("Missing token")
        end
      end

      context 'when invalid token' do
        subject(:invalid_request_obj) do
          # custom helper method `token_generator`
          described_class.new('Authorization' => token_generator(5))
        end

        it 'return an InvalidToken error' do
          #inv_res = invalid_request_obj.call
          expect{invalid_request_obj.call}.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'when token is expired' do
        let(:header) { { 'Authorization' => expired_token_generator(user.id) } }
        subject(:request_obj) { described_class.new(header) }

        it 'return ExceptionHandler::ExpiredSignature error' do
          sig_res = request_obj.call
          expect(sig_res.errors[:token][0]).to eq("Invalid token")
        end
      end

      context 'fake token' do
        let(:header) { { 'Authorization' => 'foobar' } }
        subject(:invalid_request_obj) { described_class.new(header) }

        it 'handles JWT::DecodeError' do
          jwt_res = invalid_request_obj.call
          expect(jwt_res.errors[:token][0]).to eq("Invalid token")
             # .to raise_error(
             #         ExceptionHandler::InvalidToken,
              #        /Not enough or too many segments/
              #    )
        end
      end
    end
  end
end
