require 'nokogiri'
require 'open-uri'
require 'csv'
require 'typhoeus'

doc = Nokogiri::HTML(open("http://list.qoo10.sg/gmkt.inc/Category/Default.aspx"))

paths = []

doc.css('li[class^="cate"]').each do |link|

  link.css("dt a").each do |subCategory|

    subCategoryUrl = subCategory['href']
    puts subCategory.text + " | " + subCategoryUrl
    paths << subCategoryUrl

  end

end

# puts paths