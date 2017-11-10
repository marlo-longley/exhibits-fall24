# frozen_string_literal: true

require_relative 'macros/general'
require_relative 'macros/dor'

require 'active_support/core_ext/object/blank'
extend Macros::General
extend Macros::Dor

settings do
  provide 'reader_class_name', 'DorReader'
  provide 'processing_thread_pool', ::Settings.traject.processing_thread_pool || 1
end

to_fields %w(id druid), accumulate { |resource, *_| resource.bare_druid }
to_field 'modsxml', accumulate { |resource, *_| resource.smods_rec.to_xml }

# ITEM FIELDS
to_field 'display_type' do |resource, accumulator, _context|
  next if resource.collection?
  accumulator << display_type(dor_content_type(resource)) # defined in public_xml_fields
end
to_field 'file_id' do |resource, accumulator, _context|
  next if resource.collection?
  Array(file_ids(resource)).each do |v|
    accumulator << v
  end
end
to_field 'collection', accumulate { |resource, *_| resource.collections.map(&:bare_druid) }
to_field 'collection_with_title', accumulate { |resource, *_|
  resource.collections.map { |collection| "#{collection.bare_druid}-|-#{coll_title(collection)}" }
}

# COLLECTION FIELDS
# solr_doc[:display_type] =
to_field 'format_main_ssim', conditional(->(resource, *_) { resource.collection? }, literal('Collection'))
to_field 'collection_type', conditional(->(resource, *_) { resource.collection? }, literal('Digital Collection'))

# OTHER FIELDS
to_field 'url_fulltext', accumulate { |resource, *_| "https://purl.stanford.edu/#{resource.bare_druid}" }
to_field 'access_facet', literal('Online')
to_field 'building_facet', literal('Stanford Digital Repository')

# title fields
to_field 'title_245a_search', stanford_mods(:sw_short_title)
to_field 'title_245_search', stanford_mods(:sw_full_title)
to_field 'title_variant_search', stanford_mods(:sw_addl_titles) do |_record, accumulator|
  accumulator.reject!(&:blank?)
end
to_field 'title_sort', stanford_mods(:sw_sort_title)
to_field 'title_245a_display', stanford_mods(:sw_short_title)
to_field 'title_display', stanford_mods(:sw_title_display)
to_field 'title_full_display', stanford_mods(:sw_full_title)

# author fields
to_field 'author_1xx_search', stanford_mods(:sw_main_author)
to_field 'author_7xx_search', stanford_mods(:sw_addl_authors)
to_field 'author_person_facet', stanford_mods(:sw_person_authors)
to_field 'author_other_facet', stanford_mods(:sw_impersonal_authors)
to_field 'author_sort', stanford_mods(:sw_sort_author) do |_record, accumulator|
  accumulator.map! { |v| v.tr("\uFFFF", "\uFFFD") }
end

to_field 'author_corp_display', stanford_mods(:sw_corporate_authors)
to_field 'author_meeting_display', stanford_mods(:sw_meeting_authors)
to_field 'author_person_display', stanford_mods(:sw_person_authors)
to_field 'author_person_full_display', stanford_mods(:sw_person_authors)

# subject search fields
to_field 'topic_search', stanford_mods(:topic_search)
to_field 'geographic_search', stanford_mods(:geographic_search)
to_field 'subject_other_search', stanford_mods(:subject_other_search)
to_field 'subject_other_subvy_search', stanford_mods(:subject_other_subvy_search)
to_field 'subject_all_search', stanford_mods(:subject_all_search)
to_field 'topic_facet', stanford_mods(:topic_facet)
to_field 'geographic_facet', stanford_mods(:geographic_facet)
to_field 'era_facet', stanford_mods(:era_facet)

to_field 'format_main_ssim', conditional(->(resource, *_) { !resource.collection? }, stanford_mods(:format_main))

to_field 'language', stanford_mods(:sw_language_facet)
to_field 'physical', stanford_mods(:term_values, [:physical_description, :extent])
to_field 'summary_search', stanford_mods(:term_values, :abstract)
to_field 'toc_search', stanford_mods(:term_values, :tableOfContents)
to_field 'url_suppl', stanford_mods(:term_values, [:related_item, :location, :url])

