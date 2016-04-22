require 'nokogiri'
require 'open-uri'
require 'csv'
require 'typhoeus'

######################################################################
# Scrape list of subcategory urls
######################################################################

doc = Nokogiri::HTML(open("http://list.qoo10.sg/gmkt.inc/Category/Default.aspx"))

paths = []
subCategoryTitle = []

doc.css('li[class^="cate"]').each do |link|

  link.css("dt a").each do |subCategory|

    subCategoryUrl = subCategory['href']
    subCategoryTitle << subCategory.text
    paths << subCategoryUrl
    # puts subCategory.text + " | " + subCategoryUrl
  end

end

CSV.open("q10subCategoryUrls.csv", "w") do |csv|
  puts "Writing subcategories to csv..."
  csv << subCategoryTitle
  csv << paths
  puts "Success writing to csv..."
end

# puts paths