# frozen_string_literal: true

require 'rails_helper'

describe ApplicationHelper, type: :helper do
  describe '#collection_title' do
    it 'unmangles the collection title from the compound field' do
      expect(helper.collection_title('foo-|-bar')).to eq 'bar'
    end
  end

  describe '#collection_title_for_index_field' do
    it 'unmangles the collection title from the compound field' do
      expect(helper.document_collection_title(value: 'foo-|-bar')).to eq 'bar'
    end

    it 'handles multivalued fields' do
      expect(helper.document_collection_title(value: ['foo-|-bar', 'baz-|-bop'])).to eq 'bar and bop'
    end
  end

  describe '#notes_wrap' do
    let(:output) { '<ul class="general-notes"><li>a</li><li><p>b</p><p>c</p></li><li>d</li></ul>' }

    it 'permits embedded HTML and handles multivalued notes as an unordered list' do
      expect(helper.notes_wrap(value: %w(a <p>b</p><p>c</p> d))).to eq output
    end
    context 'single note' do
      it 'returns the note' do
        expect(helper.notes_wrap(value: %w(<p>stuff</p>))).to eq '<p>stuff</p>'
      end
    end
  end

  describe '#table_of_contents_separator' do
    context 'single value' do
      let(:input) { { document: SolrDocument.new(id: 'cf386wt1778'), value: ['Homiliae'] } }

      it 'presents content inline' do
        expect(helper.table_of_contents_separator(input)).to eq 'Homiliae'
        expect(helper.table_of_contents_separator(input)).not_to match(/data-toggle='collapse'/)
      end
    end

    context 'multi-valued' do
      let(:input) { { document: SolrDocument.new(id: 'cf386wt1778'), value: ['Homiliae--euangelia'] } }

      it 'separates MODS table of contents' do
        expect(helper.table_of_contents_separator(input)).to match(%r{<li>Homiliae</li><li>euangelia</li>})
      end

      it 'collapses content' do
        expect(helper.table_of_contents_separator(input)).to match(/data-toggle='collapse'/)
      end
    end
  end

  describe '#manuscript_link' do
    let(:input) { { value: ['bg021sq9590'], document: document } }

    before do
      helper.extend(Module.new do
        def current_exhibit
          FactoryBot.create(:exhibit, slug: 'test-flag-exhibit-slug')
        end
      end)
    end

    context 'page details' do
      let(:title) { 'Baldwin of Ford OCist, De sacramento altaris' }
      let(:show_page) { '/test-flag-exhibit-slug/catalog/bg021sq9590' }
      let(:document) do
        SolrDocument.new(
          title_full_display: "p. 3:#{title}",
          manuscript_number_tesim: ['MS 198'],
          format_main_ssim: ['Page details']
        )
      end

      it 'removes page prefix if present' do
        expect(helper.manuscript_link(input)).to have_link(text: title, href: show_page)
      end
    end

    context 'bibilography resource' do
      let(:document) do
        SolrDocument.new(
          title_full_display: 'A Zotero reference',
          format_main_ssim: ['Bibliography']
        )
      end

      it 'displays druid for Bibliography resources' do
        expect(helper.manuscript_link(input)).to eq 'bg021sq9590'
      end
    end
  end
end