# publication fields
to_field 'pub_search', stanford_mods(:place)
to_field 'pub_year_isi', stanford_mods(:pub_year_int, false) # for sorting
# TODO:  remove pub_date_sort after reindexing existing colls;  deprecated in favor of pub_year_isi ...
to_field 'pub_date_sort', stanford_mods(:pub_year_sort_str, false)
# these are for single value facet display (in leiu of date slider (pub_year_tisim) )
to_field 'pub_year_no_approx_isi', stanford_mods(:pub_year_int, true)
to_field 'pub_year_w_approx_isi', stanford_mods(:pub_year_int, false)
# display fields  TODO:  pub_date_display is deprecated;  need better implementation of imprint_display
to_field 'imprint_display', stanford_mods(:pub_date_display)

# pub_date_best_sort_str_value is protected ...
to_field 'creation_year_isi', accumulate { |resource, *_|
  resource.smods_rec.year_int(resource.smods_rec.date_created_elements(false))
}
to_field 'publication_year_isi', accumulate { |resource, *_|
  resource.smods_rec.year_int(resource.smods_rec.date_issued_elements(false))
}
to_field 'all_search', accumulate { |resource, *_| resource.smods_rec.text.gsub(/\s+/, ' ') }
to_field 'pub_year_tisim' do |_resource, accumulator, context|
  next unless context.output_hash['pub_year_isi'] && context.output_hash['pub_year_isi'].first >= 0
  accumulator << context.output_hash['pub_year_isi'].first if context.output_hash['pub_year_isi'].first >= 0
end

to_field 'author_no_collector_ssim', stanford_mods(:non_collector_person_authors)
to_field 'box_ssi', stanford_mods(:box)

# add coordinates solr field containing the cartographic coordinates per
# MODS subject.cartographics.coordinates (via stanford-mods gem)
to_field 'coordinates_tesim', stanford_mods(:coordinates)

# add collector_ssim solr field containing the collector per MODS names (via stanford-mods gem)
to_field 'collector_ssim', stanford_mods(:collectors_w_dates)
to_field 'folder_ssi', stanford_mods(:folder)
to_field 'genre_ssim' do |resource, accumulator, _context|
  Array(resource.smods_rec.genre.content).each { |v| accumulator << v }
end
to_field 'location_ssi', stanford_mods(:physical_location_str)
to_field 'series_ssi', stanford_mods(:series)
to_field 'identifier_ssim' do |resource, accumulator, _context|
  Array(resource.smods_rec.identifier.content).each { |v| accumulator << v }
end

to_field 'geographic_srpt' do |resource, accumulator, _context|
  ids = extract_geonames_ids(resource)
  ids.each do |id|
    value = get_geonames_api_envelope(id)
    accumulator << value if value
  end
end

to_field 'geographic_srpt', stanford_mods(:coordinates_as_envelope)
to_field 'geographic_srpt', stanford_mods(:geo_extensions_as_envelope)
to_field 'geographic_srpt', stanford_mods(:geo_extensions_point_data)

to_field 'iiif_manifest_url_ssi' do |resource, accumulator, _context|
  accumulator << iiif_manifest_url(resource.bare_druid)
end

# CONTENT METADATA

to_field 'content_metadata_type_ssim' do |resource, accumulator, _context|
  content_metadata = resource.public_xml.at_xpath('/publicObject/contentMetadata')

  accumulator << content_metadata['type'] if content_metadata.present?
end

to_field 'content_metadata_type_ssm', copy('content_metadata_type_ssim')

each_record do |resource, context|
  content_metadata = resource.public_xml.at_xpath('/publicObject/contentMetadata')
  next unless content_metadata.present?
  images = content_metadata.xpath('resource/file[@mimetype="image/jp2"]')
  thumbnail_data = images.first { |node| node.attr('id') =~ /jp2$/ }
  context.clipboard['thumbnail_data'] = thumbnail_data
end

to_field 'content_metadata_first_image_file_name_ssm' do |_resource, accumulator, context|
  next unless context.clipboard['thumbnail_data']

  file_id = context.clipboard['thumbnail_data'].attr('id').gsub('.jp2', '')
  accumulator << file_id
end

