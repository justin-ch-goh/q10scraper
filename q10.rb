require 'nokogiri'
require 'open-uri'
require 'csv'


# Fetch and parse HTML document
doc = Nokogiri::HTML(open("http://list.qoo10.sg/gmkt.inc/Bestsellers/"))
# path = doc.css("li#441633906 a")[0]['href']
# section = doc.css("div.section_ctlst li")[0]
# puts section
# path = doc.css("li").key?('goodscode')[0]['href']

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

doc.css("div.section_ctlst li").each do |link|

  item_url = link.css("a.thumb")[0]['href']

  paths << item_url
  thumbnailImg << link.css("a.thumb img")[0]['gd_src'] # link.css("a.thumb img")[0]['src'] didn't work due to spinner
  title << link.css("p.subject a")[0]['title']
  price << link.css("p.price strong")[0].text
  sellerShop << link.css("p.name a")[0].text
  shipping << link.css("div.shipping p").text
  discountEm << link.css("p.discount em").text
  discountSpan << link.css("p.discount span").text
  discountDel << link.css("p.discount del").text

  # extract reviews from each page
  item_page = Nokogiri::HTML(open("#{item_url}"))
  review = item_page.css("ul.pht_review dd.detail a").text
  puts review
  reviews << review
  
end

CSV.open("q10bestsellers.csv", "w") do |csv|
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