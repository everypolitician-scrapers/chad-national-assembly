#!/bin/env ruby
# encoding: utf-8

require 'nokogiri'
require 'open-uri'
require 'csv'
require 'scraperwiki'
require 'pry'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def noko_for(url)
  Nokogiri::HTML(open(url).read) 
end

def scrape_list(url)
  noko = noko_for(url)
  noko.css('#actu_left a[href*="spip.php?article"]/@href').map(&:text).each do |href|
    scrape_mp(URI.join url, href)
  end
end

def scrape_mp(url)
  noko = noko_for(url)
  box = noko.css('#actu_left')

  party_info = box.xpath('.//span[contains(.,"politique")]/following-sibling::a[1]').text
  if matched = party_info.match(/(.*?)\s+\((.*?)\)/)
    party_id, party = matched.captures 
  elsif party_info.to_s.empty?
    party_id, party = ["unknown", "unknown"]
  else
    party = party_info
    party_info = nil
  end

  data = { 
    id: url.to_s[/article(\d+)/, 1],
    name: box.css('h1').text.strip,
    party: party,
    party_id: party_id,
    area: box.xpath('.//span[contains(.,"Localisation")]/following-sibling::a[1]').text.strip,
    image: box.css('img.spip_logos/@src').text,
    term: 3,
  }
  data[:image] = URI.join(url, data[:image]).to_s unless data[:image].to_s.empty?
  # puts data
  ScraperWiki.save_sqlite([:name, :term], data)
end

term = {
  id: 3,
  name: 'Troisième Législature',
  start_date: '2011',
}
ScraperWiki.save_sqlite([:id], term, 'terms')


scrape_list('http://www.assemblee-tchad.org/spip.php?rubrique49')