to_field 'content_metadata_first_image_width_ssm' do |_resource, accumulator, context|
  next unless context.clipboard['thumbnail_data']
  image_data = context.clipboard['thumbnail_data'].at_xpath('./imageData')

  accumulator << image_data['width']
end

to_field 'content_metadata_first_image_height_ssm' do |_resource, accumulator, context|
  next unless context.clipboard['thumbnail_data']
  image_data = context.clipboard['thumbnail_data'].at_xpath('./imageData')

  accumulator << image_data['height']
end

to_field 'content_metadata_image_iiif_info_ssm', resource_images_iiif_urls do |_resource, accumulator, _context|
  accumulator.map! { |base_url| "#{base_url}/info.json" }
end

to_field 'thumbnail_square_url_ssm', resource_images_iiif_urls do |_resource, accumulator, _context|
  accumulator.map! { |base_url| "#{base_url}/square/100,100/0/default.jpg" }
end

to_field 'thumbnail_url_ssm', resource_images_iiif_urls do |_resource, accumulator, _context|
  accumulator.map! { |base_url| "#{base_url}/full/!400,400/0/default.jpg" }
end

to_field 'large_image_url_ssm', resource_images_iiif_urls do |_resource, accumulator, _context|
  accumulator.map! { |base_url| "#{base_url}/full/!1000,1000/0/default.jpg" }
end

to_field 'full_image_url_ssm', resource_images_iiif_urls do |_resource, accumulator, _context|
  accumulator.map! { |base_url| "#{base_url}/full/!3000,3000/0/default.jpg" }
end

# FEIGENBAUM FIELDS

to_field 'doc_subtype_ssi' do |resource, accumulator, _context|
  subtype = resource.smods_rec.note.select { |n| n.displayLabel == 'Document subtype' }.map(&:content)
  accumulator << subtype.first unless subtype.empty?
end

to_field 'donor_tags_ssim' do |resource, accumulator, _context|
  donor_tags = resource.smods_rec.note.select { |n| n.displayLabel == 'Donor tags' }.map(&:content)
  Array(donor_tags).each do |v|
    accumulator << v.sub(/^./, &:upcase)
  end
end

to_field 'folder_name_ssi' do |resource, accumulator, _context|
  preferred_citation = resource.smods_rec.note.select { |n| n.type_at == 'preferred citation' }.map(&:content)
  match_data = preferred_citation.first.match(/Title: +(.+)/i) if preferred_citation.present?
  accumulator << match_data[1].strip if match_data.present?
end

to_field 'general_notes_ssim' do |resource, accumulator, _context|
  general_notes = resource.smods_rec.note.select { |n| n.type_at.blank? && n.displayLabel.blank? }.map(&:content)
  Array(general_notes).each do |v|
    accumulator << v
  end
end

# FULL TEXT FIELDS
to_field 'full_text_tesimv' do |resource, accumulator, _context|
  Array(object_level_full_text_urls(resource)).each do |file_url|
    accumulator << get_file_content(file_url)
  end
end

# PARKER FIELDS

to_field 'manuscript_number_tesim' do |resource, accumulator, _context|
  Array(resource.smods_rec.location.shelfLocator.try(:text)).each do |v|
    accumulator << v.presence
  end
end

# We need to join the `displayLabel` and titles for all *alternative* titles
# `title_variant_display` has different behavior
to_field 'manuscript_titles_tesim' do |resource, accumulator, _context|
  Array(parse_manuscript_titles(resource)).each do |v|
    accumulator << v
  end
end

to_field 'text_titles_tesim' do |resource, accumulator, _context|
  Array(resource.smods_rec.tableOfContents.try(:content)).each do |v|
    accumulator << v
  end
end

to_field 'incipit_tesim' do |resource, accumulator, _context|
  Array(parse_incipit(resource)).each do |v|
    accumulator << v
  end
end

# parse titleInfo[type="alternative"]/title into tuples of (displayLabel, title)
def parse_manuscript_titles(sdb)
  manuscript_titles = []
  sdb.smods_rec.title_info.each do |title_info|
    next unless title_info.attr('type') == 'alternative'
    display_label = title_info.attr('displayLabel')
    title_info.at_xpath('*[local-name()="title"]').tap do |title|
      label_with_title = [display_label, title.content].map(&:to_s).map(&:strip)
      manuscript_titles << label_with_title.join('-|-')
    end
  end
  manuscript_titles
