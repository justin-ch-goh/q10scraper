require 'nokogiri'
require 'open-uri'
require 'csv'
require 'typhoeus'

############################################################################
# Scrape products from subcategories provided by q10categories.rb
# and outputs the data to a csv file named q10subCategoryScraper#{title}.csv
#
# Configuration options
# => baseUrl (subcategory URL)
# => pagesPerCsvFile (number of q10 pages/to limit csv file size)
# => startingPage (if you want to start from other pages)
# => endPage (default = totalPages) 
# => max_concurrency (optimum is around 8-16 before diminishing returns)
#
############################################################################

# Define subcategory base url
baseUrl = "http://list.qoo10.sg/gmkt.inc/Category/?gdlc_cd=100000031"

# Define a starting page number
startingPage = 1

# array of data to pipe to csv
paths = []        # URL to product page
thumbnailImg = [] # jpeg, since webp has a spinner placeholder
title = []        # Title blurb
price = []        # Price (after reductions)
sellerShop = []   # <a href="" title="power-seller"> 
shipping = []     # cost / free shipping
discountEm = []   # original
discountSpan = [] # reduction
discountDel = []  # strikethrough
reviews = []      # go into the product's URL, extract the first review

# Write CSV for every x number of pages
pagesPerCsvFile = 3

# Get page metadata (subcategory/total number of pages)
doc = Nokogiri::HTML(open("#{baseUrl}"+"&curPage=1"))

# Get subcategory name for naming of CSV files later
subCategory = doc.css("dfn.major").text

# Total number of pages for this subcategory
totalPages = doc.css("div#quickPaging em").text.gsub(/\D/, '').to_i

# endPage = totalPages
endPage = 8

if endPage < startingPage
  raise 'endPage must be larger than startingPage'
end

# Loop to extract from multiple pages for each subcategory
(startingPage..endPage).each do |i|

  doc = Nokogiri::HTML(open("#{baseUrl}"+"&curPage=#{i}"))

  pathsForLoop = []

  # Extract product data for csv
  doc.css("div.bd_glr4 li").each do |link|

    item_url = link.css("a.thumb")[0]['href']

    paths << item_url
    pathsForLoop << item_url
    thumbnailImg << link.css("a.thumb img")[0]['gd_src']
    title << link.css("p.subject a")[0]['title']
    price << link.css("div.price strong")[0].text
    sellerShop << link.css("p.name a")[0].text
    shipping << link.css("div.shipping span").text
    discountEm << link.css("p.discount em").text
    discountSpan << link.css("p.discount span").text
    discountDel << link.css("div.price del").text

    # requests in series
    # item_page = Nokogiri::HTML(open("#{item_url}"))
    # review = item_page.css("ul.pht_review dd.detail a").text
    # puts review
    # reviews << review
    
  end

  # using Typhoeus to run multiple requests in parallel to de-bottleneck Nokogiri
  hydra = Typhoeus::Hydra.new(max_concurrency: 16)

  # need to map the i th set of paths, not ALL the paths
  requests = pathsForLoop.map { |path| Typhoeus::Request.new("#{path}") }
  requests.each { |request| hydra.queue(request) }
  hydra.run
  # get all "photo reviews"
  requests.each { |request| 
    review = Nokogiri::HTML(request.response.body).css("ul.pht_review dd.detail a").text
    reviews << review }

  csvFileNumber = i / pagesPerCsvFile

  # Write to CSV only once per x pages
  # Need || condition to ensure last csv file is written
  if (i % pagesPerCsvFile == 0) || (i == endPage)
    if (i == endPage)
      csvFileNumber += 1
    end
    CSV.open("q10subCategoryScraper#{subCategory}#{csvFileNumber}.csv", "w") do |csv|
      puts "Writing to csv..."
      csv << paths
      csv << thumbnailImg
      csv << title
      csv << price
      csv << sellerShop
      csv << shipping
      csv << discountEm
      csv << discountSpan
      csv << discountDel
      csv << reviews
      puts "Success writing to csv..."
    end
    # reset globals for next csv
    paths = []      
    thumbnailImg = [] 
    title = []     
    price = []     
    sellerShop = []  
    shipping = []    
    discountEm = [] 
    discountSpan = []
    discountDel = []  
    reviews = []      
  end

end