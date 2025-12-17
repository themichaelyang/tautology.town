---
layout: post
title: "Learning about signed cookies"
---

While I was [implementing OAuth 2.0 authorization]({% post_url 2025-11-17-learning-oauth2 %}), I learned about [Sinatra's signed cookie sessions](https://sinatrarb.com/intro.html#session-secret-security). Sinatra session data is stored in an HMAC-SHA256 signed user cookie and is only accessible if the signature is verified. Data is set and fetched on the `session` hash. The secret is set via `set :session_secret`, or is randomly generated at startup if not provided.

Sinatra sessions use the [v2](https://github.com/sinatra/sinatra/blob/4062e3669c7dff0f59ca1d0b0bfa67f7eef444af/sinatra.gemspec#L53) `Rack::Session` [middleware](https://en.wikipedia.org/wiki/Rack_(web_server_interface)). `Rack::Session` v3 uses [AES 256 CTR](https://github.com/rack/rack-session/blob/dadcfe60f193e8d8540bec6b95ca75bed8e5fd7e/lib/rack/session/encryptor.rb#L166C32-L166C43) encryption.

Signed cookies are the same idea as [JWTs](https://www.jwt.io/introduction#what-is-json-web-token) (which also commonly use HMAC signatures), in that you can trust signed state stored with the user. This can be useful for lightweight stateless sessions on OAuth login apps, although [most apps should use regular database-backed session cookies](https://ianlondon.github.io/posts/dont-use-jwts-for-sessions/).

This security measure is also in place because `Rack::Session` treats session cookie data as trusted input. [This article](https://martinfowler.com/articles/session-secret.html) describes an interesting remote code execution (RCE) attack against a Rack app with a weak session secret, exploiting the fact that `Rack::Session` can deserialize Ruby objects.

Signed (or encrypted) cookies are a standard feature in server-side web frameworks. They were included in every framework I checked: [Rails](https://api.rubyonrails.org/classes/ActionDispatch/Session/CookieStore.html), [Express.js](https://github.com/expressjs/cookie-parser), [Django](https://docs.djangoproject.com/en/5.2/topics/http/sessions/#using-cookie-based-sessions), and [Phoenix/Plug](https://hexdocs.pm/plug/Plug.Session.COOKIE.html).

Learning about signed/encrypted cookies, I found it odd how synonymous JWTs have become widespread instead of being regarded as an implementation detail of the web framework. A signed cookie can be implemented with a JWT in a cookie, but using them directly can be [prone to mistakes](https://semgrep.dev/blog/2020/hardcoded-secrets-unverified-tokens-and-other-common-jwt-mistakes/). My hunch is that JWTs became popular because frontend frameworks like React leave these to the application developer.

---

For this topic, I Googled, read blog posts and framework docs, and looked over `Rack::Session` and Sinatra source code.
