require 'json'
require_relative '../../as_arclight/indexer/lib/ead_helper'

# Builds digital_objects_ssm the same way Harvard's ArcLight traject config did
# from ArchivesSpace EAD exports, so Solr output is unchanged now that we map
# from the API instead.
#
# The EAD exporter (EADSerializer#serialize_digital_object) skips digital
# objects that are unpublished or suppressed and only exports published file
# versions:
#   * no published file versions -> one <dao>, href is the digital_object_id
#   * one published file version  -> one <dao>, href is its file_uri
#   * several                     -> a <daogrp> with one <daoloc> per file version
# The traject config took the label from the title attribute (the digital
# object title on <dao>, the file version caption on <daoloc>), and
# Arclight::DigitalObject falls back to the href when the label is blank.
module DigitalObjectsMapping

  def digital_objects(instances)
    instances.map {|i| i.dig('digital_object', '_resolved')}
             .compact
             .select {|d| d['publish'] == true && d['suppressed'] != true}
             .map {|d| digital_object_links(d)}
             .flatten
             .map(&:to_json)
  end

  def digital_object_links(digital_object)
    file_versions = digital_object.fetch('file_versions', []).select {|fv| fv['publish'] == true}
    title = EADHelper.strip_markup(digital_object['title'])

    links = if file_versions.empty?
              [digital_object_link(title, digital_object['digital_object_id'])]
            elsif file_versions.length == 1
              [digital_object_link(title, file_versions.first['file_uri'])]
            else
              file_versions.map {|fv| digital_object_link(EADHelper.strip_markup(fv['caption']), fv['file_uri'])}
            end

    links.compact
  end

  def digital_object_link(label, href)
    return if href.nil? || href.strip.empty?

    label = href if label.nil? || label.strip.empty?
    { label: label, href: href }
  end

end
