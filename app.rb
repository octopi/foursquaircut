get '/' do
	erb :index
end

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