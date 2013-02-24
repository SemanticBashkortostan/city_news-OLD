#coding: utf-8

class CreateFeedSources < ActiveRecord::Migration
  def up
    create_table :feed_sources do |t|
      t.integer :text_class_id
      t.string :url

      t.timestamps
    end
    add_index :feed_sources, :text_class_id


    sources = { TextClass.find_by_name("Ишимбай").id => ["http://ishimbay-news.ru/rss.xml", "http://ishimbai.procrb.ru/rss/?rss=y",
                          "http://vestivmeste.ru/index.php/v-dvuh-slovah?format=feed&type=rss",
                          "http://восход-ишимбай.рф/index.php?option=com_content&view=category&id=8&Itemid=598&format=feed&type=rss",
                          "http://восход-ишимбай.рф/index.php?option=com_content&view=category&id=10&Itemid=600&format=feed&type=rss",
                          "http://восход-ишимбай.рф/index.php?option=com_content&view=category&id=26&Itemid=601&format=feed&type=rss",
                          "http://восход-ишимбай.рф/index.php?option=com_content&view=category&id=12&Itemid=602&format=feed&type=rss"
                          ],
             TextClass.find_by_name("Салават").id => ["http://slvnews.ru/rss", "http://rssportal.ru/feed/163654.xml", "http://rosevronews.ru/feed/" ],
             TextClass.find_by_name("Уфа").id => ["http://rssportal.ru/feed/129727.xml", "http://news.yandex.ru/Ufa/index.rss"],
             TextClass.find_by_name("Стерлитамак").id => ["http://rssportal.ru/feed/223350.xml", "http://sterlegrad.ru/rss.xml", "http://cityopen.ru/?feed=rss2"],
             TextClass.find_by_name("Нефтекамск").id => ["http://neftekamsk.procrb.ru/rss/?rss=y", "http://rssportal.ru/feed/240378.xml",
                             "http://feeds.feedburner.com/delogazeta/UGfI?format=xml"],
             nil => ["http://feeds.feedburner.com/bashinform/all?format=xml"] }
    sources.each do |tc_id, urls|
      urls.each do |url|
        FeedSource.create! :text_class_id => tc_id, :url => url
      end
    end 

  end


  def down
    drop_table :feed_sources
  end
end
