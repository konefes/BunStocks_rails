desc 'Updates BunStocks Firebase stock data with closing prices once a day'

namespace :bunstocks do

task :update_bunstocks => :environment do
    Stock.update_bunstocks
end

task :fill_db => :environment do
    Stock.fill_db
end

task :check_db => :environment do
    Stock.check_db
end

task :check_price => :environment do
    Stock.check_price
end

task :whenever_test => :environment do
    Stock.whenever_test
end

end