require 'spec_helper'

describe Backup::Repository do
  let(:progress) { StringIO.new }
  let!(:project) { create(:project) }

  before do
    allow(progress).to receive(:puts)
    allow(progress).to receive(:print)

    allow_any_instance_of(String).to receive(:color) do |string, _color|
      string
    end

    allow_any_instance_of(described_class).to receive(:progress).and_return(progress)
  end

  describe '#dump' do
    describe 'repo failure' do
      before do
        allow(Gitlab::Popen).to receive(:popen).and_return(['normal output', 0])
      end

      it 'does not raise error' do
        expect { described_class.new.dump }.not_to raise_error
      end
    end
  end

  describe '#restore' do
    describe 'command failure' do
      before do
        allow(Gitlab::Popen).to receive(:popen).and_return(['error', 1])
      end

      it 'shows the appropriate error' do
        described_class.new.restore

        expect(progress).to have_received(:puts).with("Ignoring error on #{project.full_path} - error")
      end
    end
  end

  describe '#empty_repo?' do
    context 'for a wiki' do
      let(:wiki) { create(:project_wiki) }

      it 'invalidates the emptiness cache' do
        expect(wiki.repository).to receive(:expire_emptiness_caches).once

        wiki.empty?
      end

      context 'wiki repo has content' do
        let!(:wiki_page) { create(:wiki_page, wiki: wiki) }

        it 'returns true, regardless of bad cache value' do
          expect(described_class.new.send(:empty_repo?, wiki)).to be(false)
        end
      end

      context 'wiki repo does not have content' do
        it 'returns true, regardless of bad cache value' do
          expect(described_class.new.send(:empty_repo?, wiki)).to be_truthy
        end
      end
    end
  end
end
