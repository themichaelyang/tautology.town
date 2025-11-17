---
layout: post
title: "Learning about: OAuth 2.0 authorization code grants"
---

Over the weekend, I learned how to integrate a client app with OAuth 2.0 to add "login with" functionality. Here's how I understand it.

## Basic flow for a web app with a backend

You have your app server, the OAuth client, and the service you want to log in with, the authorization server.

1. You register your app server and its redirect URI with the authorization server, and are given a client ID and client secret.

2. When a user goes to "login with", your app server redirects them to the authorization server's [authorization endpoint](https://datatracker.ietf.org/doc/html/rfc6749#section-3.1), typically at `/oauth/authorize`. Parameters are sent as query parameters to the authorization endpoint, including the `client_id` and `redirect_uri`. This endpoint is where the authorization service first asks for login then shows a page asking the user if they want to grant permissions to your app server.

3. If authorized, the authorization service redirects back to your app server at the `redirect_uri`, with a query parameter `code` for the authorization code.

4. Your app server now exchanges the authorization code for an access token by making a POST request to the authorization server's [token endpoint](https://datatracker.ietf.org/doc/html/rfc6749#section-3.2), typically `/oauth/token`.

5. Now, your app server has an API access token to the authorization server. You can fetch profile information from the authorization server and handle login/sign up normally.

<script src="https://unpkg.com/mermaid@11.12.0/dist/mermaid.min.js"></script>
<pre class="mermaid">
---
config:
  theme: 'neutral'
  fontFamily: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
  nodeSpacing: 20
  rankSpacing: 25
---
sequenceDiagram
    participant Browser
    participant App as App server
    participant Auth as Auth server
    Browser->>App: GET {app}/login-with
    App->>Browser: 302 redirect {auth}/oauth/authorize
    Browser->>Auth: GET {auth}/oauth/authorize
    Auth->>Browser: Login and permissions page
    Browser->>Auth: Log in and grant permission to app
    Auth->>Browser: 302 redirect {app}/callback?code=...
    Browser->>App: GET {app}/callback?code=...
    App->>Auth: POST code to {auth}/oauth/token
    Auth->>App: Access token
    App->Auth: API calls with access token
    App->>Browser: Logged in with auth server
</pre>

```ruby
require "sinatra/base"
require "oauth2"

enable :sessions

client = OAuth2::Client.new(
  ENV["OAUTH_CLIENT_ID"], 
  ENV["OAUTH_CLIENT_SECRET"], 
  site: ENV["OAUTH_SERVICE_URL"],
  authorize_url: "oauth/authorize", # relative to service URL
  token_url: "oauth/token",         # relative to service URL
  redirect_uri: ENV["APP_BASE_URL"] + "/callback",
)

get "/" do
  if session[:logged_in]
    "<a href=/logout>log out</a>"
  else
    "<a href=/login-with>login with</a>"
  end
end

get "/login-with" do
  redirect client.auth_code.authorize_url
end

# Authorization server redirects here
get "/callback" do
  auth_code = params["code"]
  access = client.auth_code.get_token(auth_code)
  
  # make API calls with `access.token` or use `access.get/post` helpers
  session[:logged_in] = true

  redirect back
end

get "/logout" do
  session.clear
  redirect back
end
```

## Protecting against redirect CSRF with `state`

Because the authorization code is passed as a query parameter, there's a possibility of a [cross site request forgery (CSRF) attack](https://www.rfc-editor.org/rfc/rfc6819#section-4.4.1.8). For example, the victim could click a link to the app server redirect URI but with an attacker's authorization code and be logged in with a different account.

To prevent this, we can generate a non-guessable "state" value and save it to the user's local session cookies. Then we pass it along in a `state` parameter to the authorization server's authorization endpoint. 

OAuth specifies query parameters must be passed along, so we verify that it matches the `state` on the session when redirected to our app server's `redirect_uri`. 

This StackExchange [answer from Andy](https://security.stackexchange.com/a/278235/241664) does a good job explaining the attack and mitigation.

## Protecting against authorization code theft with PKCE

Proof Key for Code Exchange, or PKCE ("pixy"), protects against authorization code theft and is required for OAuth 2.1. It verifies that the origin of the OAuth request is the same that uses the authorization code.

To do PKCE, the app generates an unguessable code verifier, and a code challenge which is the BASE64, URL-encoded SHA-256 hash of the verifier.

These are passed in `code_challenge` to the authorization endpoint and `code_verifier` to the token endpoint. The `code_challenge_method` must also be passed as `S256`.

If the authorization server implements PKCE, it will verify that the code challenge and code verifier SHA-256 match before granting the access token.

PKCE is also used for browser-only or mobile-only apps _without_ backends that can't securely store OAuth client secrets. These are known as "public" [OAuth 2.0 client types](https://oauth.net/2/client-types/).

PKCE is described in detail [here](https://blog.postman.com/what-is-pkce/).

## How I learned

I learned this by using the Ruby [oauth2](https://github.com/ruby-oauth/oauth2) gem and reading the [sample code](https://github.com/ruby-oauth/oauth2?tab=readme-ov-file#common-flows-end-to-end) and the Recurse Center API OAuth documentation. I used [Sinatra](https://sinatrarb.com/) for the backend.

ChatGPT suggested `state` and PKCE, which lead me to read more.

When writing this post, I also found Aaron Parecki's [OAuth 2 Simplified blog post](https://aaronparecki.com/oauth-2-simplified/) to be very clear yet concise. He also publishes a longer and more comprehensive [microsite](https://www.o#{auth}/), but I rather like the blog version.

[RFC 6819](https://www.rfc-editor.org/rfc/rfc6819#section-3.6) discusses security considerations of OAuth 2.0. When researching for this post, I referenced the RFCs, linked [here](https://oauth.net/) (also due to Aaron Parecki).