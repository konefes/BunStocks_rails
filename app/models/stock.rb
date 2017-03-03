class Stock < ActiveRecord::Base
    
    # Update each stock with the day's closing price
    def self.update_bunstocks
        require 'open-uri'
        require 'json'
        
        # Load all NASDAQ tickers from DB
        tickers = Array.new
        Stock.all.each do |stock|
            tickers.push(stock.ticker)    
        end
        # tickers.push("AAPL")
        # tickers.push("MSFT")
        
        # Query-building variables
        queryStart = 'https://query.yahooapis.com/v1/public/yql?q=select%20PreviousClose%20from%20yahoo.finance.quotes%20where%20symbol%20in%20(%22'
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
                # puts response
                puts (Date.today - 1.day).to_s
                hash = JSON.parse response
                hash["query"]["results"]["quote"].each do |priceHash|
                    priceArray.push(priceHash["PreviousClose"].to_f)
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
        date = (Date.today - 1.day).to_s
        
        tickerCount = 0
        tickers.each do |ticker|
            response = firebase.set("stocks/" + ticker + "/" + date, {:price => priceArray[tickerCount].to_f})
            tickerCount += 1
        end
        
    end
    
    #############################################################################
    
    def self.historic_to_firebase
        # Writes historic values for the previous year to firebase as they are
        # retrieved with yql
       
        require 'open-uri'
        require 'json'
        
        # Update firebase to reflect yql queries
        firebase_uri = 'https://bunstocks-32cd8.firebaseio.com/'
        firebase = Firebase::Client.new(firebase_uri, Rails.application.secrets.firebase_key)
        
        # Load all NASDAQ tickers from DB
        tickers = Array.new
        Stock.all.each do |stock|
            # if stock.ticker >= "VONE" && stock.ticker <= "VOXX"
            if stock.ticker >= "IRDMB"
                tickers.push(stock.ticker)
            end
        end
        # tickers.push("AAPL")
        # tickers.push("MSFT")
        
        # Query-building variables
        # Examples: http://query.yahooapis.com/v1/public/yql?q=select * from yahoo.finance.historicaldata where symbol = "YHOO"
        #               and startDate = "2014-02-11" and endDate = "2014-02-18"&diagnostics=true&env=store://datatables.org/alltableswithkeys
        #           http://query.yahooapis.com/v1/public/yql?q=select%20Open%20from%20yahoo.finance.historicaldata%20where%20symbol%20=%20%22AAPL%22%20and%20startDate%20=%20%222015-01-1%22%20and%20endDate%20=%20%222015-01-2%22&format=xml&diagnostics=true&env=store://datatables.org/alltableswithkeys
        queryStart = 'https://query.yahooapis.com/v1/public/yql?q=select%20Date%2CClose%20from%20yahoo.finance.historicaldata%20where%20symbol%20in%20(%22'
        querySeparator = '%22,%22'
        queryMid1 = '%22)%20and%20startDate%20%3D%20%22'
        queryStartDate = '2017-02-02'
        queryMid2 = '%22%20and%20endDate%20%3D%20%22'
        queryEndDate = '2017-03-01'
        queryEnd = '%22&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback='
        queryCount = 0
        query = ""
        overallCount = 0
        
        # Iterate through stock symbols
        tickers.each do |stock|
            query += queryStart
            query += stock
            query += queryMid1
            query += queryStartDate
            query += queryMid2
            query += queryEndDate
            query += queryEnd
            puts query
            puts query.length
            puts "********************************************************"
            response = open(query).read
            # puts response
            hash = JSON.parse response
            # priceValues = Array.new
            if hash["query"]["count"] > 0
                hash["query"]["results"]["quote"].each do |queryResult|
                    firebase.set("stocks/" + stock + "/" + queryResult["Date"], {:price => queryResult["Close"].to_f}) 
                    #  priceValues.push([queryResult["Date"], queryResult["Close"].to_f])
                end
            end
            query = ""
            queryCount = 0
            overallCount += 1
            puts overallCount.to_s
        end
        
    end
    
    #############################################################################
    
    def self.fill_db
        puts "executing fill_db"
        File.open(Rails.root.to_s + "/app/models/nasdaqlisted.txt", "r").each_line do |line|
           Stock.create(ticker: line.partition("|").first)
        end
    end
    
    #############################################################################
    
    def self.check_db
        Stock.all.each do |entry|
            puts entry.ticker
        end
    end
    
    #############################################################################
    
    def self.check_price 
        queryStart = 'https://query.yahooapis.com/v1/public/yql?q=select%20LastTradePriceOnly%20from%20yahoo.finance.quotes%20where%20symbol%20in%20(%22'
        querySeparator = '%22,%22'
        queryEnd = '%22)&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback=' 
        
        response = open(queryStart + "AAPL" + queryEnd).read
        puts response
    end
    
    #############################################################################
    
    def self.whenever_test
        firebase_uri = 'https://bunstocks-32cd8.firebaseio.com/'
        firebase = Firebase::Client.new(firebase_uri, Rails.application.secrets.firebase_key)
        response = firebase.set("test", {:time => Time.now.to_s})
    end
    
end
