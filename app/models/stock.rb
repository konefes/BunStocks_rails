class Stock < ActiveRecord::Base
    
    def self.update_bunstocks
        require 'open-uri'
        require 'json'
        
        # Load all NASDAQ tickers from DB
        tickers = Array.new
        Stock.all.each do |stock|
            tickers.push(stock.ticker)    
        end
        
        # Query-building variables
        queryStart = 'https://query.yahooapis.com/v1/public/yql?q=select%20LastTradePriceOnly%20from%20yahoo.finance.quotes%20where%20symbol%20in%20(%22'
        querySeparator = '%22,%22'
        queryEnd = '%22)&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback='
        queryCount = 0
        query = ""
        priceArray = Array.new
        overallCount = 0
        
        # Iterate through stock symbols, query in batches of 50
        tickers.each do |stock|
            if queryCount == 0
                query += queryStart
            end
            query += stock
            if queryCount < 50 && stock != tickers.last
                query += querySeparator
                queryCount += 1
            else
                query += queryEnd
                # puts query
                # puts query.length
                # puts "********************************************************"
                response = open(query).read
                hash = JSON.parse response
                hash["query"]["results"]["quote"].each do |priceHash|
                    priceArray.push(priceHash["LastTradePriceOnly"].to_f)
                end
                query = ""
                queryCount = 0
                overallCount += 1
            end
        end
        
        puts overallCount.to_s
        
        # Update firebase to reflect yql queries
        firebase_uri = 'https://bunstocks-32cd8.firebaseio.com/'
        firebase = Firebase::Client.new(firebase_uri, Rails.application.secrets.firebase_key)
        
        tickerCount = 0
        tickers.each do |ticker|
            response = firebase.set("stocks/" + ticker + "/" + Date.today.to_s, {:price => priceArray[tickerCount].to_f})
            tickerCount += 1
        end
        
    end
    
    
    def self.fill_db
        puts "executing fill_db"
        File.open(Rails.root.to_s + "/app/models/nasdaqlisted.txt", "r").each_line do |line|
           Stock.create(ticker: line.partition("|").first)
        end
    end
    
    
    def self.check_db
        Stock.all.each do |entry|
            puts entry.ticker
        end
    end
    
    def self.check_price 
        queryStart = 'https://query.yahooapis.com/v1/public/yql?q=select%20LastTradePriceOnly%20from%20yahoo.finance.quotes%20where%20symbol%20in%20(%22'
        querySeparator = '%22,%22'
        queryEnd = '%22)&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback=' 
        
        response = open(queryStart + "AAPL" + queryEnd).read
        puts response
    end
    
    def self.whenever_test
        firebase_uri = 'https://bunstocks-32cd8.firebaseio.com/'
        firebase = Firebase::Client.new(firebase_uri, Rails.application.secrets.firebase_key)
        response = firebase.set("test", {:time => Time.now.to_s})
    end
    
end
