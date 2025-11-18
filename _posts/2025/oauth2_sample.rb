require "sinatra"
require "oauth2"

enable :sessions

REDIRECT_PATH = "/oauth2/redirect"
# If testing locally, take care to be consistent with localhost or 127.0.0.1 because of sameSite cookies!
REDIRECT_URI = ENV["APP_BASE_URL"] + REDIRECT_PATH

client = OAuth2::Client.new(
  ENV["OAUTH_CLIENT_ID"], 
  ENV["OAUTH_CLIENT_SECRET"], 
  site: ENV["OAUTH_SERVICE_URL"],
  authorize_url: "oauth/authorize", # relative to service URL
  token_url: "oauth/token",         # relative to service URL
  redirect_uri: REDIRECT_URI,
)

get "/" do
  if session[:access_token]
    "<p>Token: #{session[:access_token]}</p>" + \
    "<a href=/logout>log out</a>"
  else
    "<a href=/login-with>login with</a>"
  end
end

get "/login-with" do
  redirect client.auth_code.authorize_url
end

# Authorization server redirects here
get REDIRECT_PATH do
  auth_code = params["code"]
  access = client.auth_code.get_token(auth_code, redirect_uri: REDIRECT_URI)
  
  # make API calls with `access.token` or use `access.get/post` helpers
  session[:access_token] = access.token

  redirect back
end

get "/logout" do
  session.clear
  redirect back
end
