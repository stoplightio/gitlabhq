require 'spec_helper'

describe Identity do
  describe 'relations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'fields' do
    it { is_expected.to respond_to(:provider) }
    it { is_expected.to respond_to(:extern_uid) }
  end

  describe '#is_ldap?' do
    let(:ldap_identity) { create(:identity, provider: 'ldapmain') }
    let(:other_identity) { create(:identity, provider: 'twitter') }

    it 'returns true if it is a ldap identity' do
      expect(ldap_identity.ldap?).to be_truthy
    end

    it 'returns false if it is not a ldap identity' do
      expect(other_identity.ldap?).to be_falsey
    end
  end

  describe '.with_extern_uid' do
    context 'LDAP identity' do
      let!(:ldap_identity) { create(:identity, provider: 'ldapmain', extern_uid: 'uid=john smith,ou=people,dc=example,dc=com') }

      it 'finds the identity when the DN is formatted differently' do
        identity = described_class.with_extern_uid('ldapmain', 'uid=John Smith, ou=People, dc=example, dc=com').first

        expect(identity).to eq(ldap_identity)
      end
    end

    context 'any other provider' do
      let!(:test_entity) { create(:identity, provider: 'test_provider', extern_uid: 'test_uid') }

      it 'the extern_uid lookup is case insensitive' do
        identity = described_class.with_extern_uid('test_provider', 'TEST_UID').first

        expect(identity).to eq(test_entity)
      end
    end
  end
end
