class HomeController < ApplicationController
  def index
    render 'index'
  end

  def find
    start = Time.now
    current_time = start.to_i
    spammers = {}
    @spammer_hash = {}
    counter = 0
    @item_count = 0

    loop do
      begin
        query = "SELECT actor_id, created_time, post_id, attachment, permalink FROM stream WHERE filter_key IN (SELECT filter_key FROM stream_filter WHERE uid = me() AND name = 'Links') AND created_time < #{current_time} ORDER BY created_time DESC LIMIT 500"
        feed = current_user.facebook.fql_query(query)
        feed.each do |item|
          begin
            # the top-secret algorithm
            regex = /upworthy.com|u.pw|buzzfeed.com|gawker.com|distractify.com|huffingtonpost.com|mashable.com|youtube.com|cheezburger.com/i
            if item['attachment']['href'].match(regex)
              spammers[item['actor_id']].present? ? spammers[item['actor_id']] += 1 : spammers[item['actor_id']] = 1
            end
          rescue
            # just in case there's some weird data, ignore it
          end
        end
        puts feed.count
        @item_count += feed.count
        current_time = feed.last['created_time'] if feed.count > 0
      rescue Koala::Facebook::APIError => e
        # ignore error for now, it'll try again until counter gets to 5
      end
      counter += 1
      break if counter == 5 || feed.count.zero? || (Time.now - start) > 20 # if taking more than 20 seconds, deal with what we have
    end

    top_five = spammers.sort_by{|k,v| v}.reverse[0..4]
    top_five_str = top_five.map {|i| i[0]}.join(',')

    # get spammer info from fb
    spammer_arr = current_user.facebook.batch do |batch_api|
      top_five.each do |spammer|
        batch_api.get_object(spammer[0])
      end
    end

    # get pictures for spammers
    pics_arr = current_user.facebook.fql_query("SELECT id, pic_square FROM profile WHERE id IN (#{top_five_str})")

    spammer_arr.each do |spammer|
      @spammer_hash[spammer['id']] = spammer
      @spammer_hash[spammer['id']]['spam_count'] = spammers[spammer['id'].to_i]
    end

    pics_arr.each do |pic|
      @spammer_hash[pic['id'].to_s]['pic'] = pic['pic_square']
      puts pic['pic_square']
    end

    render 'find'
  end
end