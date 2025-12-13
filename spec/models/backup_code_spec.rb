require 'rails_helper'

RSpec.describe BackupCode, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:code_digest) }
  end

  describe '.generate_codes_for_user' do
    let(:user) { User.create!(name: 'Test User', email: 'test@example.com', password: 'Password123!', password_confirmation: 'Password123!') }

    it 'generates 10 backup codes' do
      codes = BackupCode.generate_codes_for_user(user)
      expect(codes.length).to eq(10)
    end

    it 'generates unique codes' do
      codes = BackupCode.generate_codes_for_user(user)
      expect(codes.uniq.length).to eq(10)
    end

    it 'generates 8 character alphanumeric codes' do
      codes = BackupCode.generate_codes_for_user(user)
      codes.each do |code|
        expect(code.length).to eq(8)
        expect(code).to match(/^[A-Z0-9]+$/)
      end
    end

    it 'creates backup code records in database' do
      expect {
        BackupCode.generate_codes_for_user(user)
      }.to change { user.backup_codes.count }.by(10)
    end

    it 'stores hashed versions of codes' do
      codes = BackupCode.generate_codes_for_user(user)
      backup_code = user.backup_codes.first
      expect(backup_code.code_digest).not_to eq(codes.first)
      expect(backup_code.code_digest.length).to be > 8
    end

    it 'sets used to false by default' do
      BackupCode.generate_codes_for_user(user)
      user.backup_codes.each do |backup_code|
        expect(backup_code.used).to be false
      end
    end
  end

  describe '#verify' do
    let(:user) { User.create!(name: 'Test User', email: 'test@example.com', password: 'Password123!', password_confirmation: 'Password123!') }
    let!(:codes) { BackupCode.generate_codes_for_user(user) }
    let(:backup_code) { user.backup_codes.reload.first }
    let(:plain_code) { codes.first }

    context 'with unused backup code' do
      it 'verifies correct code' do
        expect(backup_code.verify(plain_code)).to be true
      end

      it 'rejects incorrect code' do
        expect(backup_code.verify('WRONGCOD')).to be false
      end
    end

    context 'with used backup code' do
      before { backup_code.mark_as_used! }

      it 'rejects code even if correct' do
        expect(backup_code.verify(plain_code)).to be false
      end
    end
  end

  describe '#mark_as_used!' do
    let(:user) { User.create!(name: 'Test User', email: 'test@example.com', password: 'Password123!', password_confirmation: 'Password123!') }
    let!(:codes) { BackupCode.generate_codes_for_user(user) }
    let(:backup_code) { user.backup_codes.reload.first }

    it 'sets used to true' do
      expect {
        backup_code.mark_as_used!
      }.to change { backup_code.used }.from(false).to(true)
    end

    it 'sets used_at timestamp' do
      expect {
        backup_code.mark_as_used!
      }.to change { backup_code.used_at }.from(nil)

      expect(backup_code.used_at).to be_within(1.second).of(Time.current)
    end
  end
end