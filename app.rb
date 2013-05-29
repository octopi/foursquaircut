get '/' do
	erb :index
end

# AUTHENTICATION PROCESS
# see https://developer.foursquare.com/overview/auth for details
get '/redirect_uri' do
	code = params[:code] # code returned from foursquare

	# exchange code for access token
	response = HTTParty.get('https://foursquare.com/oauth2/access_token?client_id=ZZFVNTTUWTJQ0O5KJO3VS4R5H114RHOJSPM5MWIVPWWSTK12&client_secret=YOISDBOTYSUTOQPEMHXZD2AH0U5GG2L1EW1CMDIPPZJPIN2N&grant_type=authorization_code&redirect_uri=http://foursquaircut.herokuapp.com/redirect_uri&code=' + code)
    access_token = response['access_token']
    puts 'your access_token is ' + access_token

    # create new authenticated foursquare client
    fsq = Foursquare2::Client.new(:oauth_token => access_token)
    
    # variables used in loop
    limit = 250
    offset = 0
    finished = false
    checkin = nil

    # loop through venues until you find a salon
    while not finished
        # see https://developer.foursquare.com/docs/users/checkins
    	checkins = fsq.user_checkins(:limit => limit, :offset => offset)
    	items = checkins['items']
    	items.each do |c|
    		if c['venue'] == nil
    			finished = true
    		elsif '4bf58dd8d48988d110951735' == c['venue']['categories'][0]['id'] # categoryId matching
    			checkin = c
    			finished = true
    		end
    		if finished
				break
			end
    	end

        # paginate through API
        offset += 250
    	limit = [250, checkins['count'] - offset].min
        if limit < 0
            finished = true
        end
    end

    # determine what to display
    if checkin == nil
    	erb :result, :locals => { :needed => true, :last => 'NEVER', :venue => 'NOWHERE' }
    else
    	before = checkin['createdAt']
    	now = Time.now
    	needed = (now - before).to_i > (86400 * 90) # if it's been more than 90 days, recommend a cut
		erb :result, :locals => { :needed => needed, :last => Time.at(before), :venue => checkin['venue']['name'] }
    end
end

# USERLESS VENUE SEARCH
# find nearby salons or pharmacies, depending on whether or not a haircut is needed
# the call is done server-side as to not expose client id/secret, but client-side passes in lat/lon
get '/find_nearby' do
    # create a new userless client
    fsq = Foursquare2::Client.new(:client_id => 'ZZFVNTTUWTJQ0O5KJO3VS4R5H114RHOJSPM5MWIVPWWSTK12', :client_secret => 'YOISDBOTYSUTOQPEMHXZD2AH0U5GG2L1EW1CMDIPPZJPIN2N')
    
    # search and return results. exactly the same as what foursquare gives us originally.
    results = fsq.search_venues(:ll => params[:lat]+','+params[:lon], :categoryId => '4bf58dd8d48988d110951735').to_json
    results
end

# USER PUSH
# showing off user push. simply log whenever a connected user checks in anywhere.
post '/post' do
    puts params.to_s
end
