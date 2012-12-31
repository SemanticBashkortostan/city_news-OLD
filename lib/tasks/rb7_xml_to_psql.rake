require 'nokogiri'

namespace :rb7_data do


  def fetch_data_from_xml( path="#{Rails.root}/tmp/grouped_news.xml")
    xmlfeed = Nokogiri::XML(open(path))
    rows = xmlfeed.xpath("//row")
    rows.each do |row|
      nid = row.xpath('field[@name="nid"]').children.text
      title = row.xpath('field[@name="title"]').children.text
      annotation = row.xpath('field[@name="annotation"]').children.text
      text = row.xpath('field[@name="text"]').children.text
      source = row.xpath('field[@name="source"]').children.text
      created = row.xpath('field[@name="created"]').children.text
      changed = row.xpath('field[@name="changed"]').children.text
      tid = row.xpath('field[@name="tid"]').children.text
      ints = [nid, created, changed, tid]

      begin
        sql = "INSERT INTO rb7_news (nid, created, changed, tid, title, annotation, text, source) VALUES
               (#{ints.join(", ")}, '#{title}', '#{annotation}', '#{text}', '#{source}')"
        ActiveRecord::Base.connection.execute sql

        puts "Successfully inserted into rb7_news #{nid}"
      rescue Exception => e
        puts "Error with inserting #{nid} #{e}"
      end
    end

  end


  desc 'Migrate news data from rb7 xml'
  task :migrate_news => :environment do
    fetch_data_from_xml
  end
end