end

def parse_incipit(sdb)
  sdb.smods_rec.related_item.each do |item|
    item.note.each do |note|
      return note.text.strip if note.attr('type') == 'incipit'
    end
  end
  nil
end

def iiif_manifest_url(bare_druid)
  format ::Settings.purl.iiif_manifest_url, druid: bare_druid
end

# @return [Array{String}] The IDs from geonames //subject/geographic URIs, if any
def extract_geonames_ids(sdb)
  sdb.smods_rec.subject.map do |z|
    next unless z.geographic.any?
    uri = z.geographic.attr('valueURI')
    next if uri.nil?

    m = %r{^https?://sws\.geonames\.org/(\d+)}i.match(uri.value)
    m ? m[1] : nil
  end.compact.reject(&:empty?)
end

# rubocop:disable Metrics/AbcSize
# Fetch remote geonames metadata and format it for Solr
# @param [String] id geonames identifier
# @return [String] Solr WKT/CQL ENVELOPE based on //geoname/bbox
def get_geonames_api_envelope(id)
  url = "http://api.geonames.org/get?geonameId=#{id}&username=#{::Settings.geonames_username}"
  xml = Nokogiri::XML Faraday.get(url).body
  bbox = xml.at_xpath('//geoname/bbox')
  return if bbox.nil?
  min_x, max_x = [bbox.at_xpath('west').text.to_f, bbox.at_xpath('east').text.to_f].minmax
  min_y, max_y = [bbox.at_xpath('north').text.to_f, bbox.at_xpath('south').text.to_f].minmax
  "ENVELOPE(#{min_x},#{max_x},#{max_y},#{min_y})"
rescue Faraday::Error => e
  logger.error("Error fetching/parsing #{url} -- #{e.message}")
  nil
end
# rubocop:enable Metrics/AbcSize

# go grab the supplied file url, grab the file, encode and return
# TODO: this should also be able to deal with .rtf and .xml files, scrubbing/converting as necessary to get plain text
def get_file_content(file_url)
  response = Faraday.get(file_url)
  response.body.scrub.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').gsub(/\s+/, ' ')
rescue
  logger.error("Error indexing full text - couldn't load file #{file_url}")
  nil
end

# these are the file locations where full txt files can be found at the object level
# this method returns an array of fully qualified public URLs that can be accessed to find full text countent
def object_level_full_text_urls(sdb)
  files = []
  object_level_full_text_filenames(sdb).each do |xpath_location|
    files += sdb.public_xml.xpath(xpath_location).map do |txt_file|
      "#{::Settings.stacks.file_url}/#{sdb.bare_druid}/#{txt_file['id']}"
    end
  end
  files
end

# xpaths to locations in the contentMetadata where full text object level files can be found,
#  add as many as you need, all will be searched
def object_level_full_text_filenames(sdb)
  [
    # feigenbaum style - full text in .txt named for druid
    "//contentMetadata/resource/file[@id=\"#{sdb.bare_druid}.txt\"]"
  ]
end

# rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
def file_ids(resource)
  ids = []
  if resource.content_metadata
    if display_type(dor_content_type(resource)) == 'image'
      resource.content_metadata.root.xpath('resource[@type="image"]/file/@id').each do |node|
        ids << node.text unless node.text.empty?
      end
    elsif display_type(dor_content_type(resource)) == 'file'
      resource.content_metadata.root.xpath('resource/file/@id').each do |node|
        ids << node.text unless node.text.empty?
      end
    end
  end
  return nil if ids.empty?
  ids
end
# rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

def display_type(dor_content_type)
  case dor_content_type
  when 'book'
    'book'
  when 'image', 'manuscript', 'map'
    'image'
  else
    'file'
  end
end

def dor_content_type(resource)
  resource.content_metadata ? resource.content_metadata.root.xpath('@type').text : nil
end

def coll_title(resource)
  @collection_titles ||= {}
  @collection_titles[resource.druid] ||= begin
    resource.identity_md_obj_label
  end
end